#!/usr/bin/env bash
# Demo 2.1a: kubectl im Alltag
# Folie: Tag 2, 2.1 "1.5 kompakt: kubectl im Alltag" (Terminal-Streifen)
# Zeigt: die drei Befehle, mit denen ihr jeden Pod ansehen koennt.
# Voraussetzung: hallo laeuft. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.1a "kubectl im Alltag" "2.1, 1.5 kompakt: kubectl im Alltag"
require_hallo

say "Status: Laeuft alles, wie oft wurde neu gestartet?"
run "kubectl get pods"
say "Details und Ereignisse. Wichtig ist der Abschnitt Events ganz unten."
run "kubectl describe pod -l app=hallo"
say "Was die Anwendung selbst ausgibt, jede Zeile mit dem Pod-Namen davor."
run "kubectl logs -l app=hallo --prefix --tail=5"
finish
