#!/usr/bin/env bash
# Demo 2.2a: ConfigMap geaendert, alte Begruessung
# Folie: Tag 2, Check-in 2.2, Aufloesung 1/2 "ConfigMap geaendert, alte Begruessung"
# Zeigt: Umgebungsvariablen werden nur beim Containerstart gelesen.
# Aendert die ConfigMap und setzt sie am Ende auf die Datei zurueck.
# Voraussetzung: 00-vorbereiten.sh. Dauer: etwa 4 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.2a "ConfigMap geaendert, alte Begruessung" "Check-in 2.2, Aufloesung 1/2"
braucht_betrieb
aufraeumen_mit "kubectl apply -f lab02-hallo-app/betrieb/configmap.yaml && kubectl rollout restart deployment/hallo && kubectl rollout status deployment/hallo --timeout=180s"

sage "Wert im laufenden Container:"
lauf "kubectl exec deploy/hallo -- printenv GREETING"
sage "ConfigMap im Cluster aendern:"
lauf "kubectl patch configmap hallo-config -p '{\"data\":{\"GREETING\":\"Hallo aus der Demo\"}}'"
lauf "kubectl get configmap hallo-config -o jsonpath='{.data.GREETING}'; echo"
sage "Der Container hat trotzdem noch den alten Wert:"
lauf "kubectl exec deploy/hallo -- printenv GREETING"
sage "Neue Pods aus demselben Image und Template, kein Rebuild:"
lauf "kubectl rollout restart deployment/hallo"
lauf "kubectl rollout status deployment/hallo --timeout=180s"
lauf "kubectl exec deploy/hallo -- printenv GREETING"
fertig
