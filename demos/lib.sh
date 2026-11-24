#!/usr/bin/env bash
# Gemeinsame Hilfsfunktionen fuer alle Demonstrationen.
# Wird von jedem Demo-Skript mit "source" geladen, nie direkt ausgefuehrt.
#
# Aufruf eines Demo-Skripts aus dem Hauptordner:
#   bash demos/tag2/2.1d-service-ohne-endpunkte/demo.sh            # Schritt fuer Schritt
#   bash demos/tag2/2.1d-service-ohne-endpunkte/demo.sh --auto     # ohne Pausen
#   bash demos/tag2/2.1d-service-ohne-endpunkte/demo.sh --trocken  # nur Befehle zeigen
#
# Sicherheit: Alle kubectl-Befehle laufen mit festem Kontext und Namespace
# (Standard minikube und workshop). Ein GKE-Kontext wird abgelehnt.

DEMO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$DEMO_ROOT" || exit 1

MODE=interactive
for demo_arg in "$@"; do
  case "$demo_arg" in
    --auto) MODE=auto ;;
    --trocken) MODE=dry ;;
    -h|--help)
      sed -n '2,10p' "$DEMO_ROOT/demos/lib.sh"
      exit 0
      ;;
  esac
done

CONTEXT="${DEMO_KONTEXT:-minikube}"
NS="${DEMO_NAMESPACE:-workshop}"
PROFILE="${DEMO_PROFIL:-minikube}"

# Werkzeuge, kubeconfig und minikube-Daten des Workshops laden.
# Fehlt der Kontext in der Workshop-kubeconfig (minikube wurde ohne
# workshop-env.sh gestartet, also unter ~/.kube und ~/.minikube), gelten
# wieder kubeconfig und minikube-Daten von vorher. Die Werkzeuge bleiben.
demo_kc_before="${KUBECONFIG-}"
demo_mh_before="${MINIKUBE_HOME-}"
# shellcheck disable=SC1091
. scripts/workshop-env.sh >/dev/null || exit 1
if ! command kubectl config get-contexts "$CONTEXT" >/dev/null 2>&1; then
  if [ -n "$demo_kc_before" ]; then export KUBECONFIG="$demo_kc_before"; else unset KUBECONFIG; fi
  if [ -n "$demo_mh_before" ]; then export MINIKUBE_HOME="$demo_mh_before"; else unset MINIKUBE_HOME; fi
fi
# Eigene kubeconfig statt der des Workshops, falls noetig.
if [ -n "${DEMO_KUBECONFIG:-}" ]; then
  export KUBECONFIG="$DEMO_KUBECONFIG"
fi

# kubectl und minikube in diesen Skripten immer mit festem Ziel.
# Angezeigt wird der kurze Befehl wie auf der Folie.
kubectl() {
  case "${1:-}" in
    config) command kubectl "$@" ;;
    *) command kubectl --context "$CONTEXT" --namespace "$NS" "$@" ;;
  esac
}
minikube() {
  command minikube -p "$PROFILE" "$@"
}

fail() {
  printf '\nFEHLER: %s\n' "$*" >&2
  exit 1
}

check_target() {
  [ "$MODE" = dry ] && return 0
  case "$CONTEXT" in
    gke_*) fail "Die Demonstrationen laufen nur lokal. Kontext $CONTEXT ist GKE." ;;
  esac
  command kubectl config get-contexts "$CONTEXT" >/dev/null 2>&1 \
    || fail "Kontext $CONTEXT fehlt. Zuerst Lab 0 ausfuehren (minikube start)."
  command kubectl --context "$CONTEXT" get namespace "$NS" >/dev/null 2>&1 \
    || fail "Namespace $NS fehlt oder der Cluster laeuft nicht. minikube status pruefen."
}

# Voraussetzung: hallo laeuft (Stand nach Lab 2).
require_hallo() {
  [ "$MODE" = dry ] && return 0
  command kubectl --context "$CONTEXT" -n "$NS" get deployment hallo >/dev/null 2>&1 \
    || fail "Deployment hallo fehlt. Erst: bash demos/tag2/00-vorbereiten/demo.sh"
}

