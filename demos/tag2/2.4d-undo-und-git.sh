#!/usr/bin/env bash
# Demo 2.4d: Undo und Git
# Folie: Tag 2, Check-in 2.4, Aufloesung 2/2 "Undo und Git"
# Zeigt: eine Aenderung im Cluster laesst Cluster und Repository auseinanderlaufen.
# Das naechste apply aus dem Repository setzt die Datei wieder durch.
# Voraussetzung: 00-vorbereiten.sh, hallo-app:1.0 geladen. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.4d "Undo und Git" "Check-in 2.4, Aufloesung 2/2"
braucht_betrieb
aufraeumen_mit "kubectl apply -f lab02-hallo-app/betrieb/deployment.yaml && kubectl rollout status deployment/hallo --timeout=180s"

sage "Notmassnahme direkt im Cluster: zurueck auf Version 1.0."
lauf "kubectl set image deployment/hallo hallo=hallo-app:1.0"
lauf "kubectl rollout status deployment/hallo --timeout=180s"
lauf "kubectl rollout history deployment/hallo"
sage "Was im Cluster laeuft:"
lauf "kubectl get deployment hallo -o wide"
sage "Was im Repository steht:"
lauf "grep image: lab02-hallo-app/betrieb/deployment.yaml"
sage "Das naechste apply aus dem Repository (oder die Pipeline) bringt wieder die Datei:"
aufraeumen
lauf "kubectl get deployment hallo -o wide"
fertig
