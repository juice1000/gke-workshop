#!/usr/bin/env python3
"""Trainer-Probelauf in einem eigens erzeugten lokalen Cluster."""
import json
import os
from pathlib import Path
import subprocess
import time

from pruefen import Checkpoint

ROOT = Path(__file__).resolve().parent.parent
CONTEXT = os.environ["WORKSHOP_CONTEXT"]
if not CONTEXT.startswith("gke-lab-test-"):
    raise SystemExit("Integration nur im temporaeren gke-lab-test-Cluster ausfuehren.")
NAMESPACE = "workshop-test"
COMMAND = ["kubectl", "--context", CONTEXT, "--namespace", NAMESPACE]


def command(*args, input_text=None, success=True):
    result = subprocess.run(COMMAND + list(args), input=input_text, text=True,
                            capture_output=True, timeout=240)
    if success and result.returncode:
        raise RuntimeError(f"kubectl {' '.join(args)}\n{result.stderr}")
    return result


def get(*args):
    return json.loads(command("get", *args, "-o", "json").stdout)


def apply(path):
    command("apply", "-f", str(ROOT / path))


def rollout(name="hallo"):
    command("rollout", "status", f"deployment/{name}", "--timeout=180s")


def wait_for(description, predicate, seconds=180):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if predicate():
            print(f"OK: {description}", flush=True)
            return
        time.sleep(2)
    command("get", "pods", "-o", "wide", success=False)
    events = command("get", "events", "--sort-by=.metadata.creationTimestamp", success=False)
    raise AssertionError(f"Timeout: {description}\n{events.stdout[-6000:]}")


def pods(app="hallo"):
    return [pod for pod in get("pods", "-l", f"app={app}")["items"]
            if not pod["metadata"].get("deletionTimestamp")]


def statuses(app="hallo"):
    return [status for pod in pods(app) for status in pod.get("status", {}).get("containerStatuses", [])]


def waiting_reason(reason, app="hallo"):
    return any(status.get("state", {}).get("waiting", {}).get("reason") == reason
               for status in statuses(app))


def ready(pod):
    return any(condition["type"] == "Ready" and condition["status"] == "True"
               for condition in pod.get("status", {}).get("conditions", []))


def checkpoint(stage):
    env = dict(os.environ, WORKSHOP_NAMESPACE=NAMESPACE)
    subprocess.run(["python3", str(ROOT / "scripts/pruefen.py"), stage], env=env, check=True, timeout=90)


def mit_image(path, action="apply"):
    """Wie in den Labs: Platzhalter per sed ersetzen und ueber stdin anwenden."""
    path = ROOT / path
    files = sorted(path.glob("*.yaml")) if path.is_dir() else [path]
    text = "".join(f.read_text() for f in files).replace("WORKSHOP_IMAGE", "hallo-app:2.0")
    command(action, "-f", "-", input_text=text)


def has_event(app, message):
    names = {pod["metadata"]["name"] for pod in pods(app)}
    return any(event.get("involvedObject", {}).get("name") in names
               and message in event.get("message", "") for event in get("events")["items"])


def fault(number, app):
    if number == 1:
        return waiting_reason("ErrImagePull", app) or waiting_reason("ImagePullBackOff", app)
    if number == 2:
        return waiting_reason("CreateContainerConfigError", app)
    if number == 3:
        return any(status.get("lastState", {}).get("terminated", {}).get("exitCode") == 1
                   or status.get("state", {}).get("terminated", {}).get("exitCode") == 1
                   for status in statuses(app))
    if number == 4:
        return any(condition.get("reason") == "Unschedulable"
                   for pod in pods(app) for condition in pod.get("status", {}).get("conditions", []))
    return has_event(app, "Readiness probe failed") and has_event(app, "404")


