#!/usr/bin/env bash
# Demo 2.3c: Liveness haengt an der Datenbank
# Folie: Tag 2, Check-in 2.3 Probes, Aufloesung 2/3 "Liveness haengt an der Datenbank"
# Zeigt: was die Probes fragen. Die Endpunkte pruefen nur die Anwendung selbst.
# Startet einen Tunnel im Hintergrund und beendet ihn am Ende.
# Voraussetzung: 00-vorbereiten.sh, curl. Dauer: etwa 2 Minuten.
# Port aendern: DEMO_PORT=18080 bash demos/tag2/2.3c-health-endpunkte.sh
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.3c "Liveness haengt an der Datenbank" "Check-in 2.3 Probes, Aufloesung 2/3"
braucht_betrieb
PORT="${DEMO_PORT:-8080}"
aufraeumen_mit "pkill -f 'port-forward service/hallo $PORT:80' || true"

sage "Tunnel zum Service starten (sonst im zweiten Terminal)."
lauf "kubectl port-forward service/hallo $PORT:80 >/dev/null 2>&1 & sleep 3"
sage "Das fragt die Liveness-Probe:"
lauf "curl -s localhost:$PORT/actuator/health/liveness; echo"
sage "Das fragt die Readiness-Probe:"
lauf "curl -s localhost:$PORT/actuator/health/readiness; echo"
sage "Keine Datenbank, kein externer Dienst darin. Fiele die Datenbank aus, bliebe die Liveness UP."
lauf "curl -s localhost:$PORT/; echo"
fertig
