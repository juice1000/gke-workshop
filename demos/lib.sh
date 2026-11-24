#!/usr/bin/env bash
# Gemeinsame Hilfsfunktionen fuer alle Demonstrationen.
# Wird von jedem Demo-Skript mit "source" geladen, nie direkt ausgefuehrt.
#
# Aufruf eines Demo-Skripts aus dem Hauptordner:
#   bash demos/tag2/2.1d-service-ohne-endpunkte.sh            # Schritt fuer Schritt
#   bash demos/tag2/2.1d-service-ohne-endpunkte.sh --auto     # ohne Pausen
#   bash demos/tag2/2.1d-service-ohne-endpunkte.sh --trocken  # nur Befehle zeigen
#
# Sicherheit: Alle kubectl-Befehle laufen mit festem Kontext und Namespace
# (Standard minikube und workshop). Ein GKE-Kontext wird abgelehnt.

DEMO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$DEMO_ROOT" || exit 1

MODUS=interaktiv
for demo_arg in "$@"; do
  case "$demo_arg" in
    --auto) MODUS=auto ;;
    --trocken) MODUS=trocken ;;
    -h|--help)
      sed -n '2,10p' "$DEMO_ROOT/demos/lib.sh"
      exit 0
      ;;
  esac
done

KONTEXT="${DEMO_KONTEXT:-minikube}"
NS="${DEMO_NAMESPACE:-workshop}"
PROFIL="${DEMO_PROFIL:-minikube}"

# Werkzeuge, kubeconfig und minikube-Daten des Workshops laden.
# Fehlt der Kontext in der Workshop-kubeconfig (minikube wurde ohne
# workshop-env.sh gestartet, also unter ~/.kube und ~/.minikube), gelten
# wieder kubeconfig und minikube-Daten von vorher. Die Werkzeuge bleiben.
demo_kc_vorher="${KUBECONFIG-}"
demo_mh_vorher="${MINIKUBE_HOME-}"
# shellcheck disable=SC1091
. scripts/workshop-env.sh >/dev/null || exit 1
if ! command kubectl config get-contexts "$KONTEXT" >/dev/null 2>&1; then
  if [ -n "$demo_kc_vorher" ]; then export KUBECONFIG="$demo_kc_vorher"; else unset KUBECONFIG; fi
  if [ -n "$demo_mh_vorher" ]; then export MINIKUBE_HOME="$demo_mh_vorher"; else unset MINIKUBE_HOME; fi
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
    *) command kubectl --context "$KONTEXT" --namespace "$NS" "$@" ;;
  esac
}
minikube() {
  command minikube -p "$PROFIL" "$@"
}

fehler() {
  printf '\nFEHLER: %s\n' "$*" >&2
  exit 1
}

pruefe_ziel() {
  [ "$MODUS" = trocken ] && return 0
  case "$KONTEXT" in
    gke_*) fehler "Die Demonstrationen laufen nur lokal. Kontext $KONTEXT ist GKE." ;;
  esac
  command kubectl config get-contexts "$KONTEXT" >/dev/null 2>&1 \
    || fehler "Kontext $KONTEXT fehlt. Zuerst Lab 0 ausfuehren (minikube start)."
  command kubectl --context "$KONTEXT" get namespace "$NS" >/dev/null 2>&1 \
    || fehler "Namespace $NS fehlt oder der Cluster laeuft nicht. minikube status pruefen."
}

# Voraussetzung: hallo laeuft (Stand nach Lab 2).
braucht_hallo() {
  [ "$MODUS" = trocken ] && return 0
  command kubectl --context "$KONTEXT" -n "$NS" get deployment hallo >/dev/null 2>&1 \
    || fehler "Deployment hallo fehlt. Erst: bash demos/tag2/00-vorbereiten.sh"
}

# Voraussetzung: Stand nach der Challenge in 2.2 (betrieb/ mit ConfigMap und Probes).
braucht_betrieb() {
  braucht_hallo
  [ "$MODUS" = trocken ] && return 0
  if ! command kubectl --context "$KONTEXT" -n "$NS" get configmap hallo-config >/dev/null 2>&1; then
    fehler "ConfigMap hallo-config fehlt. Erst: bash demos/tag2/00-vorbereiten.sh"
  fi
  if ! command kubectl --context "$KONTEXT" -n "$NS" get deployment hallo \
       -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}' | grep -q path; then
    fehler "hallo laeuft noch ohne betrieb/. Erst: bash demos/tag2/00-vorbereiten.sh"
  fi
}

titel() {
  # $1 Kennung, $2 Titel, $3 Folie
  pruefe_ziel
  printf '\n==================================================================\n'
  printf ' Demo %s: %s\n' "$1" "$2"
  printf ' Folie: %s\n' "$3"
  printf ' Ziel: Kontext %s, Namespace %s\n' "$KONTEXT" "$NS"
  printf '==================================================================\n'
}

# Kurzer erklaerender Text vor einem Schritt.
sage() {
  printf '\n> %s\n' "$*"
}

# Einen Befehl zeigen, auf Enter warten, ausfuehren.
lauf() {
  printf '\n$ %s\n' "$1"
  [ "$MODUS" = trocken ] && return 0
  if [ "$MODUS" = interaktiv ]; then
    printf '  [Enter] ausfuehren, [s] ueberspringen: '
    read -r demo_antwort
    [ "$demo_antwort" = s ] && return 0
  fi
  eval "$1"
}

# Einen Befehl mehrmals ausfuehren, damit Statuswechsel sichtbar werden.
beobachte() {
  # $1 Sekunden, $2 Befehl
  printf '\n$ %s   (alle 5 s, %s s lang, Strg+C bricht ab)\n' "$2" "$1"
  [ "$MODUS" = trocken ] && return 0
  if [ "$MODUS" = interaktiv ]; then
    printf '  [Enter] starten: '
    read -r demo_antwort
  fi
  demo_ende=$(( $(date +%s) + $1 ))
  while [ "$(date +%s)" -lt "$demo_ende" ]; do
    printf -- '--- %s\n' "$(date +%H:%M:%S)"
    eval "$2"
    sleep 5
  done
}

# Name des ersten Pods zu einem Label, fuer Befehle mit Pod-Namen.
pod_von() {
  if [ "$MODUS" = trocken ]; then printf 'POD'; return 0; fi
  command kubectl --context "$KONTEXT" -n "$NS" get pods -l "app=$1" \
    --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}'
}

# Aufraeumen auch bei Strg+C: Befehl merken, bei Abbruch still ausfuehren.
DEMO_AUFRAEUMEN=""
aufraeumen_mit() {
  DEMO_AUFRAEUMEN="$1"
  trap 'demo_abbruch' INT
}
demo_abbruch() {
  printf '\n\nAbbruch. Raeume auf: %s\n' "$DEMO_AUFRAEUMEN"
  [ "$MODUS" = trocken ] || eval "$DEMO_AUFRAEUMEN" >/dev/null 2>&1
  exit 130
}
aufraeumen() {
  [ -z "$DEMO_AUFRAEUMEN" ] && return 0
  sage "Aufraeumen: Ausgangszustand wiederherstellen."
  lauf "$DEMO_AUFRAEUMEN"
  DEMO_AUFRAEUMEN=""
  trap - INT
}

fertig() {
  aufraeumen
  printf '\nDemo beendet.\n'
}
