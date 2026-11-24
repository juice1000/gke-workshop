#!/usr/bin/env bash
# Demo 3.1a: Welcher Cluster, welcher Namespace?
# Folie: Tag 3, 3.1 Rueckblick, Zugaenge pruefen
# Zeigt: kubeconfig kennt mehrere Kontexte. Der aktuelle Kontext entscheidet,
# wohin ein kubectl ohne --context geht. Aendert nichts, wechselt keinen Kontext.
# Voraussetzung: Cluster laeuft. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 3.1a "Welcher Cluster, welcher Namespace?" "3.1 Rueckblick, Zugaenge pruefen"

sage "Alle Kontexte in der kubeconfig. Der Stern markiert den aktuellen."
lauf "kubectl config get-contexts"
sage "Nur der Name des aktuellen Kontexts. Auf GKE beginnt er mit gke_PROJEKT_ZONE_CLUSTER."
lauf "kubectl config current-context"
sage "Der Standard-Namespace dieses Kontexts. Leer heisst: default."
lauf "kubectl config view --minify -o jsonpath='{..namespace}'; echo"
sage "Sicher ist nur ein fester Kontext im Befehl. Diese Demos setzen ihn immer."
lauf "kubectl --context $KONTEXT get nodes"
sage "Wechseln ginge mit: kubectl config use-context NAME (hier nicht noetig)."
fertig
