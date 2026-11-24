#!/usr/bin/env bash
# Demo 2.4b: Rollout mit falschem Tag
# Folie: Tag 2, Check-in 2.4, Aufloesung 1/2 "Rollout mit falschem Tag"
# Zeigt: die alten Pods bedienen weiter, der Rollout bleibt stehen, kein Auto-Rollback.
# Rollback am Ende.
# Voraussetzung: demos/tag2/00-vorbereiten/demo.sh. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.4b "Rollout mit falschem Tag" "Check-in 2.4, Aufloesung 1/2"
require_betrieb
cleanup_with "kubectl rollout undo deployment/hallo && kubectl rollout status deployment/hallo --timeout=180s"

say "Ein Image-Tag, den es nicht gibt:"
run "kubectl set image deployment/hallo hallo=hallo-app:nicht-vorhanden"
run "kubectl rollout status deployment/hallo --timeout=30s"
say "Alte Pods 1/1 Running, der neue haengt beim Laden des Images:"
run "kubectl get pods -l app=hallo"
say "So lange wartet das Deployment, bevor es ProgressDeadlineExceeded meldet (Repo 180, Standard 600):"
run "kubectl get deploy hallo -o jsonpath='{.spec.progressDeadlineSeconds}'; echo"
say "Zurueckrollen muss ein Mensch oder die Pipeline:"
finish
