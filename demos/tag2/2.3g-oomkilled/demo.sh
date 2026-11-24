#!/usr/bin/env bash
# Demo 2.3g: OOMKilled
# Folie: Tag 2, Check-in 2.3 Ressourcen, Aufloesung 2/2 "OOMKilled"
# Zeigt: ein Container ueber seinem Speicherlimit wird beendet (Exit 137).
# Nutzt lab03-defekt/extra/oom.yaml und loescht es am Ende.
# Voraussetzung: hallo-app:1.0 geladen. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.3g "OOMKilled" "Check-in 2.3 Ressourcen, Aufloesung 2/2"
[ -f lab03-defekt/extra/oom.yaml ] || fail "lab03-defekt/extra/oom.yaml fehlt."
cleanup_with "kubectl delete -f lab03-defekt/extra/oom.yaml --ignore-not-found"

say "Ein Pod mit 128Mi Limit, dessen JVM sofort 200 MiB Heap belegt:"
run "grep -E 'Xms|memory' lab03-defekt/extra/oom.yaml"
run "kubectl apply -f lab03-defekt/extra/oom.yaml"
observe 60 "kubectl get pods -l app=oom"
say "RESTARTS steigt, dazwischen OOMKilled. Der Beleg steht unter Last State:"
POD="$(pod_of oom)"
run "kubectl describe pod $POD | grep -A4 'Last State'"
say "Exit Code 137 = 128 + Signal 9: von aussen beendet, nicht von der Anwendung."
finish