def main():
    command("create", "namespace", NAMESPACE)
    print("===== Lab 1 und Lab 2: DNS, Deployment, Selbstheilung, Skalierung", flush=True)
    checkpoint("dns")
    # Ein Checkpoint darf ein leeres Namespace nicht als Erfolg melden.
    env = dict(os.environ, WORKSHOP_NAMESPACE=NAMESPACE)
    negative = subprocess.run(["python3", str(ROOT / "scripts/pruefen.py"), "abschluss"], env=env,
                              capture_output=True, timeout=60)
    assert negative.returncode != 0, "Checkpoint akzeptiert fehlende Anwendung"
    apply("lab02-hallo-app/k8s")
    rollout()
    checkpoint("lab02")
    old_uid = pods()[0]["metadata"]["uid"]
    command("delete", "pod", pods()[0]["metadata"]["name"])
    rollout()
    wait_for("Geloeschter Pod wurde ersetzt", lambda: len(pods()) == 2 and all(
        pod["metadata"]["uid"] != old_uid and ready(pod) for pod in pods()))
    command("scale", "deployment/hallo", "--replicas=4")
    rollout()
    wait_for("Vier bereite Pods", lambda: len(pods()) == 4 and all(ready(pod) for pod in pods()))
    command("scale", "deployment/hallo", "--replicas=2")
    rollout()
    wait_for("Wieder zwei Pods", lambda: len(pods()) == 2)

    print("===== Tag 2: ConfigMap, Secret, Probes und Version 2.0", flush=True)
    command("create", "secret", "generic", "hallo-secret", "--from-literal=DB_PASSWORT=nur-uebung")
    apply("lab02-hallo-app/betrieb")
    rollout()
    checkpoint("betrieb")
    tunnel = Checkpoint(CONTEXT, NAMESPACE)
    response = tunnel.response()
    assert "nur-uebung" not in response
    command("patch", "configmap", "hallo-config", "--type=merge",
            "-p", '{"data":{"GREETING":"Geaendert im Probelauf"}}')
    assert tunnel.response().startswith("Hallo aus der ConfigMap von Pod "), "Bestehende Env-Werte aendern sich ohne Neustart"
    command("rollout", "restart", "deployment/hallo")
    rollout()
    assert tunnel.response().startswith("Geaendert im Probelauf von Pod ")
    # Die Fehlerroute liefert 500, die Liveness bleibt gesund (App-Test im Build).
    command("delete", "-f", str(ROOT / "lab02-hallo-app/betrieb"))
    command("delete", "secret", "hallo-secret")

    print("===== Lab 3: Fuenf Fehlerbilder und ihre Reparaturen", flush=True)
    for number in range(1, 6):
        app = f"fall{number}"
        apply(f"lab03-defekt/fall{number}.yaml")
        wait_for(f"Fall {number}: erwartetes Fehlerbild", lambda n=number, a=app: fault(n, a))
        if number == 3:
            def crash_log_available():
                name = pods(app)[0]["metadata"]["name"]
                previous = command("logs", name, "--previous", success=False)
                current = command("logs", name, success=False)
                return "FEHLER: Falscher Startbefehl" in previous.stdout + current.stdout
            wait_for("Fall 3: Startfehler im aktuellen oder vorigen Log belegt", crash_log_available, seconds=45)
        apply(f"lab03-defekt/loesungen/fall{number}.yaml")
        rollout(app)
        assert any(ready(pod) for pod in pods(app))
        command("delete", "-f", str(ROOT / f"lab03-defekt/loesungen/fall{number}.yaml"))
        wait_for(f"Fall {number}: aufgeraeumt", lambda a=app: not pods(a))

    print("===== Lab 6: Stoerungen 6.1 bis 6.3, Verfuegbarkeit und Rollback", flush=True)
    command("create", "secret", "generic", "hallo-secret", "--from-literal=DB_PASSWORT=nur-uebung")
    faelle = [("6.1", "6.1-konfiguration"), ("6.2", "6.2-speicher"), ("6.3", "6.3-bereitschaft")]
    for nummer, datei in faelle:
        mit_image("lab06-abschluss/loesung")
        rollout()
        checkpoint("abschluss")
        before = {pod["metadata"]["uid"] for pod in pods() if ready(pod)}
        mit_image(f"lab06-abschluss/stoerungen/{datei}.yaml")

        def broken():
            if nummer == "6.1":
                return waiting_reason("CreateContainerConfigError")
            if nummer == "6.2":
                return any(status.get(where, {}).get("terminated", {}).get("reason") == "OOMKilled"
                           for status in statuses() for where in ("state", "lastState"))
            return has_event("hallo", "Readiness probe failed") and has_event("hallo", "404")

        wait_for(f"Stoerung {nummer}: erwartetes Fehlerbild", broken)
        assert command("rollout", "status", "deployment/hallo", "--timeout=5s", success=False).returncode != 0
        surviving = {pod["metadata"]["uid"] for pod in pods() if ready(pod)}
        assert before <= surviving, "Alte bereite Pods gingen waehrend fehlerhaftem Rollout verloren"
        assert "Version 2.0" in Checkpoint(CONTEXT, NAMESPACE).response()
        command("rollout", "undo", "deployment/hallo")
        rollout()
        checkpoint("abschluss")
    mit_image("lab06-abschluss/loesung", "delete")
    command("delete", "secret", "hallo-secret")

    print("===== Namespace-Rechte mit echter Kubernetes-Autorisierung", flush=True)
    role = (ROOT / "lab06-abschluss/rechte.yaml").read_text().replace("namespace: workshop\n", f"namespace: {NAMESPACE}\n")
    command("apply", "-f", "-", input_text=role)
    for namespace, verb, resource, expected in [
        (NAMESPACE, "create", "deployments.apps", True),
        (NAMESPACE, "get", "secrets", True),
        ("kube-system", "create", "deployments.apps", False),
        (NAMESPACE, "list", "nodes", False),
    ]:
        result = command("auth", "can-i", verb, resource, "-n", namespace,
                         "--as=tester", success=False)
        assert (result.returncode == 0) == expected, result.stdout + result.stderr

    print("===== Lab 7: cordon, Pending, uncordon und PDB", flush=True)
    apply("lab02-hallo-app/k8s")
    rollout()
    nodes = get("nodes")["items"]
    assert len(nodes) == 1, "Node-Experiment braucht genau einen lokalen Node"
    node = nodes[0]["metadata"]["name"]
    try:
        command("cordon", node)
        command("delete", "pod", pods()[0]["metadata"]["name"])
        wait_for("Ersatz-Pod ist auf gesperrtem Node nicht planbar", lambda: any(
            condition.get("reason") == "Unschedulable"
            for pod in pods() for condition in pod.get("status", {}).get("conditions", [])))
    finally:
        command("uncordon", node)
    rollout()
    apply("lab07-betrieb/pdb.yaml")
    wait_for("PDB erlaubt eine freiwillige Unterbrechung", lambda: get("pdb", "hallo-pdb").get(
        "status", {}).get("disruptionsAllowed") == 1)
    print("OK: Alle lokalen Labs und erwarteten Fehlerbilder bestanden. GKE separat pruefen.", flush=True)


if __name__ == "__main__":
    main()
