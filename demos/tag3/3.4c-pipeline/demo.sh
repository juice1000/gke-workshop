#!/usr/bin/env bash
# Demo 3.4c: Unsere Pipeline
# Folie: Tag 3, 3.4 "Unsere Pipeline"
# Zeigt: scripts/pipeline.sh einmal gruen mit der Lab-5-Loesung, einmal rot
# mit Stoerung 6.3. Rot heisst: Belege gesichert, zurueckgerollt, Exit-Code 1.
# Am Ende gilt wieder lab02-hallo-app/betrieb/.
# Voraussetzung: demos/tag2/00-vorbereiten/demo.sh. Dauer: etwa 4 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 3.4c "Unsere Pipeline" "3.4 Unsere Pipeline"
require_betrieb
cleanup_with "kubectl apply -f lab02-hallo-app/betrieb/ && kubectl rollout restart deployment/hallo && kubectl rollout status deployment/hallo --timeout=180s"

# Die Pipeline ruft kubectl selbst auf, mit genau diesem Ziel.
export WORKSHOP_CONTEXT="$CONTEXT" WORKSHOP_NAMESPACE="$NS"
# Kuerzeres Gate als im Lab, damit der rote Lauf in die Demo passt.
export PIPELINE_TIMEOUT=45
if [ "$MODE" != dry ]; then
  rm -rf out/demo-3.4c
  python3 scripts/render.py lab06-abschluss --image hallo-app:2.0 --output out/demo-3.4c >/dev/null
fi

say "Die Pipeline in einem Satz: dieselben Befehle wie von Hand, plus ein Gate, plus eine Reaktion."
run "sed -n '/^# Stufe/,/^# \[5\/5\]/p' scripts/pipeline.sh"
say "Gruener Lauf mit der Loesung aus Lab 6. Achtet auf die fuenf Stufen."
run "bash scripts/pipeline.sh out/demo-3.4c/loesung/; echo \"Exit-Code: \$?\""
say "Roter Lauf mit Stoerung 6.3. Das Gate wartet hier hoechstens 45 Sekunden."
run "bash scripts/pipeline.sh out/demo-3.4c/stoerungen/6.3-bereitschaft.yaml; echo \"Exit-Code: \$?\""
say "Vor dem Rollback hat die Pipeline Belege gesichert:"
run "BELEGE=\$(ls -d out/pipeline/2* | tail -1); ls \"\$BELEGE\""
run "grep 'Readiness probe failed' \"\$BELEGE/describe.txt\" | tail -1"
say "Die alten Pods haben die ganze Zeit bedient, jetzt laeuft wieder der alte Stand:"
run "kubectl get pods -l app=hallo"
say "TeamCity sieht nur den Exit-Code: 0 gruen, 1 rot und zurueckgerollt, 2 gar nicht erst ausgerollt."
finish
