#!/usr/bin/env bash
# Demo 3.6a: Gesperrter Node, Ersatz-Pod Pending
# Folie: Tag 3, 3.6 Lab 7: Vertiefung Betrieb
# Zeigt: cordon sperrt den Node fuer neue Pods. Laufende Pods bleiben. Ein
# Ersatz-Pod findet im Ein-Node-Cluster keinen Platz und bleibt Pending.
# Sperre wird am Ende aufgehoben, auch bei Strg+C.
# Voraussetzung: demos/tag2/00-vorbereiten/demo.sh. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 3.6a "Gesperrter Node, Ersatz-Pod Pending" "3.6 Lab 7: Vertiefung Betrieb"
require_betrieb

if [ "$MODE" = dry ]; then NODE_NAME=minikube; else
  NODE_NAME="$(command kubectl --context "$CONTEXT" get nodes -o jsonpath='{.items[0].metadata.name}')"
fi
cleanup_with "kubectl uncordon $NODE_NAME && kubectl rollout status deployment/hallo --timeout=180s"

say "Node $NODE_NAME fuer neue Pods sperren:"
run "kubectl cordon $NODE_NAME"
run "kubectl get nodes"
say "Die laufenden Pods merken davon nichts:"
run "kubectl get pods -l app=hallo"
POD="$(pod_of hallo)"
say "Ein Pod geht verloren. Das Deployment will Ersatz."
run "kubectl delete pod $POD"
observe 15 "kubectl get pods -l app=hallo"
say "Warum Pending? Die Events nennen den gesperrten Node:"
if [ "$MODE" = dry ]; then PENDING=POD; else
  PENDING="$(command kubectl --context "$CONTEXT" -n "$NS" get pods -l app=hallo \
    --field-selector=status.phase=Pending -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
fi
if [ -n "$PENDING" ]; then
  run "kubectl describe pod $PENDING | tail -n 4"
else
  say "Kein Pod Pending. Ist der Node wirklich gesperrt? kubectl get nodes"
fi
say "Sperre aufheben. Der Ersatz-Pod startet."
finish
