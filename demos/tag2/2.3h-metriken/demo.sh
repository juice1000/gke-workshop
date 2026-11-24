#!/usr/bin/env bash
# Demo 2.3h (Extra): Autoscaler bei Lastspitze
# Folie: Tag 2, Anhang, Extra-Aufloesung "Autoscaler bei Lastspitze"
# Zeigt: die Messwerte, nach denen ein HPA skaliert, und einen HPA fuer hallo.
# Schaltet das minikube-Addon metrics-server ein. Loescht den HPA am Ende.
# Voraussetzung: demos/tag2/00-vorbereiten/demo.sh. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.3h "Autoscaler bei Lastspitze (Extra)" "Anhang, Extra-Aufloesung Autoscaler bei Lastspitze"
require_betrieb
cleanup_with "kubectl delete -f lab02-hallo-app/extra/hpa.yaml --ignore-not-found"

run "kubectl get hpa"
say "Ohne metrics-server gibt es keine Messwerte. Einschalten, dann etwa eine Minute warten."
run "minikube addons enable metrics-server"
observe 90 "kubectl top pods 2>&1 | head -n 5"
say "Ein HPA fuer hallo: 2 bis 4 Pods, Ziel 50 Prozent der CPU-Requests."
run "kubectl apply -f lab02-hallo-app/extra/hpa.yaml"
observe 30 "kubectl get hpa"
say "Der HPA aendert nur die Anzahl der Pods. Wohin Anfragen gehen, entscheidet er nicht."
finish
