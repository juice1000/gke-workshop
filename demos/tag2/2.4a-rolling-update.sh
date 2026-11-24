#!/usr/bin/env bash
# Demo 2.4a: Rolling Update
# Folie: Tag 2, 2.4 "Rolling Update: Austausch im Betrieb" (Terminal-Streifen)
# Zeigt: Pods werden schrittweise getauscht, ein alter geht erst, wenn ein neuer bereit ist.
# Voraussetzung: hallo laeuft. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.4a "Rolling Update" "2.4, Rolling Update: Austausch im Betrieb"
braucht_hallo

sage "Gleiches Image, neue Pods. Achtet auf die Reihenfolge: erst neu und bereit, dann alt weg."
lauf "kubectl rollout restart deployment/hallo"
beobachte 60 "kubectl get pods -l app=hallo"
lauf "kubectl rollout status deployment/hallo --timeout=180s"
fertig
