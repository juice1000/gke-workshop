#!/usr/bin/env bash
# Demo 3.4a: Exit-Code von rollout status
# Folie: Tag 3, 3.4 Anbindung an den Build-Prozess
# Zeigt: eine Pipeline erkennt einen gescheiterten Rollout am Exit-Code von
# kubectl rollout status. Danach rollt undo zurueck, der Exit-Code ist 0.
# Am Ende gilt wieder betrieb/deployment.yaml.
# Voraussetzung: 00-vorbereiten.sh aus tag2. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 3.4a "Exit-Code von rollout status" "3.4 Anbindung an den Build-Prozess"
braucht_betrieb
aufraeumen_mit "kubectl apply -f lab02-hallo-app/betrieb/deployment.yaml && kubectl rollout status deployment/hallo --timeout=180s"

sage "Die Pipeline deployt einen Tag, den es nicht gibt:"
lauf "kubectl set image deployment/hallo hallo=hallo-app:gibtsnicht"
sage "Die Pipeline wartet hoechstens 30 Sekunden. Entscheidend ist der Exit-Code."
lauf "kubectl rollout status deployment/hallo --timeout=30s; echo \"Exit-Code: \$?\""
sage "Nicht 0: die Pipeline bricht ab. Die alten Pods bedienen weiter:"
lauf "kubectl get pods -l app=hallo"
sage "Zurueckrollen auf die vorige Revision:"
lauf "kubectl rollout undo deployment/hallo"
lauf "kubectl rollout status deployment/hallo --timeout=180s; echo \"Exit-Code: \$?\""
sage "0: der Rollout ist fertig. Das Repository nennt aber noch den Stand vor dem Fehler, siehe Demo 2.4d."
fertig
