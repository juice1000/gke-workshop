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

    def get(self, *args):
        result = subprocess.run(self.command + ["--request-timeout=10s", "get", *args, "-o", "json"],
                                capture_output=True, text=True, timeout=20)
        if result.returncode:
            # Keine Objektinhalte ausgeben, insbesondere keine Secrets.
            self.check(False, f"{' '.join(args)} erreichbar", "Kontext, Namespace, Namen und Rechte pruefen")
            return {}
        return json.loads(result.stdout)

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
        deployment = self.get("deployment", "hallo")
        spec, status = deployment.get("spec", {}), deployment.get("status", {})
        replicas = spec.get("replicas", 0)
        generation = deployment.get("metadata", {}).get("generation", 0)
        self.check(replicas == 2 and status.get("observedGeneration", 0) >= generation
                   and status.get("updatedReplicas", 0) == replicas
                   and status.get("availableReplicas", 0) == replicas
                   and status.get("replicas", 0) == replicas,
                   "Zwei aktuelle, verfuegbare Replikas", "kubectl rollout status deployment/hallo; dann describe und Events")
        service = self.get("service", "hallo")
        ports = service.get("spec", {}).get("ports", [])
        self.check(service.get("spec", {}).get("selector") == {"app": "hallo"}
                   and any(p.get("port") == 80 and p.get("targetPort") == 8080 for p in ports),
                   "Service waehlt app=hallo und leitet 80 auf 8080 weiter", "service.yaml: selector, port und targetPort")
        containers = spec.get("template", {}).get("spec", {}).get("containers", [])
        container = next((item for item in containers if item.get("name") == "hallo"), {})
        if stage != "lab02":
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
        response = self.response() if deployment and service else ""
        # Der EndpointSlice-Controller kann dem Deployment-Status kurz nachlaufen.
        addresses = set()
        for _ in range(10):
            slices = self.get("endpointslices.discovery.k8s.io", "-l", "kubernetes.io/service-name=hallo")
            addresses = {address for item in slices.get("items", []) for endpoint in item.get("endpoints", [])
                         if endpoint.get("conditions", {}).get("ready") is True
                         for address in endpoint.get("addresses", [])}
            if len(addresses) == 2 or not deployment:
                break
            time.sleep(0.5)
        self.check(len(addresses) == 2, "Service hat zwei bereite Pod-Adressen",
                   "Pod-Labels, Service-Selektor und Readiness pruefen")
        expected_version = "1.0" if stage == "lab02" else "2.0"
        self.check("von Pod " in response and f"Version {expected_version}" in response,
                   f"HTTP-Antwort mit Pod-Name und Version {expected_version}",
                   "Image-Version, rollout status und port-forward pruefen")
        actual_pods = self.get("pods", "-l", "app=hallo")
        names = {pod["metadata"]["name"] for pod in actual_pods.get("items", [])}
        match = re.search(r"von Pod (\S+), Version ", response)
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
