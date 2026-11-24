#!/usr/bin/env bash
# Demo 00: Ausgangslage fuer die Demonstrationen an Tag 2 und Tag 3 herstellen.
# Entspricht der Challenge in 2.2: hallo-app:2.0 mit ConfigMap, Secret, Probes
# und Ressourcen (lab02-hallo-app/betrieb/). Kann beliebig oft laufen und
# setzt dabei auch Aenderungen abgebrochener Demonstrationen zurueck.
# Dauer: 1 bis 5 Minuten (Image-Bau beim ersten Mal).
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 00 "Ausgangslage herstellen" "vor 2.1 und nach jeder abgebrochenen Demo"

sage "Laeuft der lokale Cluster?"
lauf "minikube status"

sage "Beide Images im Cluster? Lab 3 und Demo 2.4d brauchen 1.0, betrieb/ braucht 2.0."
for demo_v in 1.0 2.0; do
  if [ "$MODUS" != trocken ] && minikube image ls 2>/dev/null | grep -q "hallo-app:$demo_v"; then
    printf '  hallo-app:%s ist schon geladen.\n' "$demo_v"
  else
    lauf "docker build --build-arg APP_VERSION=$demo_v -t hallo-app:$demo_v lab02-hallo-app"
    lauf "minikube image load hallo-app:$demo_v"
  fi
done

sage "Secret anlegen. AlreadyExists heisst: gibt es schon, alles gut."
lauf "kubectl create secret generic hallo-secret --from-literal=DB_PASSWORT=uebung123 || true"

sage "Reste abgebrochener Demonstrationen entfernen (nur Demo-Objekte)."
lauf "kubectl delete -f lab03-defekt/fall2.yaml --ignore-not-found; kubectl delete configmap fall2-config --ignore-not-found; kubectl delete namespace demo-anders --ignore-not-found --wait=false; kubectl delete deployment oom --ignore-not-found; kubectl delete hpa hallo --ignore-not-found; kubectl delete pdb hallo-pdb-demo --ignore-not-found; kubectl delete rolebinding,role demo-leser --ignore-not-found"

sage "Node wieder freigeben, falls Demo 3.6a oder 3.6b abgebrochen wurde."
if [ "$MODUS" = trocken ]; then demo_node=minikube; else
  demo_node="$(command kubectl --context "$KONTEXT" get nodes -o jsonpath='{.items[0].metadata.name}')"
fi
lauf "kubectl uncordon $demo_node"

sage "Den Stand aus betrieb/ anwenden und warten, bis er laeuft."
lauf "kubectl apply -f lab02-hallo-app/betrieb/"
lauf "kubectl rollout status deployment/hallo --timeout=180s"
lauf "kubectl get pods -l app=hallo"
fertig
