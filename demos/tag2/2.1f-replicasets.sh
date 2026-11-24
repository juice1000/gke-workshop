#!/usr/bin/env bash
# Demo 2.1f: Zwei ReplicaSets
# Folie: Tag 2, Check-in 2.1, Aufloesung 3/3 "Zwei ReplicaSets"
# Zeigt: jede Aenderung am Pod-Template erzeugt ein neues ReplicaSet,
# das alte bleibt mit 0 Pods fuer ein Rollback stehen.
# Voraussetzung: hallo laeuft. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.1f "Zwei ReplicaSets" "Check-in 2.1, Aufloesung 3/3"
braucht_hallo

lauf "kubectl get replicasets -l app=hallo"
sage "rollout restart schreibt die Uhrzeit ins Pod-Template. Das zaehlt als Aenderung."
lauf "kubectl rollout restart deployment/hallo"
lauf "kubectl rollout status deployment/hallo --timeout=180s"
sage "Jetzt ein ReplicaSet mehr. Das alte steht mit 0 Pods da."
lauf "kubectl get replicasets -l app=hallo"
sage "Genau diese Liste nutzt rollout undo in 2.4."
lauf "kubectl rollout history deployment/hallo"
fertig
