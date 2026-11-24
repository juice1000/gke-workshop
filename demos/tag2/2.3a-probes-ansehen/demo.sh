#!/usr/bin/env bash
# Demo 2.3a: Zwei Probes, zwei Fragen
# Folie: Tag 2, 2.3 "Zwei Probes, zwei Fragen" (Terminal-Streifen)
# Zeigt: wo ihr die Probes im Cluster seht.
# Voraussetzung: demos/tag2/00-vorbereiten/demo.sh. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.3a "Zwei Probes, zwei Fragen" "2.3, Zwei Probes, zwei Fragen"
require_betrieb

say "READY zeigt das Ergebnis der Readiness, RESTARTS die Neustarts durch die Liveness."
run "kubectl get pods -l app=hallo"
say "Pfade und Zeiten der drei Probes. period = Abstand, #failure = erlaubte Fehlschlaege."
run "kubectl describe pod -l app=hallo | grep -E 'Liveness|Readiness|Startup'"
finish
