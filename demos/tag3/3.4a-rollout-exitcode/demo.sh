#!/usr/bin/env bash
# Demo 3.4a: Exit-Code von rollout status
# Folie: Tag 3, 3.4 Anbindung an den Build-Prozess
# Zeigt: eine Pipeline erkennt einen gescheiterten Rollout am Exit-Code von
# kubectl rollout status. Danach rollt undo zurueck, der Exit-Code ist 0.
# Am Ende gilt wieder betrieb/deployment.yaml.
# Voraussetzung: demos/tag2/00-vorbereiten/demo.sh. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 3.4a "Exit-Code von rollout status" "3.4 Anbindung an den Build-Prozess"
require_betrieb
cleanup_with "kubectl apply -f lab02-hallo-app/betrieb/deployment.yaml && kubectl rollout status deployment/hallo --timeout=180s"

say "Die Pipeline deployt einen Tag, den es nicht gibt:"
run "kubectl set image deployment/hallo hallo=hallo-app:gibtsnicht"
say "Die Pipeline wartet hoechstens 30 Sekunden. Entscheidend ist der Exit-Code."
run "kubectl rollout status deployment/hallo --timeout=30s; echo \"Exit-Code: \$?\""
say "Nicht 0: die Pipeline bricht ab. Die alten Pods bedienen weiter:"
run "kubectl get pods -l app=hallo"
say "Zurueckrollen auf die vorige Revision:"
run "kubectl rollout undo deployment/hallo"
run "kubectl rollout status deployment/hallo --timeout=180s; echo \"Exit-Code: \$?\""
say "0: der Rollout ist fertig. Das Repository nennt aber noch den Stand vor dem Fehler, siehe Demo 2.4d."
finish
