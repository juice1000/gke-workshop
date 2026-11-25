#!/usr/bin/env bash
# Pipeline als Skript (Tag 3, Lab 6). Dieselben Befehle wie von Hand, plus ein
# Gate, das gruen oder rot entscheidet, plus eine automatische Reaktion.
#
# Aufruf aus dem Repository-Hauptordner:
#   bash scripts/pipeline.sh MANIFEST [--build]
#   MANIFEST: gerenderte Datei oder Ordner, z. B. out/lab06/starter/
#   Ein Manifest ohne Deployment (nur Service oder ConfigMap) ist erlaubt,
#   wenn deployment/hallo im Namespace schon laeuft.
#
# Umgebung wie in Lab 4 und 5: WORKSHOP_CONTEXT, WORKSHOP_NAMESPACE, IMAGE.
# Optional: PIPELINE_TIMEOUT in Sekunden (Standard 120).
#
# Stufe            entspricht in TeamCity
# [1/5] Pruefen    Build-Schritt "Validate" (Eingaben, Kontext, Dry Run)
# [2/5] Build      Build-Schritte "Build" und "Push" (Docker Runner)
# [3/5] Deploy     Build-Schritt "Deploy" (kubectl apply)
# [4/5] Gate       Build-Schritt "Verify": Exit-Code entscheidet gruen/rot
# [5/5] Rollback   Schritt "Rollback", nur bei Fehler ("If build failed")
#
# Das Gate prueft immer deployment/hallo und, falls vorhanden, deployment/verkehr.
# Rollback: "rollout undo" nur fuer Deployments, die das Manifest geaendert hat.
# Service und ConfigMap setzt der Rollback nicht zurueck.
#
# Jeder Lauf schreibt eine Zeile nach out/pipeline/verlauf.txt.
# Exit-Code: 0 gruen, 1 rot (zurueckgerollt), 2 vor dem Deploy gestoppt.
set -u

MANIFEST="${1:-}"
BUILD=nein
[ "${2:-}" = "--build" ] && BUILD=ja
TIMEOUT="${PIPELINE_TIMEOUT:-120}"

stufe() { printf '\n[%s] %s\n' "$1" "$2"; }
ok() { printf '  OK\n'; }
# Eine Zeile pro Lauf: Zeit, Ergebnis, Manifest, Namespace.
verlauf() {
  mkdir -p out/pipeline 2>/dev/null || return 0
  printf '%s %-9s %s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "${MANIFEST:-?}" "${WORKSHOP_NAMESPACE:-?}" >> out/pipeline/verlauf.txt
}
stopp() { printf '  FEHLER: %s\n\nPipeline GESTOPPT: nichts ausgerollt.\n' "$1"; verlauf GESTOPPT; exit 2; }
# kubectl immer mit festem Ziel, nie still der aktuelle Kontext.
k() { kubectl --context "$WORKSHOP_CONTEXT" --namespace "$WORKSHOP_NAMESPACE" "$@"; }
# Befehl wie im CI-Log zeigen und ausfuehren.
zeige() {
  local text="$*"
  printf '  $ %s\n' "${text/#k /kubectl }"
  "$@" 2>&1 | sed 's/^/    /'
  return "${PIPESTATUS[0]}"
}

# ---------------------------------------------------------------- [1/5]
stufe 1/5 "Pruefen"
[ -f scripts/pipeline.sh ] || stopp "Aus dem Repository-Hauptordner starten."
[ -n "$MANIFEST" ] || stopp "Aufruf: bash scripts/pipeline.sh MANIFEST [--build]"
case "${2:-}" in ""|--build) ;; *) stopp "Unbekannte Option: $2" ;; esac
[ -n "${WORKSHOP_CONTEXT:-}" ] || stopp "WORKSHOP_CONTEXT ist nicht gesetzt."
[ -n "${WORKSHOP_NAMESPACE:-}" ] || stopp "WORKSHOP_NAMESPACE ist nicht gesetzt."
[ -e "$MANIFEST" ] || stopp "Manifest $MANIFEST fehlt. Erst render.py ausfuehren."
if grep -rqE 'TODO_IMAGE|WORKSHOP_IMAGE|WORKSHOP_PERSON' "$MANIFEST"; then
  stopp "Das Manifest enthaelt noch einen Platzhalter (TODO_IMAGE, WORKSHOP_IMAGE oder WORKSHOP_PERSON). Mit basis.sh rendern."
