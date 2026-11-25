#!/usr/bin/env bash
# Pipeline als Skript (Lab 6). Dieselben Befehle wie von Hand, plus ein Gate,
# das gruen oder rot entscheidet, plus eine automatische Reaktion.
#
# Aufruf aus dem Repository-Hauptordner:
#   bash scripts/pipeline.sh DATEI_ODER_ORDNER [--build]
# Umgebung: IMAGE aus Lab 4, fuer Etappe D auch PROJECT_ID.
# Ziel: aktueller kubectl-Kontext und dessen Namespace.
#
# Stufe            entspricht in TeamCity
# [1/5] Pruefen    "Validate": der API-Server prueft das Manifest (Dry Run)
# [2/5] Build      "Build" und "Push", nur mit --build
# [3/5] Deploy     "Deploy": kubectl apply
# [4/5] Gate       "Verify": rollout status mit Zeitgrenze
# [5/5] Rollback   "If build failed": Belege sichern, rollout undo
#
# Exit-Code: 0 gruen, 1 rot (zurueckgerollt), 2 vor dem Deploy gestoppt.
set -u
QUELLE="${1:-}"
TIMEOUT="${PIPELINE_TIMEOUT:-180}"

stufe() { printf '\n[%s] %s\n' "$1" "$2"; }
stopp() { printf '  FEHLER: %s\n\nPipeline GESTOPPT: nichts ausgerollt.\n' "$1"; exit 2; }
# Alle Dateien hintereinander, Platzhalter ersetzt. Die Dateien bleiben unveraendert.
manifest() {
  if [ -d "$QUELLE" ]; then cat "$QUELLE"/*.yaml; else cat "$QUELLE"; fi \
    | sed -e "s#WORKSHOP_IMAGE#$IMAGE#" -e "s#WORKSHOP_PROJECT#${PROJECT_ID:-}#"
}

stufe 1/5 "Pruefen"
[ -e "$QUELLE" ] || stopp "Aufruf: bash scripts/pipeline.sh DATEI_ODER_ORDNER [--build]"
[ -n "${IMAGE:-}" ] || stopp "IMAGE ist nicht gesetzt (Lab 4, Schritt 2)."
if grep -rq WORKSHOP_PROJECT "$QUELLE" && [ -z "${PROJECT_ID:-}" ]; then
  stopp "PROJECT_ID ist nicht gesetzt (Lab 4, Schritt 1)."
fi
printf '  Ziel: Kontext %s, Namespace %s\n' "$(kubectl config current-context)" \
  "$(kubectl config view --minify -o jsonpath='{..namespace}')"
manifest | kubectl apply --dry-run=server -f - | sed 's/^/  /'
[ "${PIPESTATUS[1]}" = 0 ] || stopp "Der API-Server lehnt das Manifest ab."

stufe 2/5 "Build"
if [ "${2:-}" = --build ]; then
  IMAGE="${IMAGE%:*}:2.0-$(git rev-parse --short HEAD)"
  # GKE-Nodes sind amd64, auch wenn der eigene Rechner ARM ist.
  docker build --platform linux/amd64 --build-arg "APP_VERSION=${IMAGE##*:}" -t "$IMAGE" lab02-hallo-app \
    || stopp "docker build fehlgeschlagen."
  docker push "$IMAGE" || stopp "docker push fehlgeschlagen."
  printf '  Neues Image: %s\n' "$IMAGE"
else
  printf '  uebersprungen (ohne --build gilt IMAGE)\n'
fi

stufe 3/5 "Deploy"
manifest | kubectl apply -f - | sed 's/^/  /'
[ "${PIPESTATUS[1]}" = 0 ] || { printf '\nPipeline ROT: apply fehlgeschlagen.\n'; exit 1; }

stufe 4/5 "Gate (hoechstens ${TIMEOUT}s)"
if kubectl rollout status deployment/hallo --timeout="${TIMEOUT}s" | sed 's/^/  /' && [ "${PIPESTATUS[0]}" = 0 ]; then
  stufe 5/5 "Rollback"
  printf '  uebersprungen\n\nPipeline GRUEN: %s laeuft.\n' \
    "$(kubectl get deployment hallo -o jsonpath='{.spec.template.spec.containers[0].image}')"
  exit 0
fi

stufe 5/5 "Rollback"
BELEGE="out/pipeline/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BELEGE"
kubectl get pods -o wide > "$BELEGE/pods.txt" 2>&1
kubectl describe pods -l app=hallo > "$BELEGE/describe.txt" 2>&1
kubectl get events --sort-by=.lastTimestamp > "$BELEGE/events.txt" 2>&1
NEUESTER="$(kubectl get pods -l app=hallo --sort-by=.metadata.creationTimestamp -o name | tail -1)"
{ kubectl logs "$NEUESTER" --tail=100; kubectl logs "$NEUESTER" --previous --tail=100; } > "$BELEGE/logs.txt" 2>&1
printf '  Belege: %s/ (pods, describe, events, logs)\n' "$BELEGE"
kubectl rollout undo deployment/hallo | sed 's/^/  /'
kubectl rollout status deployment/hallo --timeout=300s | sed 's/^/  /'
printf '\nPipeline ROT: Release zurueckgerollt. Belege: %s/\n' "$BELEGE"
exit 1
