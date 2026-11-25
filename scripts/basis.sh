#!/usr/bin/env bash
# Bekannten guten Stand im eigenen Namespace herstellen. Das Sicherheitsnetz:
# Wer laenger als 10 Minuten feststeckt, setzt zurueck und macht weiter.
#
# Aufruf aus dem Repository-Hauptordner:
#   bash scripts/basis.sh lab05            Ausgangslage fuer Lab 5 (Stoerungssuche)
#   bash scripts/basis.sh lab06            Ausgangslage fuer Lab 6 (Abschluss)
#   bash scripts/basis.sh lab06 TEIL       Einstieg in einen Teil (Ordner basis/TEIL/)
#   bash scripts/basis.sh lab06 --pruefen  nur pruefen, nichts aendern
#
# Umgebung wie in Lab 4: WORKSHOP_CONTEXT, WORKSHOP_NAMESPACE, IMAGE.
# Ablauf: rendern, Altlasten des Labs entfernen, Secret sicherstellen,
# scripts/pipeline.sh mit dem guten Stand, dann Pruefungen.
# Exit-Code: 0 gesund, 1 nicht gesund, 2 falsche Eingabe.
set -u

LAB="${1:-}"
TEIL=""
NUR_PRUEFEN=nein
for arg in "${@:2}"; do
  case "$arg" in
    --pruefen) NUR_PRUEFEN=ja ;;
    -*) printf 'FEHLER: Unbekannte Option %s\n' "$arg" >&2; exit 2 ;;
    *) TEIL="$arg" ;;
  esac
done

fail() { printf 'FEHLER: %s\n' "$*" >&2; exit 2; }
k() { kubectl --context "$WORKSHOP_CONTEXT" --namespace "$WORKSHOP_NAMESPACE" "$@"; }

[ -f scripts/basis.sh ] || fail "Aus dem Repository-Hauptordner starten."
case "$LAB" in
  lab05|5) NN=05; QUELLE=lab05-stoerungen/basis; AUSGABE=out/lab05; BASIS=out/lab05 ;;
  lab06|6) NN=06; QUELLE=lab06-abschluss; AUSGABE=out/lab06; BASIS=out/lab06/basis ;;
  *) sed -n '5,9p' "$0" >&2; exit 2 ;;
esac
[ -n "$TEIL" ] && BASIS="$BASIS/$TEIL"
[ -n "${WORKSHOP_CONTEXT:-}" ] || fail "WORKSHOP_CONTEXT ist nicht gesetzt (Lab 4, Schritt 1)."
[ -n "${WORKSHOP_NAMESPACE:-}" ] || fail "WORKSHOP_NAMESPACE ist nicht gesetzt (Lab 4, Schritt 1)."
# Nur Kurs-Namespaces: lokal "workshop", auf GKE "workshop-...".
case "$WORKSHOP_NAMESPACE" in
  workshop|workshop-*) ;;
  *) fail "Namespace $WORKSHOP_NAMESPACE ist kein Kurs-Namespace. Erlaubt: workshop oder workshop-..." ;;
esac
printf 'Ziel: Kontext %s, Namespace %s, Lab %s\n' "$WORKSHOP_CONTEXT" "$WORKSHOP_NAMESPACE" "$NN"

