#!/usr/bin/env bash
# Lab 5: Stoerungen in den eigenen Namespace einbauen.
# Lest dieses Skript erst nach dem Lab. Es verraet die Ursachen.
#
# Aufruf aus dem Repository-Hauptordner:
#   bash lab05-stoerungen/stoerung.sh start      Ausgangslage herstellen (auch zum Zuruecksetzen)
#   bash lab05-stoerungen/stoerung.sh 1 ... 5    Stoerung 5.1 ... 5.5 einbauen
#   bash lab05-stoerungen/stoerung.sh zufall     eine zufaellige Stoerung, ohne Nummer
#   bash lab05-stoerungen/stoerung.sh pruefen    ist alles wieder gesund?
#   bash lab05-stoerungen/stoerung.sh aufloesen  welche Stoerung war eingebaut?
#
# Umgebung wie in Lab 4: WORKSHOP_CONTEXT, WORKSHOP_NAMESPACE, IMAGE.
set -u

AKTION="${1:-}"
AUSGABE=out/lab05
MERKER="$AUSGABE/.stoerung"

fail() { printf 'FEHLER: %s\n' "$*" >&2; exit 1; }
k() { kubectl --context "$WORKSHOP_CONTEXT" --namespace "$WORKSHOP_NAMESPACE" "$@"; }

[ -f lab05-stoerungen/stoerung.sh ] || fail "Aus dem Repository-Hauptordner starten."
[ -n "${WORKSHOP_CONTEXT:-}" ] || fail "WORKSHOP_CONTEXT ist nicht gesetzt (Lab 4, Schritt 1)."
[ -n "${WORKSHOP_NAMESPACE:-}" ] || fail "WORKSHOP_NAMESPACE ist nicht gesetzt (Lab 4, Schritt 1)."
printf 'Ziel: Kontext %s, Namespace %s\n' "$WORKSHOP_CONTEXT" "$WORKSHOP_NAMESPACE"

titel() {
  case "$1" in
    1) echo "Neustarts im Betrieb" ;;
    2) echo "Stiller Service" ;;
    3) echo "Fehlendes Secret" ;;
    4) echo "Fehlerflut" ;;
    5) echo "Gemischte Antworten" ;;
  esac
}

ausgangslage_da() {
  k get deployment verkehr >/dev/null 2>&1 || fail "Ausgangslage fehlt. Erst: bash lab05-stoerungen/stoerung.sh start"
}

neuester_hallo_pod() {
  k get pods -l app=hallo --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}'
}

einbauen() {
  case "$1" in
    1) # Liveness fragt einen Pfad ab, den es nicht gibt: Neustart alle 30 bis 40 Sekunden.
      k patch deployment hallo -p '{"spec":{"template":{"spec":{"containers":[{"name":"hallo","livenessProbe":{"httpGet":{"path":"/actuator/health/live"}}}]}}}}' >/dev/null ;;
    2) # Service leitet auf einen Port, auf dem niemand lauscht.
      k patch service hallo --type=json -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":8081}]' >/dev/null ;;
    3) # Secret weg. Laufende Pods merken nichts, ein neuer Pod startet nicht.
      k delete secret hallo-secret >/dev/null
      k delete pod "$(neuester_hallo_pod)" --wait=false >/dev/null ;;
    4) # Ein Client ruft ueberwiegend die Fehlerroute auf.
      k set env deployment/verkehr PFADE="/ /fehler /fehler" >/dev/null ;;
    5) # Konfiguration geaendert, nur ein Pod neu gestartet.
      k patch configmap hallo-config -p '{"data":{"GREETING":"Hallo aus der Testumgebung"}}' >/dev/null
      k delete pod "$(neuester_hallo_pod)" --wait=false >/dev/null ;;
    *) fail "Unbekannte Stoerung: $1 (1 bis 5)" ;;
  esac
  mkdir -p "$AUSGABE"
  printf '%s\n' "$1" > "$MERKER"
}