# Voraussetzung: Stand nach der Challenge in 2.2 (betrieb/ mit ConfigMap und Probes).
require_betrieb() {
  require_hallo
  [ "$MODE" = dry ] && return 0
  if ! command kubectl --context "$CONTEXT" -n "$NS" get configmap hallo-config >/dev/null 2>&1; then
    fail "ConfigMap hallo-config fehlt. Erst: bash demos/tag2/00-vorbereiten/demo.sh"
  fi
  if ! command kubectl --context "$CONTEXT" -n "$NS" get deployment hallo \
       -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}' | grep -q path; then
    fail "hallo laeuft noch ohne betrieb/. Erst: bash demos/tag2/00-vorbereiten/demo.sh"
  fi
  if ! command kubectl --context "$CONTEXT" -n "$NS" get deployment hallo \
       -o jsonpath='{.spec.template.spec.containers[0].env[*].name}' | grep -qw GREETING; then
    fail "hallo laeuft ohne GREETING aus der ConfigMap. Erst die TODOs in lab02-hallo-app/betrieb/deployment.yaml ergaenzen (betrieb/README.md, Schritt 3), dann: bash demos/tag2/00-vorbereiten/demo.sh"
  fi
}

title() {
  # $1 Kennung, $2 Titel, $3 Folie
  check_target
  printf '\n==================================================================\n'
  printf ' Demo %s: %s\n' "$1" "$2"
  printf ' Folie: %s\n' "$3"
  printf ' Ziel: Kontext %s, Namespace %s\n' "$CONTEXT" "$NS"
  printf '==================================================================\n'
}

# Kurzer erklaerender Text vor einem Schritt.
say() {
  printf '\n> %s\n' "$*"
}

# Einen Befehl zeigen, auf Enter warten, ausfuehren.
run() {
  printf '\n$ %s\n' "$1"
  [ "$MODE" = dry ] && return 0
  if [ "$MODE" = interactive ]; then
    printf '  [Enter] ausfuehren, [s] ueberspringen: '
    read -r demo_answer
    [ "$demo_answer" = s ] && return 0
  fi
  eval "$1"
}

# Einen Befehl mehrmals ausfuehren, damit Statuswechsel sichtbar werden.
observe() {
  # $1 Sekunden, $2 Befehl
  printf '\n$ %s   (alle 5 s, %s s lang, Strg+C bricht ab)\n' "$2" "$1"
  [ "$MODE" = dry ] && return 0
  if [ "$MODE" = interactive ]; then
    printf '  [Enter] starten: '
    read -r demo_answer
  fi
  demo_end=$(( $(date +%s) + $1 ))
  while [ "$(date +%s)" -lt "$demo_end" ]; do
    printf -- '--- %s\n' "$(date +%H:%M:%S)"
    eval "$2"
    sleep 5
  done
}

# Name des ersten Pods zu einem Label, fuer Befehle mit Pod-Namen.
pod_of() {
  if [ "$MODE" = dry ]; then printf 'POD'; return 0; fi
  command kubectl --context "$CONTEXT" -n "$NS" get pods -l "app=$1" \
    --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}'
}

# Aufraeumen auch bei Strg+C: Befehl merken, bei Abbruch still ausfuehren.
DEMO_CLEANUP=""
cleanup_with() {
  DEMO_CLEANUP="$1"
  trap 'on_interrupt' INT
}
on_interrupt() {
  printf '\n\nAbbruch. Raeume auf: %s\n' "$DEMO_CLEANUP"
  [ "$MODE" = dry ] || eval "$DEMO_CLEANUP" >/dev/null 2>&1
  exit 130
}
cleanup() {
  [ -z "$DEMO_CLEANUP" ] && return 0
  say "Aufraeumen: Ausgangszustand wiederherstellen."
  run "$DEMO_CLEANUP"
  DEMO_CLEANUP=""
  trap - INT
}

finish() {
  cleanup
  printf '\nDemo beendet.\n'
}
