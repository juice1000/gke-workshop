#!/usr/bin/env bash
# Demo 00: Ausgangslage fuer die Demonstrationen an Tag 2 und Tag 3 herstellen.
# Entspricht der Challenge in 2.2: hallo-app:2.0 mit ConfigMap, Secret, Probes
# und Ressourcen (lab02-hallo-app/betrieb/). Kann beliebig oft laufen und
# setzt dabei auch Aenderungen abgebrochener Demonstrationen zurueck.
# Dauer: 1 bis 5 Minuten (Image-Bau beim ersten Mal).
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 00 "Ausgangslage herstellen" "vor 2.1 und nach jeder abgebrochenen Demo"

say "Laeuft der lokale Cluster?"
run "minikube status"

say "Beide Images im Cluster? Lab 3 und Demo 2.4d brauchen 1.0, betrieb/ braucht 2.0."
for demo_v in 1.0 2.0; do
  if [ "$MODE" != dry ] && minikube image ls 2>/dev/null | grep -q "hallo-app:$demo_v"; then
    printf '  hallo-app:%s ist schon geladen.\n' "$demo_v"
  else
    run "docker build --build-arg APP_VERSION=$demo_v -t hallo-app:$demo_v lab02-hallo-app"
    run "minikube image load hallo-app:$demo_v"
  fi
done

say "Secret anlegen. AlreadyExists heisst: gibt es schon, alles gut."
run "kubectl create secret generic hallo-secret --from-literal=DB_PASSWORT=uebung123 || true"

say "Reste abgebrochener Demonstrationen entfernen (nur Demo-Objekte)."
run "kubectl delete deployment oom --ignore-not-found; kubectl delete hpa hallo --ignore-not-found; kubectl delete pdb hallo-pdb-demo --ignore-not-found; kubectl delete rolebinding,role demo-leser --ignore-not-found"

say "Node wieder freigeben, falls Demo 3.6a oder 3.6b abgebrochen wurde."
if [ "$MODE" = dry ]; then demo_node=minikube; else
  demo_node="$(command kubectl --context "$CONTEXT" get nodes -o jsonpath='{.items[0].metadata.name}')"
fi
run "kubectl uncordon $demo_node"

say "Den Stand aus betrieb/ anwenden und warten, bis er laeuft."
run "kubectl apply -f lab02-hallo-app/betrieb/"
run "kubectl rollout status deployment/hallo --timeout=180s"
run "kubectl get pods -l app=hallo"
finish