case "$AKTION" in
  start)
    [ -n "${IMAGE:-}" ] || fail "IMAGE ist nicht gesetzt (Lab 4, Schritt 2)."
    # Loeschen und neu anlegen statt apply: so bleibt keine Aenderung einer Stoerung zurueck.
    if [ -f "$AUSGABE/deployment.yaml" ]; then
      k delete -f "$AUSGABE/" --ignore-not-found --wait=true >/dev/null
    fi
    # Jedes Mal frisch rendern, damit immer das aktuelle IMAGE gilt.
    rm -rf "$AUSGABE"
    python3 scripts/render.py lab05-stoerungen/k8s --image "$IMAGE" --output "$AUSGABE" >/dev/null || exit 1
    k delete deployment hallo --ignore-not-found --wait=true >/dev/null
    k delete secret hallo-secret --ignore-not-found >/dev/null
    k create secret generic hallo-secret --from-literal=DB_PASSWORT=uebung123 >/dev/null || exit 1
    k apply -f "$AUSGABE/" || exit 1
    k rollout status deployment/hallo --timeout=300s || exit 1
    k rollout status deployment/verkehr --timeout=300s || exit 1
    rm -f "$MERKER"
    printf '\nAusgangslage steht. Verkehr mitlesen: kubectl logs deployment/verkehr -f\n'
    ;;
  1|2|3|4|5)
    ausgangslage_da
    einbauen "$AKTION"
    printf 'Stoerung 5.%s eingebaut: %s. Beobachtet zuerst die Logs.\n' "$AKTION" "$(titel "$AKTION")"
    ;;
  zufall)
    ausgangslage_da
    einbauen $(( RANDOM % 5 + 1 ))
    printf 'Eine Stoerung ist eingebaut. Welche, verraet: bash lab05-stoerungen/stoerung.sh aufloesen\n'
    ;;
  aufloesen)
    [ -f "$MERKER" ] || fail "Keine Stoerung eingebaut, oder start hat sie zurueckgesetzt."
    nummer="$(cat "$MERKER")"
    printf 'Eingebaut war Stoerung 5.%s: %s\n' "$nummer" "$(titel "$nummer")"
    ;;
  pruefen)
    fehlt=0
    pruefe() { if [ "$1" = ja ]; then printf 'OK: %s\n' "$2"; else printf 'FEHLT: %s\n' "$2"; fehlt=$((fehlt + 1)); fi; }
    bereit="$(k get deployment hallo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
    [ "${bereit:-0}" = 2 ] && a=ja || a=nein; pruefe "$a" "zwei bereite Pods von hallo"
    k get secret hallo-secret >/dev/null 2>&1 && a=ja || a=nein; pruefe "$a" "Secret hallo-secret vorhanden"
    zeilen="$(k logs deployment/verkehr --tail=6 2>/dev/null)"
    printf '%s\n' "$zeilen" | sed 's/^/  /'
    [ -n "$zeilen" ] && ! printf '%s\n' "$zeilen" | grep -qv -- '-> 200 ' && a=ja || a=nein
    pruefe "$a" "die letzten 6 Anfragen mit HTTP 200"
    gruesse="$(printf '%s\n' "$zeilen" | sed -n 's/.*-> 200 \(.*\) von Pod .*/\1/p' | sort -u | wc -l | tr -d ' ')"
    [ "$gruesse" = 1 ] && a=ja || a=nein; pruefe "$a" "alle Antworten mit derselben Begruessung"
    neustarts="$(k get pods -l app=hallo -o jsonpath='{.items[*].status.containerStatuses[0].restartCount}' 2>/dev/null)"
    [ -n "$neustarts" ] && ! printf '%s\n' "$neustarts" | tr ' ' '\n' | grep -qv '^0$' && a=ja || a=nein
    pruefe "$a" "keine Neustarts bei hallo (Neustarts: ${neustarts:-keine Pods})"
    printf '\nErgebnis: %s Pruefung(en) fehlgeschlagen\n' "$fehlt"
    [ "$fehlt" = 0 ]
    ;;
  *)
    sed -n '5,10p' "$0"
    exit 2
    ;;
esac
