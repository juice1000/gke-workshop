#!/usr/bin/env bash
# Demo 2.3b: Die Anwendung haengt
# Folie: Tag 2, Check-in 2.3 Probes, Aufloesung 1/3 "Die Anwendung haengt"
# Zeigt: Readiness nimmt einen Pod aus dem Service, ohne ihn neu zu starten.
# Ein haengender Prozess laesst sich nicht sauber nachbauen. Stattdessen
# scheitert die Readiness eines neuen Pods (falscher Pfad). Rollback am Ende.
# Voraussetzung: 00-vorbereiten.sh. Dauer: etwa 4 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.3b "Die Anwendung haengt" "Check-in 2.3 Probes, Aufloesung 1/3"
braucht_betrieb
aufraeumen_mit "kubectl rollout undo deployment/hallo && kubectl rollout status deployment/hallo --timeout=180s"

sage "Readiness alle 5 s, nach 3 Fehlschlaegen raus aus dem Service (etwa 15 s)."
sage "Liveness alle 10 s, nach 3 Fehlschlaegen Neustart (etwa 30 s)."
lauf "kubectl describe pod -l app=hallo | grep -E 'Liveness|Readiness'"
sage "Im Service: jeder Pod mit Ready true."
lauf "kubectl describe endpointslices -l kubernetes.io/service-name=hallo | grep -E 'Addresses|Ready|TargetRef'"

sage "Fehler einbauen: Readiness eines neuen Pods fragt einen Pfad, den es nicht gibt."
lauf "kubectl patch deployment hallo --type=json -p='[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/readinessProbe/httpGet/path\",\"value\":\"/gibtsnicht\"}]'"
beobachte 60 "kubectl get pods -l app=hallo"
sage "Neuer Pod: Running, READY 0/1, RESTARTS 0. Die alten bleiben bereit (maxUnavailable: 0)."
lauf "kubectl describe endpointslices -l kubernetes.io/service-name=hallo | grep -E 'Addresses|Ready|TargetRef'"
POD="$(pod_von hallo)"
lauf "kubectl describe pod $POD | grep -i 'readiness probe failed' | tail -n 2"
fertig
