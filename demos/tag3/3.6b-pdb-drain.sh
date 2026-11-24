#!/usr/bin/env bash
# Demo 3.6b: PDB blockiert drain
# Folie: Tag 3, 3.6 Lab 6: Vertiefung Betrieb
# Zeigt: mit minAvailable 2 bei 2 Pods ist keine freiwillige Unterbrechung
# erlaubt. drain sperrt den Node, kann aber keinen Pod verdraengen.
# Am Ende: uncordon und PDB loeschen, auch bei Strg+C.
# Voraussetzung: 00-vorbereiten.sh aus tag2. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 3.6b "PDB blockiert drain" "3.6 Lab 6: Vertiefung Betrieb"
braucht_betrieb

if [ "$MODUS" = trocken ]; then NODE=minikube; else
  NODE="$(command kubectl --context "$KONTEXT" get nodes -o jsonpath='{.items[0].metadata.name}')"
fi
aufraeumen_mit "kubectl uncordon $NODE && kubectl delete pdb hallo-pdb-demo --ignore-not-found && kubectl rollout status deployment/hallo --timeout=180s"

sage "Zwei Pods laufen:"
lauf "kubectl get deploy hallo"
sage "PDB: mindestens 2 Pods muessen bleiben. Lab 6 nutzt 1, hier absichtlich 2."
lauf "kubectl create pdb hallo-pdb-demo --selector=app=hallo --min-available=2"
lauf "kubectl get pdb hallo-pdb-demo"
sage "ALLOWED DISRUPTIONS 0. Jetzt den Node leeren, nur die Pods von hallo, hoechstens 30 Sekunden:"
lauf "kubectl drain $NODE --pod-selector=app=hallo --timeout=30s; echo \"Exit-Code: \$?\""
sage "Der Node ist gesperrt, die Pods laufen trotzdem weiter:"
lauf "kubectl get nodes"
lauf "kubectl get pods -l app=hallo"
sage "Auf GKE wartet ein Node-Upgrade genauso, bis das PDB es zulaesst (hoechstens eine Stunde)."
sage "Sperre aufheben und PDB loeschen:"
fertig
