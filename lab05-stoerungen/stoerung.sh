#!/usr/bin/env bash
# Lab 5: Stoerungen in den eigenen Namespace einbauen.
# Lest dieses Skript erst nach dem Lab. Es verraet die Ursachen.
#
# Aufruf aus dem Repository-Hauptordner:
#   bash lab05-stoerungen/stoerung.sh start      gesunde Ausgangslage (auch zum Zuruecksetzen)
#   bash lab05-stoerungen/stoerung.sh 1 ... 5    Stoerung 5.1 ... 5.5 einbauen
#   bash lab05-stoerungen/stoerung.sh zufall     eine zufaellige Stoerung, ohne Nummer
#
# Umgebung: IMAGE aus Lab 4. Ziel: aktueller kubectl-Kontext und dessen Namespace.
set -u

[ -f lab05-stoerungen/stoerung.sh ] || { echo "Aus dem Repository-Hauptordner starten." >&2; exit 2; }
printf 'Ziel: Kontext %s, Namespace %s\n' "$(kubectl config current-context)" \
  "$(kubectl config view --minify -o jsonpath='{..namespace}')"

neuester_pod() { kubectl get pods -l app=hallo --sort-by=.metadata.creationTimestamp -o name | tail -1; }

einbauen() {
  kubectl get deployment verkehr >/dev/null 2>&1 || { echo "Erst: bash lab05-stoerungen/stoerung.sh start" >&2; exit 1; }
  case "$1" in
    1) # Liveness fragt einen Pfad ab, den es nicht gibt: Neustart alle 30 bis 40 Sekunden.
      kubectl patch deployment hallo -p '{"spec":{"template":{"spec":{"containers":[{"name":"hallo","livenessProbe":{"httpGet":{"path":"/actuator/health/live"}}}]}}}}' ;;
    2) # Service leitet auf einen Port, auf dem niemand lauscht.
      kubectl patch service hallo --type=json -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":8081}]' ;;
    3) # Secret weg. Laufende Pods merken nichts, ein neuer Pod startet nicht.
      kubectl delete secret hallo-secret && kubectl delete "$(neuester_pod)" --wait=false ;;
    4) # Der Client ruft ueberwiegend die Fehlerroute auf.
      kubectl set env deployment/verkehr PFADE="/ /fehler /fehler" ;;
    5) # Konfiguration geaendert, nur ein Pod neu gestartet.
      kubectl patch configmap hallo-config -p '{"data":{"GREETING":"Hallo aus der Testumgebung"}}' \
        && kubectl delete "$(neuester_pod)" --wait=false ;;
    *) echo "Unbekannte Stoerung: $1 (1 bis 5)" >&2; exit 2 ;;
  esac >/dev/null
}

case "${1:-}" in
  start)
    [ -n "${IMAGE:-}" ] || { echo "IMAGE ist nicht gesetzt (Lab 4, Schritt 2)." >&2; exit 2; }
    # Deployments und Secret neu anlegen: so bleibt keine Aenderung einer Stoerung zurueck.
    kubectl delete deployment hallo verkehr --ignore-not-found --wait=true
    kubectl delete secret hallo-secret --ignore-not-found
    kubectl create secret generic hallo-secret --from-literal=DB_PASSWORT=uebung123
    sed "s#WORKSHOP_IMAGE#$IMAGE#" lab05-stoerungen/basis/*.yaml | kubectl apply -f - || exit 1
    kubectl rollout status deployment/hallo --timeout=300s || exit 1
    kubectl rollout status deployment/verkehr --timeout=300s || exit 1
    printf '\nAusgangslage steht. Verkehr mitlesen: kubectl logs deployment/verkehr -f\n'
    printf 'Browser: http://EXTERNAL-IP/ui.html, Adresse aus: kubectl get service hallo-extern\n'
    ;;
  1|2|3|4|5) einbauen "$1"; printf 'Stoerung 5.%s eingebaut. Beobachtet zuerst den Verkehr.\n' "$1" ;;
  zufall) einbauen $((RANDOM % 5 + 1)); printf 'Eine Stoerung ist eingebaut. Beobachtet zuerst den Verkehr.\n' ;;
  *) sed -n '5,8p' "$0"; exit 2 ;;
esac
