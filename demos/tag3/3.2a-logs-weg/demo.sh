#!/usr/bin/env bash
# Demo 3.2a: Logs verschwinden mit dem Pod
# Folie: Tag 3, 3.2 Logging und Monitoring
# Zeigt: kubectl logs liest nur vom laufenden Pod. Ist der Pod geloescht, sind
# seine Logs fuer kubectl weg. Darum braucht es den Logs Explorer.
# Loescht einen Pod von hallo, das Deployment ersetzt ihn.
# Voraussetzung: demos/tag2/00-vorbereiten/demo.sh. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 3.2a "Logs verschwinden mit dem Pod" "3.2 Logging und Monitoring"
require_betrieb
cleanup_with "kubectl rollout status deployment/hallo --timeout=180s"

POD="$(pod_of hallo)"
say "Die letzten Zeilen eines laufenden Pods:"
run "kubectl logs $POD --tail=5"
say "Der Pod wird geloescht, das Deployment startet einen neuen."
run "kubectl delete pod $POD"
say "Logs des alten Pods? Kubernetes kennt ihn nicht mehr."
run "kubectl logs $POD --tail=5"
run "kubectl rollout status deployment/hallo --timeout=180s"
NEW_POD="$(pod_of hallo)"
say "Der neue Pod beginnt mit leeren Logs."
run "kubectl logs $NEW_POD --tail=5"
say "--previous hilft nur nach einem Container-Neustart im selben Pod, nicht nach einem neuen Pod."
say "Auf GKE sammelt Cloud Logging die Zeilen ein. Dort sind sie auch nach dem Loeschen noch da."
finish
