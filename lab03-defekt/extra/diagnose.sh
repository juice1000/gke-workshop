#!/usr/bin/env bash
# Uebung: Diagnose-Skript fuer ein Deployment. Ihr ergaenzt die TODOs.
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
# TODO: Details und Events aller Pods mit dem Label app=$APP ausgeben.

abschnitt "3. Aktuelle Logs (letzte 20 Zeilen je Pod)"
# TODO: Logs aller Pods mit dem Label ausgeben, mit Pod-Namen vor jeder Zeile.
#       Tipp: kubectl logs --help

abschnitt "4. Logs des vorherigen Containers"
# TODO: Wie 3, aber vom Container vor dem letzten Neustart.
#       Ohne Neustart gibt es keine vorigen Logs. Das Skript soll dann weiterlaufen.

abschnitt "5. Warnungen im Namespace"
# TODO: Nur Events vom Typ Warning, nach Zeit sortiert.
#       Tipp: kubectl get events --help, Stichwort field-selector
