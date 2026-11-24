#!/usr/bin/env bash
# Demo 2.3a: Zwei Probes, zwei Fragen
# Folie: Tag 2, 2.3 "Zwei Probes, zwei Fragen" (Terminal-Streifen)
# Zeigt: wo ihr die Probes im Cluster seht.
# Voraussetzung: 00-vorbereiten.sh. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.3a "Zwei Probes, zwei Fragen" "2.3, Zwei Probes, zwei Fragen"
braucht_betrieb

sage "READY zeigt das Ergebnis der Readiness, RESTARTS die Neustarts durch die Liveness."
lauf "kubectl get pods -l app=hallo"
sage "Pfade und Zeiten der drei Probes. period = Abstand, #failure = erlaubte Fehlschlaege."
lauf "kubectl describe pod -l app=hallo | grep -E 'Liveness|Readiness|Startup'"
fertig
