#!/usr/bin/env bash
# Demo 2.2a: ConfigMap geaendert, alte Begruessung
# Folie: Tag 2, Check-in 2.2, Aufloesung 1/2 "ConfigMap geaendert, alte Begruessung"
# Zeigt: Umgebungsvariablen werden nur beim Containerstart gelesen.
# Aendert die ConfigMap und setzt sie am Ende auf die Datei zurueck.
# Voraussetzung: demos/tag2/00-vorbereiten/demo.sh. Dauer: etwa 4 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.2a "ConfigMap geaendert, alte Begruessung" "Check-in 2.2, Aufloesung 1/2"
require_betrieb
cleanup_with "kubectl apply -f lab02-hallo-app/betrieb/configmap.yaml && kubectl rollout restart deployment/hallo && kubectl rollout status deployment/hallo --timeout=180s"

say "Wert im laufenden Container:"
run "kubectl exec deploy/hallo -- printenv GREETING"
say "ConfigMap im Cluster aendern:"
run "kubectl patch configmap hallo-config -p '{\"data\":{\"GREETING\":\"Hallo aus der Demo\"}}'"
run "kubectl get configmap hallo-config -o jsonpath='{.data.GREETING}'; echo"
say "Der Container hat trotzdem noch den alten Wert:"
run "kubectl exec deploy/hallo -- printenv GREETING"
say "Neue Pods aus demselben Image und Template, kein Rebuild:"
run "kubectl rollout restart deployment/hallo"
run "kubectl rollout status deployment/hallo --timeout=180s"
run "kubectl exec deploy/hallo -- printenv GREETING"
finish