fi
printf '  Ziel: Kontext %s, Namespace %s\n' "$WORKSHOP_CONTEXT" "$WORKSHOP_NAMESPACE"
k get deployments -o name >/dev/null 2>&1 \
  || stopp "Cluster oder Namespace nicht erreichbar. Kontext, Namespace und Anmeldung pruefen."
OBJEKTE="$(k apply --dry-run=server -f "$MANIFEST" -o name 2>&1)" || {
  printf '%s\n' "$OBJEKTE" | sed 's/^/    /'
  stopp "Der API-Server lehnt das Manifest ab (dry run)."
}
printf '%s\n' "$OBJEKTE" | sed 's/^/    /'
# Deployments aus dem Manifest: nur diese rollt die Pipeline bei Fehler zurueck.
GEAENDERT="$(printf '%s\n' "$OBJEKTE" | sed -n 's#^deployment.apps/##p')"
if ! printf '%s\n' "$OBJEKTE" | grep -qx 'deployment.apps/hallo'; then
  k get deployment hallo >/dev/null 2>&1 \
    || stopp "Kein Deployment hallo im Manifest und keins im Namespace. Erst den Starter ausrollen."
  printf '  Hinweis: kein Deployment hallo im Manifest. Das Gate prueft das laufende.\n'
fi
# Das Gate prueft hallo und, falls vorhanden, den Verkehrsgenerator aus Lab 5.
PRUEFEN="hallo"
if k get deployment verkehr >/dev/null 2>&1 || printf '%s\n' "$GEAENDERT" | grep -qx verkehr; then
  PRUEFEN="hallo verkehr"
fi
ok

# ---------------------------------------------------------------- [2/5]
stufe 2/5 "Build"
ZIEL="$MANIFEST"
if [ "$BUILD" = nein ]; then
  printf '  uebersprungen (ohne --build gilt das Image im Manifest)\n'
