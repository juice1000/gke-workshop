#!/usr/bin/env bash
# Demo 2.1a: kubectl im Alltag
# Folie: Tag 2, 2.1 "1.5 kompakt: kubectl im Alltag" (Terminal-Streifen)
# Zeigt: die drei Befehle, mit denen ihr jeden Pod ansehen koennt.
# Voraussetzung: hallo laeuft. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.1a "kubectl im Alltag" "2.1, 1.5 kompakt: kubectl im Alltag"
braucht_hallo

sage "Status: Laeuft alles, wie oft wurde neu gestartet?"
lauf "kubectl get pods"
sage "Details und Ereignisse. Wichtig ist der Abschnitt Events ganz unten."
lauf "kubectl describe pod -l app=hallo"
sage "Was die Anwendung selbst ausgibt, jede Zeile mit dem Pod-Namen davor."
lauf "kubectl logs -l app=hallo --prefix --tail=5"
fertig
