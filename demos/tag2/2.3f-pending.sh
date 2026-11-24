#!/usr/bin/env bash
# Demo 2.3f: Pending trotz freier CPU
# Folie: Tag 2, Check-in 2.3 Ressourcen, Aufloesung 1/2 "Pending trotz freier CPU"
# Zeigt: der Scheduler plant nach Requests, nicht nach tatsaechlicher Last.
# Sind die Requests verplant, bleibt ein Pod Pending, obwohl die CPU kaum arbeitet.
# Setzt den CPU-Request neuer Pods auf 60 Prozent der Node-CPU. Damit passt
# hoechstens ein neuer Pod, egal ob der Node 2 oder 8 CPUs meldet (Docker
# Desktop gibt minikube oft alle CPUs des Rechners, trotz --cpus=2).
# Am Ende gilt wieder betrieb/deployment.yaml.
# Voraussetzung: 00-vorbereiten.sh. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.3f "Pending trotz freier CPU" "Check-in 2.3 Ressourcen, Aufloesung 1/2"
braucht_betrieb
aufraeumen_mit "kubectl apply -f lab02-hallo-app/betrieb/deployment.yaml && kubectl rollout status deployment/hallo --timeout=180s"

# 60 Prozent der verplanbaren CPU des Nodes, in Millicores.
if [ "$MODUS" = trocken ]; then
  ANFORDERUNG=1200m
else
  demo_cpu="$(command kubectl --context "$KONTEXT" get nodes \
    -o jsonpath='{.items[0].status.allocatable.cpu}')"
  case "$demo_cpu" in
    *m) demo_milli="${demo_cpu%m}" ;;
    *) demo_milli=$(( demo_cpu * 1000 )) ;;
  esac
  ANFORDERUNG="$(( demo_milli * 6 / 10 ))m"
fi

sage "Vorher: verplante Ressourcen auf dem Node. Requests zaehlen, nicht die Last."
lauf "kubectl describe nodes | grep -A8 'Allocated resources'"
sage "Jeder neue Pod fordert jetzt $ANFORDERUNG CPU an, 60 Prozent des Nodes."
sage "Der Rolling Update startet neue Pods. Hoechstens einer passt noch."
lauf "kubectl set resources deployment/hallo -c hallo --requests=cpu=$ANFORDERUNG"
beobachte 40 "kubectl get pods -l app=hallo"
sage "Warum ein Pod Pending ist, steht in seinen Events:"
if [ "$MODUS" = trocken ]; then POD=POD; else
  POD="$(command kubectl --context "$KONTEXT" -n "$NS" get pods -l app=hallo \
    --field-selector=status.phase=Pending -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
fi
if [ -n "$POD" ]; then
  lauf "kubectl describe pod $POD | tail -n 4"
else
  sage "Kein Pod Pending. Alternative: Lab 3, Fall 4."
fi
sage "Die CPU ist verplant, aber kaum benutzt:"
lauf "kubectl describe nodes | grep -A8 'Allocated resources'"
fertig
