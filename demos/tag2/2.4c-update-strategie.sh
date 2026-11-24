#!/usr/bin/env bash
# Demo 2.4c (Extra): maxSurge und maxUnavailable
# Folie: Tag 2, Anhang, Extra-Aufloesung "maxSurge und maxUnavailable"
# Zeigt: die Update-Strategie und ein Update mit 4 Kopien. Skaliert am Ende auf 2.
# Voraussetzung: 00-vorbereiten.sh. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.4c "maxSurge und maxUnavailable (Extra)" "Anhang, Extra-Aufloesung maxSurge und maxUnavailable"
braucht_betrieb
aufraeumen_mit "kubectl scale deployment/hallo --replicas=2"

lauf "kubectl get deployment hallo -o jsonpath='{.spec.strategy}'; echo"
sage "Im Repo maxSurge 1, maxUnavailable 0. Bei 4 Kopien: hoechstens 5 Pods, nie weniger als 4 bereit."
sage "Ohne Angabe gilt je 25 Prozent: bei 4 Kopien mindestens 3, hoechstens 5."
lauf "kubectl scale deployment/hallo --replicas=4"
lauf "kubectl rollout status deployment/hallo --timeout=180s"
lauf "kubectl rollout restart deployment/hallo"
beobachte 60 "kubectl get pods -l app=hallo"
fertig
