#!/usr/bin/env bash
# Demo 2.3c: Liveness haengt an der Datenbank
# Folie: Tag 2, Check-in 2.3 Probes, Aufloesung 2/3 "Liveness haengt an der Datenbank"
# Zeigt: was die Probes fragen. Die Endpunkte pruefen nur die Anwendung selbst.
# Startet einen Tunnel im Hintergrund und beendet ihn am Ende.
# Voraussetzung: 00-vorbereiten.sh, curl. Dauer: etwa 2 Minuten.
# Port aendern: DEMO_PORT=18080 bash demos/tag2/2.3c-health-endpunkte/demo.sh
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.3c "Liveness haengt an der Datenbank" "Check-in 2.3 Probes, Aufloesung 2/3"
require_betrieb
PORT="${DEMO_PORT:-8080}"
cleanup_with "pkill -f 'port-forward service/hallo $PORT:80' || true"

say "Tunnel zum Service starten (sonst im zweiten Terminal)."
run "kubectl port-forward service/hallo $PORT:80 >/dev/null 2>&1 & sleep 3"
say "Das fragt die Liveness-Probe:"
run "curl -s localhost:$PORT/actuator/health/liveness; echo"
say "Das fragt die Readiness-Probe:"
run "curl -s localhost:$PORT/actuator/health/readiness; echo"
say "Keine Datenbank, kein externer Dienst darin. Fiele die Datenbank aus, bliebe die Liveness UP."
run "curl -s localhost:$PORT/; echo"
finish
