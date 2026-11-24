#!/usr/bin/env bash
# Demo 2.4b: Rollout mit falschem Tag
# Folie: Tag 2, Check-in 2.4, Aufloesung 1/2 "Rollout mit falschem Tag"
# Zeigt: die alten Pods bedienen weiter, der Rollout bleibt stehen, kein Auto-Rollback.
# Rollback am Ende.
# Voraussetzung: 00-vorbereiten.sh. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.4b "Rollout mit falschem Tag" "Check-in 2.4, Aufloesung 1/2"
braucht_betrieb
aufraeumen_mit "kubectl rollout undo deployment/hallo && kubectl rollout status deployment/hallo --timeout=180s"

sage "Ein Image-Tag, den es nicht gibt:"
lauf "kubectl set image deployment/hallo hallo=hallo-app:nicht-vorhanden"
lauf "kubectl rollout status deployment/hallo --timeout=30s"
sage "Alte Pods 1/1 Running, der neue haengt beim Laden des Images:"
lauf "kubectl get pods -l app=hallo"
sage "So lange wartet das Deployment, bevor es ProgressDeadlineExceeded meldet (Repo 180, Standard 600):"
lauf "kubectl get deploy hallo -o jsonpath='{.spec.progressDeadlineSeconds}'; echo"
sage "Zurueckrollen muss ein Mensch oder die Pipeline:"
fertig
