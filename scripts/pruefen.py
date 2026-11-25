#!/usr/bin/env python3
"""Lesende Checkpoints mit Hinweisen. Keine Manifeste werden angewendet."""
import argparse
import json
import os
import re
import socket
import subprocess
import tempfile
import time
import urllib.error
import urllib.request


# Wo die Manifeste je Etappe liegen. Fuer Hinweise bei fehlenden Objekten.
FOLDERS = {"lab02": "lab02-hallo-app/k8s/", "betrieb": "lab02-hallo-app/betrieb/",
           "gke": "out/lab04/", "abschluss": "out/lab06/starter/"}


class Checkpoint:
    def __init__(self, context, namespace):
        self.command = ["kubectl", "--context", context, "--namespace", namespace]
        self.failures = 0

    def check(self, condition, message, hint):
        if condition:
            print(f"OK: {message}")
        else:
            self.failures += 1
            print(f"FEHLT: {message}. Hinweis: {hint}")

    def get(self, *args, missing=None):
        """Objekt als JSON lesen. missing=(Meldung, Hinweis) fuer ein fehlendes Objekt."""
        result = subprocess.run(self.command + ["--request-timeout=10s", "get", *args, "-o", "json"],
                                capture_output=True, text=True, timeout=20)
        if result.returncode:
            # Keine Objektinhalte ausgeben, insbesondere keine Secrets.
            if missing and "NotFound" in result.stderr:
                self.check(False, *missing)
            else:
                self.check(False, f"{' '.join(args)} erreichbar", "Kontext, Namespace, Namen und Rechte pruefen")
            return {}
        return json.loads(result.stdout)

    def pod_problems(self):
        """Gruende, warum Pods von hallo nicht laufen, z. B. ImagePullBackOff."""
        reasons = set()
        for pod in self.get("pods", "-l", "app=hallo").get("items", []):
            for condition in pod.get("status", {}).get("conditions", []):
                if condition.get("reason") == "Unschedulable":
                    reasons.add("Unschedulable")
            for status in pod.get("status", {}).get("containerStatuses", []):
                for where in ("state", "lastState"):
                    detail = status.get(where, {})
                    reason = detail.get("waiting", {}).get("reason") or detail.get("terminated", {}).get("reason")
                    if reason and reason not in ("ContainerCreating", "Completed"):
                        reasons.add(reason)
        return sorted(reasons)

    def response(self):
        # Kurzlebiger Tunnel, nur auf Loopback. Auch bei Fehlern wieder schliessen.
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            port = listener.getsockname()[1]
        output = tempfile.TemporaryFile(mode="w+")
        process = None
        answer = ""
        try:
            # Tag 1 hat noch keine Startup-/Readiness-Probes. Ein laufender
            # Container kann daher vor dem HTTP-Server als bereit erscheinen.
            opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
            deadline = time.monotonic() + 60
            while time.monotonic() < deadline:
                # port-forward kann bei der ersten Verbindung abbrechen,
                # wenn der Container schon laeuft, HTTP aber noch nicht lauscht.
                if process is None or process.poll() is not None:
                    process = subprocess.Popen(self.command + ["port-forward", "service/hallo", f"{port}:80",
                                                               "--address=127.0.0.1"],
                                               stdout=output, stderr=output)
                try:
                    with opener.open(f"http://127.0.0.1:{port}/", timeout=2) as response:
                        answer = response.read().decode()
                        break
                except (OSError, urllib.error.URLError):
                    time.sleep(0.25)
        finally:
            if process is not None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
            if not answer:
                output.seek(0)
                print("INFO: HTTP-Tunnel: " + output.read()[-1500:].strip())
            output.close()
        return answer

    def application(self, stage):
        folder = FOLDERS[stage]
        deployment = self.get("deployment", "hallo", missing=(
            "Deployment hallo vorhanden",
            f"kubectl apply -f {folder} ausfuehren; in deployment.yaml muss metadata.name hallo sein"))
        spec, status = deployment.get("spec", {}), deployment.get("status", {})
        template = spec.get("template", {})
        containers = template.get("spec", {}).get("containers", [])
        container = next((item for item in containers if item.get("name") == "hallo"), {})
        if deployment:
            self.check(spec.get("selector", {}).get("matchLabels") == {"app": "hallo"}
                       and template.get("metadata", {}).get("labels", {}).get("app") == "hallo",
                       "Deployment waehlt seine Pods ueber das Label app=hallo",
                       "deployment.yaml: selector.matchLabels und template.metadata.labels auf app: hallo")
            self.check(spec.get("replicas") == 2, "Sollzustand: zwei Replikas",
                       f"deployment.yaml: spec.replicas ist {spec.get('replicas')}, erwartet 2. "
                       "Nach kubectl scale die Datei erneut anwenden")
            self.check(bool(container), "Container mit dem Namen hallo vorhanden",
                       "deployment.yaml: containers[].name: hallo")
        if deployment and stage == "lab02":
            self.check(container.get("image") == "hallo-app:1.0", "Image hallo-app:1.0",
                       f"deployment.yaml: image ist {container.get('image')}, erwartet hallo-app:1.0")
            self.check(container.get("imagePullPolicy") in ("IfNotPresent", "Never"),
                       "Image wird aus minikube verwendet, nicht aus dem Internet geladen",
                       "deployment.yaml: imagePullPolicy: IfNotPresent. Das Image gibt es in keiner Registry")
            self.check(any(port.get("containerPort") == 8080 for port in container.get("ports", [])),
                       "Container-Port 8080", "deployment.yaml: ports[].containerPort: 8080")
            hostname = next((item for item in container.get("env", []) if item.get("name") == "HOSTNAME"), {})
            self.check(hostname.get("valueFrom", {}).get("fieldRef", {}).get("fieldPath") == "metadata.name",
                       "HOSTNAME enthaelt den Pod-Namen",
                       "deployment.yaml: env HOSTNAME mit valueFrom.fieldRef.fieldPath: metadata.name")
        if deployment and stage != "lab02":
            paths = {"startupProbe": "/actuator/health/liveness",
                     "livenessProbe": "/actuator/health/liveness",
                     "readinessProbe": "/actuator/health/readiness"}
            for name, path in paths.items():
                probe = container.get(name, {})
                self.check(probe.get("httpGet", {}).get("path") == path
                           and probe.get("httpGet", {}).get("port") == 8080,
                           f"{name} nutzt den richtigen Health-Pfad und Port", "deployment.yaml: httpGet")
            resources = container.get("resources", {})
            self.check(bool(resources.get("requests", {}).get("cpu"))
                       and bool(resources.get("requests", {}).get("memory"))
                       and bool(resources.get("limits", {}).get("memory")),
                       "CPU-/Speicher-Requests und Speicherlimit gesetzt", "resources ergaenzen")
            env = {item["name"]: item for item in container.get("env", [])}
            self.check(env.get("GREETING", {}).get("valueFrom", {}).get("configMapKeyRef")
                       == {"name": "hallo-config", "key": "GREETING"},
                       "GREETING stammt aus hallo-config", "valueFrom.configMapKeyRef")
            if stage in ("betrieb", "abschluss"):
                self.check(env.get("DB_PASSWORT", {}).get("valueFrom", {}).get("secretKeyRef")
                           == {"name": "hallo-secret", "key": "DB_PASSWORT"},
                           "DB_PASSWORT stammt aus hallo-secret", "valueFrom.secretKeyRef")
            self.check(spec.get("strategy", {}).get("rollingUpdate", {}).get("maxUnavailable") == 0,
                       "Rollout behaelt alle bisherigen bereiten Replikas", "strategy.rollingUpdate.maxUnavailable: 0")
        if deployment:
            generation = deployment.get("metadata", {}).get("generation", 0)
            replicas = spec.get("replicas", 0)
            ready = (replicas > 0 and status.get("observedGeneration", 0) >= generation
                     and status.get("updatedReplicas", 0) == replicas
                     and status.get("availableReplicas", 0) == replicas
                     and status.get("replicas", 0) == replicas)
            hint = "kubectl rollout status deployment/hallo abwarten; dann describe und Events"
            problems = [] if ready else self.pod_problems()
            if problems:
                hint = ("Pods melden " + ", ".join(problems)
                        + ". kubectl describe pod -l app=hallo, Abschnitt Events")
                if stage in ("lab02", "betrieb") and any("Image" in reason for reason in problems):
                    hint += ". Image-Name, Tag und minikube image load pruefen"
            self.check(ready, "Alle Replikas aktuell und verfuegbar", hint)

        service = self.get("service", "hallo", missing=(
            "Service hallo vorhanden",
            f"kubectl apply -f {folder} ausfuehren; in service.yaml muss metadata.name hallo sein"))
        ports_ok = False
        if service:
            selector = service.get("spec", {}).get("selector")
            self.check(selector == {"app": "hallo"}, "Service waehlt Pods mit app=hallo",
                       f"service.yaml: selector ist {selector}, er muss zum Pod-Label aus dem Deployment passen")
            ports = service.get("spec", {}).get("ports", [])
            ports_ok = any(p.get("port") == 80 and p.get("targetPort") == 8080 for p in ports)
            self.check(ports_ok,
                       "Service leitet Port 80 auf Container-Port 8080 weiter",
                       "service.yaml: ports[].port: 80 und targetPort: 8080 (containerPort aus dem Deployment)")

        # Der EndpointSlice-Controller kann dem Deployment-Status kurz nachlaufen.
        expected = spec.get("replicas") or 2
        addresses = set()
        for _ in range(10):
            if not service:
                break
            slices = self.get("endpointslices.discovery.k8s.io", "-l", "kubernetes.io/service-name=hallo")
            # Ohne passende Pods liefert die API "endpoints": null statt einer Liste.
            addresses = {address for item in slices.get("items") or [] for endpoint in item.get("endpoints") or []
                         if (endpoint.get("conditions") or {}).get("ready") is True
                         for address in endpoint.get("addresses") or []}
            if len(addresses) == expected or not deployment:
                break
            time.sleep(0.5)
        self.check(bool(service) and len(addresses) == expected,
                   f"Service erreicht alle bereiten Pods ({len(addresses)} von {expected})",
                   "Service-Selektor mit den Pod-Labels vergleichen (kubectl get pods --show-labels) "
                   "und warten, bis die Pods bereit sind")

        # Ohne bereite Pod-Adresse oder mit falschem Port erreicht der Tunnel nichts.
        # Dann nicht 60 Sekunden warten, sondern auf die Fehler oben verweisen.
        reachable = bool(deployment and service and addresses and ports_ok)
        response = self.response() if reachable else ""
        expected_version = "1.0" if stage == "lab02" else "2.0"
        self.check("von Pod " in response and f"Version {expected_version}" in response,
                   f"HTTP-Antwort mit Pod-Name und Version {expected_version}",
                   "Erst die FEHLT-Zeilen oben beheben" if not reachable
                   else "Image-Version, rollout status und port-forward pruefen")
        actual_pods = self.get("pods", "-l", "app=hallo")
        names = {pod["metadata"]["name"] for pod in actual_pods.get("items", [])}
        match = re.search(r"von Pod (\S+), Version ", response)
        if response:
            self.check(bool(match) and match.group(1) in names,
                       "HTTP-Antwort nennt einen tatsaechlichen Pod", "HOSTNAME per fieldRef metadata.name setzen")
        if stage != "lab02":
            config = self.get("configmap", "hallo-config")
            greeting = config.get("data", {}).get("GREETING", "")
            self.check(bool(greeting) and response.startswith(greeting + " von Pod "),
                       "HTTP-Antwort verwendet die ConfigMap-Begruessung",
                       "ConfigMap geaendert? Umgebungsvariablen brauchen rollout restart")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("stage", choices=["dns", "lab02", "betrieb", "gke", "abschluss"])
    args = parser.parse_args()
    context = os.environ.get("WORKSHOP_CONTEXT", "minikube")
    namespace = os.environ.get("WORKSHOP_NAMESPACE", "workshop")
    print(f"INFO: Kontext {context}, Namespace {namespace}")
    checkpoint = Checkpoint(context, namespace)
    try:
        if args.stage == "dns":
            pods = checkpoint.get("pods", "-n", "kube-system", "-l", "k8s-app=kube-dns")
            items = pods.get("items", [])
            checkpoint.check(bool(items) and all(p.get("status", {}).get("phase") == "Running" for p in items),
                             "DNS-Pods gefunden und Running", "kubectl get pods -n kube-system --show-labels")
        else:
            checkpoint.application(args.stage)
    except (OSError, subprocess.SubprocessError, ValueError) as error:
        checkpoint.check(False, "Checkpoint ausfuehrbar", f"kubectl/Cluster pruefen ({type(error).__name__})")
    print(f"\nErgebnis: {checkpoint.failures} Pruefung(en) fehlgeschlagen")
    raise SystemExit(min(checkpoint.failures, 1))


if __name__ == "__main__":
    main()
