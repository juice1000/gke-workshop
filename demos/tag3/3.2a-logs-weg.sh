#!/usr/bin/env bash
# Demo 3.2a: Logs verschwinden mit dem Pod
# Folie: Tag 3, 3.2 Logging und Monitoring
# Zeigt: kubectl logs liest nur vom laufenden Pod. Ist der Pod geloescht, sind
# seine Logs fuer kubectl weg. Darum braucht es den Logs Explorer.
# Loescht einen Pod von hallo, das Deployment ersetzt ihn.
# Voraussetzung: 00-vorbereiten.sh aus tag2. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 3.2a "Logs verschwinden mit dem Pod" "3.2 Logging und Monitoring"
braucht_betrieb
aufraeumen_mit "kubectl rollout status deployment/hallo --timeout=180s"

POD="$(pod_von hallo)"
sage "Die letzten Zeilen eines laufenden Pods:"
lauf "kubectl logs $POD --tail=5"
sage "Der Pod wird geloescht, das Deployment startet einen neuen."
lauf "kubectl delete pod $POD"
sage "Logs des alten Pods? Kubernetes kennt ihn nicht mehr."
lauf "kubectl logs $POD --tail=5"
lauf "kubectl rollout status deployment/hallo --timeout=180s"
NEU="$(pod_von hallo)"
sage "Der neue Pod beginnt mit leeren Logs."
lauf "kubectl logs $NEU --tail=5"
sage "--previous hilft nur nach einem Container-Neustart im selben Pod, nicht nach einem neuen Pod."
sage "Auf GKE sammelt Cloud Logging die Zeilen ein. Dort sind sie auch nach dem Loeschen noch da."
fertig
