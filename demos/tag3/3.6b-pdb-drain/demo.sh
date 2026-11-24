#!/usr/bin/env bash
# Demo 3.6b: PDB blockiert drain
# Folie: Tag 3, 3.6 Lab 6: Vertiefung Betrieb
# Zeigt: mit minAvailable 2 bei 2 Pods ist keine freiwillige Unterbrechung
# erlaubt. drain sperrt den Node, kann aber keinen Pod verdraengen.
# Am Ende: uncordon und PDB loeschen, auch bei Strg+C.
# Voraussetzung: demos/tag2/00-vorbereiten/demo.sh. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 3.6b "PDB blockiert drain" "3.6 Lab 6: Vertiefung Betrieb"
require_betrieb

if [ "$MODE" = dry ]; then NODE_NAME=minikube; else
  NODE_NAME="$(command kubectl --context "$CONTEXT" get nodes -o jsonpath='{.items[0].metadata.name}')"
fi
cleanup_with "kubectl uncordon $NODE_NAME && kubectl delete pdb hallo-pdb-demo --ignore-not-found && kubectl rollout status deployment/hallo --timeout=180s"

say "Zwei Pods laufen:"
run "kubectl get deploy hallo"
say "PDB: mindestens 2 Pods muessen bleiben. Lab 6 nutzt 1, hier absichtlich 2."
run "kubectl create pdb hallo-pdb-demo --selector=app=hallo --min-available=2"
run "kubectl get pdb hallo-pdb-demo"
say "ALLOWED DISRUPTIONS 0. Jetzt den Node leeren, nur die Pods von hallo, hoechstens 30 Sekunden:"
run "kubectl drain $NODE_NAME --pod-selector=app=hallo --timeout=30s; echo \"Exit-Code: \$?\""
say "Der Node ist gesperrt, die Pods laufen trotzdem weiter:"
run "kubectl get nodes"
run "kubectl get pods -l app=hallo"
say "Auf GKE wartet ein Node-Upgrade genauso, bis das PDB es zulaesst (hoechstens eine Stunde)."
say "Sperre aufheben und PDB loeschen:"
finish