# ------------------------------------------------------------------ Pruefungen
pruefen() {
  local fehlt=0 a soll bereit neustarts slices code zeilen gruesse
  pruefe() { if [ "$1" = ja ]; then printf '  OK: %s\n' "$2"; else printf '  FEHLT: %s\n' "$2"; fehlt=$((fehlt + 1)); fi; }
  printf '\nPruefungen\n'
  soll="$(k get deployment hallo -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  bereit="$(k get deployment hallo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
  [ -n "$soll" ] && [ "${bereit:-0}" = "$soll" ] && a=ja || a=nein
  pruefe "$a" "deployment/hallo: ${bereit:-0} von ${soll:-?} Pods bereit"
  neustarts="$(k get pods -l app=hallo -o jsonpath='{.items[*].status.containerStatuses[0].restartCount}' 2>/dev/null)"
  [ -n "$neustarts" ] && ! printf '%s\n' "$neustarts" | tr ' ' '\n' | grep -qv '^0$' && a=ja || a=nein
  pruefe "$a" "keine Neustarts bei hallo (${neustarts:-keine Pods})"
  slices="$(k get endpointslices -l kubernetes.io/service-name=hallo -o jsonpath='{.items[*].endpoints[*].addresses[0]}' 2>/dev/null)"
  [ -n "$slices" ] && a=ja || a=nein
  pruefe "$a" "Service hallo hat Endpunkte"
  k get secret hallo-secret >/dev/null 2>&1 && a=ja || a=nein
  pruefe "$a" "Secret hallo-secret vorhanden"
  code="$(k exec deployment/hallo -- curl -s -o /dev/null -m 5 -w '%{http_code}' http://hallo/ 2>/dev/null)"
  [ "$code" = 200 ] && a=ja || a=nein
  pruefe "$a" "HTTP 200 von http://hallo/ im Namespace (Antwort: ${code:-keine})"
  if k get deployment verkehr >/dev/null 2>&1; then
    zeilen="$(k logs deployment/verkehr --tail=6 2>/dev/null)"
    [ -n "$zeilen" ] && ! printf '%s\n' "$zeilen" | grep -qv -- '-> 200 ' && a=ja || a=nein
    pruefe "$a" "verkehr: die letzten 6 Anfragen mit HTTP 200"
    gruesse="$(printf '%s\n' "$zeilen" | sed -n 's/.*-> 200 \(.*\) von Pod .*/\1/p' | sort -u | wc -l | tr -d ' ')"
    [ "$gruesse" = 1 ] && a=ja || a=nein
    pruefe "$a" "verkehr: alle Antworten mit derselben Begruessung"
  fi
  return "$fehlt"
}

if [ "$NUR_PRUEFEN" = ja ]; then
  pruefen; n=$?
  printf '\nErgebnis: %s Pruefung(en) fehlgeschlagen\n' "$n"
  [ "$n" = 0 ] && exit 0 || exit 1
fi

[ -n "${IMAGE:-}" ] || fail "IMAGE ist nicht gesetzt (Lab 4, Schritt 2)."

# ------------------------------------------------------------------ 1. Rendern
# Nie die Quelle aendern. Eigene Arbeitskopien in out/ bleiben als Sicherung.
if [ -d "$AUSGABE" ]; then
  if [ "$NN" = 05 ]; then
    rm -rf "$AUSGABE"
  else
    SICHERUNG="$AUSGABE-vorher-$(date +%Y%m%d-%H%M%S)"
    mv "$AUSGABE" "$SICHERUNG"
    printf 'Eure bisherige Arbeitskopie liegt jetzt in %s/\n' "$SICHERUNG"
  fi
fi
python3 scripts/render.py "$QUELLE" --image "$IMAGE" --output "$AUSGABE" >/dev/null || exit 2
# Name pro Person: Secret hallo-db-person01 (Etappe D), Pfad /workshop-person01 (HTTPRoute).
PERSON="${WORKSHOP_NAMESPACE#workshop-}"
grep -rl WORKSHOP_PERSON "$AUSGABE" 2>/dev/null | while IFS= read -r datei; do
  sed "s/WORKSHOP_PERSON/$PERSON/g" "$datei" > "$datei.neu" && mv "$datei.neu" "$datei"
done
[ -d "$BASIS" ] || fail "Teil $TEIL gibt es nicht: $BASIS fehlt."

# ------------------------------------------------------------------ 2. Altlasten
# Was das Lab angelegt hat (Label workshop-lab) und nicht zum guten Stand
# gehoert, wird geloescht. Alles andere wird nur gemeldet.
# Jede Art einzeln: Was die Rolle nicht lesen darf, faellt still heraus.
ARTEN=""
for art in deployments services configmaps serviceaccounts poddisruptionbudgets httproutes secretproviderclasses; do
  k get "$art" -o name >/dev/null 2>&1 && ARTEN="$ARTEN $art"
done
liste() { for art in $ARTEN; do k get "$art" -o name "$@" 2>/dev/null; done; }
SOLL="$(k apply --dry-run=client -f "$BASIS" -o name 2>/dev/null)"
soll_hat() {
  # $1: art/name, z. B. deployment.apps/hallo. Vergleich ohne API-Gruppe.
  printf '%s\n' "$SOLL" | sed 's#^\([a-z]*\)[^/]*/#\1/#' | grep -qx "$(printf '%s' "$1" | sed 's#^\([a-z]*\)[^/]*/#\1/#')"
}
# Geloescht wird erst nach gruener Pipeline: Ein Rollback braucht die alten Objekte.
ALTLASTEN=""
for obj in $(liste -l "workshop-lab=$NN"); do
  soll_hat "$obj" || ALTLASTEN="$ALTLASTEN $obj"
done
for obj in $(liste); do
  soll_hat "$obj" && continue
  case "$obj" in configmap/kube-root-ca.crt|serviceaccount/default) continue ;; esac
  lab="$(k get "$obj" -o jsonpath='{.metadata.labels.workshop-lab}' 2>/dev/null)"
  [ "$lab" = "$NN" ] && continue
  printf 'Fremdes Objekt im Namespace (bleibt stehen): %s\n' "$obj"
done

# ------------------------------------------------------------------ 3. Secret
if ! k get secret hallo-secret >/dev/null 2>&1; then
  k create secret generic hallo-secret --from-literal=DB_PASSWORT=uebung123 >/dev/null || exit 1
  printf 'Secret hallo-secret neu angelegt.\n'
fi

# ------------------------------------------------------------------ 4. Pipeline
bash scripts/pipeline.sh "$BASIS/" || { printf '\nAusgangslage %s steht NICHT: Pipeline nicht gruen.\n' "$NN"; exit 1; }
for obj in $ALTLASTEN; do
  printf 'Altlast aus Lab %s, wird geloescht: %s\n' "$NN" "$obj"
  k delete "$obj" --wait=false >/dev/null
done

# ------------------------------------------------------------------ 5. Pruefen
sleep 8   # verkehr braucht einige Anfragen nach dem Rollout
pruefen; n=$?
if [ "$n" != 0 ]; then
  # Haeufigster Rest: geaenderte ConfigMap oder alte Pods mit Neustarts.
  # Ein frischer Rollout liest die Konfiguration neu und startet ohne Neustarts.
  printf '\nNeue Pods holen sich die Konfiguration neu: rollout restart\n'
  k rollout restart deployment/hallo >/dev/null
  k rollout status deployment/hallo --timeout=300s >/dev/null
  sleep 8
  pruefen; n=$?
fi
printf '\nErgebnis: %s Pruefung(en) fehlgeschlagen\n' "$n"
if [ "$n" = 0 ]; then
  printf 'Ausgangslage %s steht.\n' "$NN"
  exit 0
fi
printf 'Ausgangslage %s steht NICHT. Ausgabe oben lesen oder den Trainer fragen.\n' "$NN"
exit 1
