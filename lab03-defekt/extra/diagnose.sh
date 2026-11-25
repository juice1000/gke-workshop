#!/usr/bin/env bash
# Loesung: Diagnose-Skript fuer ein Deployment.
# Aufruf: bash lab03-defekt/extra/diagnose.sh fall1
# Kontext und Namespace sind ausdruecklich gesetzt, nie stillschweigend der aktuelle.
set -uo pipefail

APP="${1:?Aufruf: bash lab03-defekt/extra/diagnose.sh APP-LABEL, z. B. fall1}"
CONTEXT="${WORKSHOP_CONTEXT:-minikube}"
NAMESPACE="${WORKSHOP_NAMESPACE:-workshop}"
K=(kubectl --context "$CONTEXT" -n "$NAMESPACE")

abschnitt() {
  printf '\n===== %s\n' "$1"
}

abschnitt "Ziel: Kontext $CONTEXT, Namespace $NAMESPACE, Label app=$APP"

abschnitt "1. Status der Pods"
"${K[@]}" get pods -l "app=$APP" -o wide

abschnitt "2. Zustand und Events der Pods"
"${K[@]}" describe pod -l "app=$APP"

abschnitt "3. Aktuelle Logs (letzte 20 Zeilen je Pod)"
"${K[@]}" logs -l "app=$APP" --prefix --tail=20 \
  || printf 'Keine aktuellen Logs. Container noch nicht gestartet?\n'

abschnitt "4. Logs des vorherigen Containers"
"${K[@]}" logs -l "app=$APP" --prefix --tail=20 --previous \
  || printf 'Keine vorigen Logs. Es gab noch keinen Neustart.\n'

abschnitt "5. Warnungen im Namespace"
"${K[@]}" get events --field-selector type=Warning --sort-by=.metadata.creationTimestamp
