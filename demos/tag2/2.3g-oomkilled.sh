#!/usr/bin/env bash
# Demo 2.3g: OOMKilled
# Folie: Tag 2, Check-in 2.3 Ressourcen, Aufloesung 2/2 "OOMKilled"
# Zeigt: ein Container ueber seinem Speicherlimit wird beendet (Exit 137).
# Nutzt lab03-defekt/extra/oom.yaml und loescht es am Ende.
# Voraussetzung: hallo-app:1.0 geladen. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.3g "OOMKilled" "Check-in 2.3 Ressourcen, Aufloesung 2/2"
[ -f lab03-defekt/extra/oom.yaml ] || fehler "lab03-defekt/extra/oom.yaml fehlt."
aufraeumen_mit "kubectl delete -f lab03-defekt/extra/oom.yaml --ignore-not-found"

sage "Ein Pod mit 128Mi Limit, dessen JVM sofort 200 MiB Heap belegt:"
lauf "grep -E 'Xms|memory' lab03-defekt/extra/oom.yaml"
lauf "kubectl apply -f lab03-defekt/extra/oom.yaml"
beobachte 60 "kubectl get pods -l app=oom"
sage "RESTARTS steigt, dazwischen OOMKilled. Der Beleg steht unter Last State:"
POD="$(pod_von oom)"
lauf "kubectl describe pod $POD | grep -A4 'Last State'"
sage "Exit Code 137 = 128 + Signal 9: von aussen beendet, nicht von der Anwendung."
fertig
