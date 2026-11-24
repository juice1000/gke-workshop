#!/usr/bin/env bash
# Demo 2.1f: Zwei ReplicaSets
# Folie: Tag 2, Check-in 2.1, Aufloesung 3/3 "Zwei ReplicaSets"
# Zeigt: jede Aenderung am Pod-Template erzeugt ein neues ReplicaSet,
# das alte bleibt mit 0 Pods fuer ein Rollback stehen.
# Voraussetzung: hallo laeuft. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.1f "Zwei ReplicaSets" "Check-in 2.1, Aufloesung 3/3"
require_hallo

run "kubectl get replicasets -l app=hallo"
say "rollout restart schreibt die Uhrzeit ins Pod-Template. Das zaehlt als Aenderung."
run "kubectl rollout restart deployment/hallo"
run "kubectl rollout status deployment/hallo --timeout=180s"
say "Jetzt ein ReplicaSet mehr. Das alte steht mit 0 Pods da."
run "kubectl get replicasets -l app=hallo"
say "Genau diese Liste nutzt rollout undo in 2.4."
run "kubectl rollout history deployment/hallo"
finish
