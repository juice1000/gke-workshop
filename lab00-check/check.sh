#!/usr/bin/env bash
# Nur lesen: Werkzeuge und optional den zugewiesenen Cloud-Zugang pruefen.
set -uo pipefail
fehlend=0
ok=0
check() {
  local text="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf 'OK: %s\n' "$text"
    ok=$((ok + 1))
  else
    printf 'FEHLT: %s\n' "$text"
    fehlend=$((fehlend + 1))
  fi
}

case "${1:-lokal}" in
  lokal)
    for tool in git docker minikube kubectl curl python3; do
      check "Werkzeug $tool installiert" command -v "$tool"
    done
    check 'Docker-Daemon erreichbar (sonst Docker starten)' docker info
    check 'Docker Buildx verfuegbar' docker buildx version
    check 'GitHub erreichbar (sonst Proxy/Netzwerk pruefen)' curl -fsSI --connect-timeout 5 --max-time 15 https://github.com
    check 'Maven Central erreichbar' curl -fsSI --connect-timeout 5 --max-time 15 https://repo.maven.apache.org/maven2/
    check 'Python 3.9 oder neuer' python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))'
    # Fuer Tag 2 noetig, am ersten Tag nur ein Hinweis.
    for tool in gcloud gke-gcloud-auth-plugin; do
      if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'HINWEIS: %s fehlt, wird ab Tag 2 gebraucht (siehe VORBEREITUNG.md)\n' "$tool"
      fi
    done
    # WSL: Repository unter /mnt/... ist langsam und macht Rechteprobleme.
    if grep -qi microsoft /proc/version 2>/dev/null; then
      case "$(pwd -P)" in
        /mnt/*) printf 'HINWEIS: Repository liegt unter /mnt. Besser im Linux-Home klonen (~/gke-workshop).\n' ;;
        *) printf 'INFO: WSL erkannt, Repository liegt im Linux-Dateisystem.\n' ;;
      esac
    fi
    printf 'INFO: Registry-Pulls werden beim Image-Build geprueft. Dieser Check startet keinen Cluster.\n'
    ;;
  cloud)
    for tool in gcloud gke-gcloud-auth-plugin kubectl; do
      check "Werkzeug $tool installiert" command -v "$tool"
    done
    if [ -z "${WORKSHOP_CONTEXT:-}" ] || [ -z "${WORKSHOP_NAMESPACE:-}" ]; then
      printf 'FEHLT: WORKSHOP_CONTEXT und WORKSHOP_NAMESPACE laut Lab 4 setzen.\n'
      fehlend=$((fehlend + 1))
    else
      printf 'INFO: Kontext %s, Namespace %s\n' "$WORKSHOP_CONTEXT" "$WORKSHOP_NAMESPACE"
      check 'Pods im eigenen Namespace lesbar' kubectl --context "$WORKSHOP_CONTEXT" -n "$WORKSHOP_NAMESPACE" --request-timeout=10s get pods
      check 'Deployments im eigenen Namespace erlaubt' kubectl --context "$WORKSHOP_CONTEXT" -n "$WORKSHOP_NAMESPACE" --request-timeout=10s auth can-i create deployments.apps --quiet
    fi
    ;;
  *) printf 'Aufruf: bash lab00-check/check.sh [lokal|cloud]\n' >&2; exit 2 ;;
esac
printf '\nErgebnis: %s OK, %s fehlend\n' "$ok" "$fehlend"
[ "$fehlend" -eq 0 ]
