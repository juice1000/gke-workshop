#!/usr/bin/env bash
# Demo 2.3h (Extra): Autoscaler bei Lastspitze
# Folie: Tag 2, Anhang, Extra-Aufloesung "Autoscaler bei Lastspitze"
# Zeigt: die Messwerte, nach denen ein HPA skaliert, und einen HPA fuer hallo.
# Schaltet das minikube-Addon metrics-server ein. Loescht den HPA am Ende.
# Voraussetzung: 00-vorbereiten.sh. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.3h "Autoscaler bei Lastspitze (Extra)" "Anhang, Extra-Aufloesung Autoscaler bei Lastspitze"
braucht_betrieb
aufraeumen_mit "kubectl delete -f lab02-hallo-app/extra/hpa.yaml --ignore-not-found"

lauf "kubectl get hpa"
sage "Ohne metrics-server gibt es keine Messwerte. Einschalten, dann etwa eine Minute warten."
lauf "minikube addons enable metrics-server"
beobachte 90 "kubectl top pods 2>&1 | head -n 5"
sage "Ein HPA fuer hallo: 2 bis 4 Pods, Ziel 50 Prozent der CPU-Requests."
lauf "kubectl apply -f lab02-hallo-app/extra/hpa.yaml"
beobachte 30 "kubectl get hpa"
sage "Der HPA aendert nur die Anzahl der Pods. Wohin Anfragen gehen, entscheidet er nicht."
fertig
