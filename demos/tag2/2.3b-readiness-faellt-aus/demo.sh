#!/usr/bin/env bash
# Demo 2.3b: Die Anwendung haengt
# Folie: Tag 2, Check-in 2.3 Probes, Aufloesung 1/3 "Die Anwendung haengt"
# Zeigt: Readiness nimmt einen Pod aus dem Service, ohne ihn neu zu starten.
# Ein haengender Prozess laesst sich nicht sauber nachbauen. Stattdessen
# scheitert die Readiness eines neuen Pods (falscher Pfad). Rollback am Ende.
# Voraussetzung: demos/tag2/00-vorbereiten/demo.sh. Dauer: etwa 4 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.3b "Die Anwendung haengt" "Check-in 2.3 Probes, Aufloesung 1/3"
require_betrieb
cleanup_with "kubectl rollout undo deployment/hallo && kubectl rollout status deployment/hallo --timeout=180s"

say "Readiness alle 5 s, nach 3 Fehlschlaegen raus aus dem Service (etwa 15 s)."
say "Liveness alle 10 s, nach 3 Fehlschlaegen Neustart (etwa 30 s)."
run "kubectl describe pod -l app=hallo | grep -E 'Liveness|Readiness'"
say "Im Service: jeder Pod mit Ready true."
run "kubectl describe endpointslices -l kubernetes.io/service-name=hallo | grep -E 'Addresses|Ready|TargetRef'"

say "Fehler einbauen: Readiness eines neuen Pods fragt einen Pfad, den es nicht gibt."
run "kubectl patch deployment hallo --type=json -p='[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/readinessProbe/httpGet/path\",\"value\":\"/gibtsnicht\"}]'"
observe 60 "kubectl get pods -l app=hallo"
say "Neuer Pod: Running, READY 0/1, RESTARTS 0. Die alten bleiben bereit (maxUnavailable: 0)."
run "kubectl describe endpointslices -l kubernetes.io/service-name=hallo | grep -E 'Addresses|Ready|TargetRef'"
POD="$(pod_of hallo)"
run "kubectl describe pod $POD | grep -i 'readiness probe failed' | tail -n 2"
finish