else
  [ -n "${IMAGE:-}" ] || stopp "IMAGE ist nicht gesetzt (wie in Lab 4)."
  COMMIT="$(git rev-parse --short HEAD)" || stopp "Kein Git-Commit gefunden."
  NEU="${IMAGE%:*}:2.0-$COMMIT"
  case "$WORKSHOP_CONTEXT" in
    gke_*)
      # GKE-Nodes sind amd64. Danach in die Registry hochladen.
      zeige docker build --platform linux/amd64 --build-arg "APP_VERSION=2.0-$COMMIT" \
        -t "$NEU" lab02-hallo-app || stopp "docker build fehlgeschlagen."
      zeige docker push "$NEU" || stopp "docker push fehlgeschlagen." ;;
    *)
      # Lokal: Architektur des Rechners, keine Registry, Image direkt in minikube laden.
      zeige docker build --build-arg "APP_VERSION=2.0-$COMMIT" \
        -t "$NEU" lab02-hallo-app || stopp "docker build fehlgeschlagen."
      zeige minikube -p "$WORKSHOP_CONTEXT" image load "$NEU" || stopp "minikube image load fehlgeschlagen." ;;
  esac
  # Kopie mit neuem Image schreiben, die Eingabedatei bleibt unveraendert.
  ZIEL="out/pipeline/build-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$ZIEL"
  if [ -d "$MANIFEST" ]; then DATEIEN=("$MANIFEST"/*.yaml); else DATEIEN=("$MANIFEST"); fi
  for datei in "${DATEIEN[@]}"; do
    sed -E "s#^([[:space:]]*image:[[:space:]]*).*#\\1$NEU#" "$datei" > "$ZIEL/$(basename "$datei")"
  done
  printf '  Image %s, Manifest-Kopie in %s/\n' "$NEU" "$ZIEL"
fi
ok

# ---------------------------------------------------------------- [3/5]
stufe 3/5 "Deploy"
zeige k apply -f "$ZIEL" || { printf '  FEHLER\n'; verlauf ROT; exit 1; }
ok

# ---------------------------------------------------------------- [4/5]
stufe 4/5 "Gate (hoechstens ${TIMEOUT}s)"
GATE=gruen
for d in $PRUEFEN; do
  zeige k rollout status "deployment/$d" --timeout="${TIMEOUT}s" || { GATE=rot; break; }
done
if [ "$GATE" = gruen ]; then
  ok
  stufe 5/5 "Rollback"
  printf '  uebersprungen\n'
  LAEUFT="$(k get deployment hallo -o jsonpath='{.spec.template.spec.containers[0].image}')"
  printf '\nPipeline GRUEN: %s laeuft in %s\n' "$LAEUFT" "$WORKSHOP_NAMESPACE"
  verlauf GRUEN
  exit 0
fi
printf '  FEHLER: Rollout nicht rechtzeitig fertig.\n'

# ---------------------------------------------------------------- [5/5]
stufe 5/5 "Rollback"
BELEGE="out/pipeline/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BELEGE"
printf '  Belege sichern nach %s/\n' "$BELEGE"
k get pods -o wide > "$BELEGE/pods.txt" 2>&1
k describe pod -l app=hallo --show-events=true > "$BELEGE/describe.txt" 2>&1
k get events --sort-by=.metadata.creationTimestamp > "$BELEGE/events.txt" 2>&1
NEUESTER="$(k get pods -l app=hallo --sort-by=.metadata.creationTimestamp \
  -o jsonpath='{.items[-1:].metadata.name}' 2>/dev/null)"
NEUSTARTS="$(k get pod "$NEUESTER" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null)"
{
  printf '=== kubectl logs %s\n' "$NEUESTER"
  k logs "$NEUESTER" --tail=100 2>&1
  if [ "${NEUSTARTS:-0}" -gt 0 ] 2>/dev/null; then
    printf '\n=== kubectl logs %s --previous (Neustarts: %s)\n' "$NEUESTER" "$NEUSTARTS"
    k logs "$NEUESTER" --previous --tail=100 2>&1
  fi
  if printf '%s\n' "$PRUEFEN" | grep -q verkehr; then
    printf '\n=== kubectl logs deployment/verkehr (Sicht der Nutzer)\n'
    k logs deployment/verkehr --tail=30 2>&1
  fi
} > "$BELEGE/logs.txt"
printf '    %s\n' pods.txt describe.txt events.txt logs.txt
ZURUECK=""
for d in $PRUEFEN; do
  printf '%s\n' "$GEAENDERT" | grep -qx "$d" && ZURUECK="$ZURUECK $d"
done
ROLLBACK=ok
if [ -z "$ZURUECK" ]; then
  printf '  Kein Deployment im Manifest: rollout undo hat nichts zurueckzusetzen.\n'
  printf '  Service und ConfigMap setzt ihr mit dem letzten guten Stand zurueck.\n'
  ROLLBACK=nichts
fi
for d in $ZURUECK; do
  zeige k rollout undo "deployment/$d" \
    && zeige k rollout status "deployment/$d" --timeout=300s || ROLLBACK=fehler
done
verlauf ROT
case "$ROLLBACK" in
  ok) printf '\nPipeline ROT: Release zurueckgerollt. Belege: %s/\n' "$BELEGE" ;;
  nichts) printf '\nPipeline ROT: nichts zurueckgerollt. Belege: %s/\n' "$BELEGE" ;;
  *) printf '\nPipeline ROT: Rollback fehlgeschlagen, bitte von Hand pruefen. Belege: %s/\n' "$BELEGE" ;;
esac
exit 1
