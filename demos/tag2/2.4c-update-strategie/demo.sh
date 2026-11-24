#!/usr/bin/env bash
# Demo 2.4c (Extra): maxSurge und maxUnavailable
# Folie: Tag 2, Anhang, Extra-Aufloesung "maxSurge und maxUnavailable"
# Zeigt: die Update-Strategie und ein Update mit 4 Kopien. Skaliert am Ende auf 2.
# Voraussetzung: demos/tag2/00-vorbereiten/demo.sh. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.4c "maxSurge und maxUnavailable (Extra)" "Anhang, Extra-Aufloesung maxSurge und maxUnavailable"
require_betrieb
cleanup_with "kubectl scale deployment/hallo --replicas=2"

run "kubectl get deployment hallo -o jsonpath='{.spec.strategy}'; echo"
say "Im Repo maxSurge 1, maxUnavailable 0. Bei 4 Kopien: hoechstens 5 Pods, nie weniger als 4 bereit."
say "Ohne Angabe gilt je 25 Prozent: bei 4 Kopien mindestens 3, hoechstens 5."
run "kubectl scale deployment/hallo --replicas=4"
run "kubectl rollout status deployment/hallo --timeout=180s"
run "kubectl rollout restart deployment/hallo"
observe 60 "kubectl get pods -l app=hallo"
finish
