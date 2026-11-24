#!/usr/bin/env bash
# Demo 3.6a: Gesperrter Node, Ersatz-Pod Pending
# Folie: Tag 3, 3.6 Lab 6: Vertiefung Betrieb
# Zeigt: cordon sperrt den Node fuer neue Pods. Laufende Pods bleiben. Ein
# Ersatz-Pod findet im Ein-Node-Cluster keinen Platz und bleibt Pending.
# Sperre wird am Ende aufgehoben, auch bei Strg+C.
# Voraussetzung: 00-vorbereiten.sh aus tag2. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 3.6a "Gesperrter Node, Ersatz-Pod Pending" "3.6 Lab 6: Vertiefung Betrieb"
braucht_betrieb

if [ "$MODUS" = trocken ]; then NODE=minikube; else
  NODE="$(command kubectl --context "$KONTEXT" get nodes -o jsonpath='{.items[0].metadata.name}')"
fi
aufraeumen_mit "kubectl uncordon $NODE && kubectl rollout status deployment/hallo --timeout=180s"

sage "Node $NODE fuer neue Pods sperren:"
lauf "kubectl cordon $NODE"
lauf "kubectl get nodes"
sage "Die laufenden Pods merken davon nichts:"
lauf "kubectl get pods -l app=hallo"
POD="$(pod_von hallo)"
sage "Ein Pod geht verloren. Das Deployment will Ersatz."
lauf "kubectl delete pod $POD"
beobachte 15 "kubectl get pods -l app=hallo"
sage "Warum Pending? Die Events nennen den gesperrten Node:"
if [ "$MODUS" = trocken ]; then PENDING=POD; else
  PENDING="$(command kubectl --context "$KONTEXT" -n "$NS" get pods -l app=hallo \
    --field-selector=status.phase=Pending -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
fi
if [ -n "$PENDING" ]; then
  lauf "kubectl describe pod $PENDING | tail -n 4"
else
  sage "Kein Pod Pending. Ist der Node wirklich gesperrt? kubectl get nodes"
fi
sage "Sperre aufheben. Der Ersatz-Pod startet."
fertig
