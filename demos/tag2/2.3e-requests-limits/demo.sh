#!/usr/bin/env bash
# Demo 2.3e: Requests und Limits
# Folie: Tag 2, 2.3 "Requests und Limits" (Terminal-Streifen)
# Zeigt: die Werte im Pod und wie viel davon auf dem Node schon verplant ist.
# Voraussetzung: demos/tag2/00-vorbereiten/demo.sh. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.3e "Requests und Limits" "2.3, Requests und Limits"
require_betrieb

say "Was jeder hallo-Pod anfordert (Requests) und hoechstens darf (Limits):"
run "kubectl describe pod -l app=hallo | grep -A4 Limits"
say "Was auf dem Node durch Requests schon reserviert ist, egal ob genutzt:"
run "kubectl describe nodes | grep -A8 'Allocated resources'"
finish
