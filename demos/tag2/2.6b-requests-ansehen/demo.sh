#!/usr/bin/env bash
# Demo 2.6b: Autopilot ohne Requests
# Folie: Tag 2, Check-in 2.6, Aufloesung 2/2 "Autopilot ohne Requests"
# Zeigt: die Requests eines Pods. Lokal stehen sie im Manifest, Autopilot setzt fehlende selbst.
# Voraussetzung: demos/tag2/00-vorbereiten/demo.sh. Dauer: etwa 1 Minute.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.6b "Autopilot ohne Requests" "Check-in 2.6, Aufloesung 2/2"
require_betrieb

run "kubectl get pods -l app=hallo -o jsonpath='{..resources}'; echo"
say "Auf Autopilot zahlt ihr nach diesen Werten. Zu hoch kostet, zu niedrig bremst."
finish
