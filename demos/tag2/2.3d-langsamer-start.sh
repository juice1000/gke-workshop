#!/usr/bin/env bash
# Demo 2.3d: Langsamer Start
# Folie: Tag 2, Check-in 2.3 Probes, Aufloesung 3/3 "Langsamer Start"
# Zeigt: ohne Startup-Probe toetet eine zu strenge Liveness den Container,
# bevor die JVM fertig ist. Ergebnis: Neustarts bis CrashLoopBackOff.
# Entfernt die Startup-Probe im Cluster. Rollback am Ende.
# Voraussetzung: 00-vorbereiten.sh. Dauer: etwa 4 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.3d "Langsamer Start" "Check-in 2.3 Probes, Aufloesung 3/3"
braucht_betrieb
aufraeumen_mit "kubectl rollout undo deployment/hallo && kubectl rollout status deployment/hallo --timeout=180s"

sage "So ist es im Repo: Startup alle 5 s, 30 Versuche, also bis zu 150 s fuer den Start."
lauf "kubectl describe pod -l app=hallo | grep -E 'Startup|Liveness'"

sage "Die Frage nachbauen: Startup-Probe weg, Liveness alle 2 s, ein Fehlschlag reicht."
sage "Die erste Liveness-Pruefung kommt sofort, bevor die JVM fertig ist. Ein Fehlschlag reicht. Die alten Pods bleiben bereit."
lauf "kubectl patch deployment hallo --type=json -p='[{\"op\":\"remove\",\"path\":\"/spec/template/spec/containers/0/startupProbe\"},{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/livenessProbe/periodSeconds\",\"value\":2},{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/livenessProbe/failureThreshold\",\"value\":1}]'"
beobachte 90 "kubectl get pods -l app=hallo"
sage "RESTARTS steigt, spaeter CrashLoopBackOff. Der Beleg:"
POD="$(pod_von hallo)"
lauf "kubectl describe pod $POD | grep -E 'Liveness probe failed|Killing|Back-off' | tail -n 4"
sage "Die Logs davor zeigen einen Start, der nie fertig wurde:"
lauf "kubectl logs $POD --previous | tail -n 5"
fertig
