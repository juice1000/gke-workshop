#!/usr/bin/env bash
# Demo 2.3e: Requests und Limits
# Folie: Tag 2, 2.3 "Requests und Limits" (Terminal-Streifen)
# Zeigt: die Werte im Pod und wie viel davon auf dem Node schon verplant ist.
# Voraussetzung: 00-vorbereiten.sh. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.3e "Requests und Limits" "2.3, Requests und Limits"
braucht_betrieb

sage "Was jeder hallo-Pod anfordert (Requests) und hoechstens darf (Limits):"
lauf "kubectl describe pod -l app=hallo | grep -A4 Limits"
sage "Was auf dem Node durch Requests schon reserviert ist, egal ob genutzt:"
lauf "kubectl describe nodes | grep -A8 'Allocated resources'"
fertig
