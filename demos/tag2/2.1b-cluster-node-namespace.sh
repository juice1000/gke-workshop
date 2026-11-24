#!/usr/bin/env bash
# Demo 2.1b: Cluster, Node, Namespace
# Folie: Tag 2, 2.1 "Eure Fragen: Cluster, Node, Namespace" (Terminal-Streifen)
# Zeigt: Nodes und Namespaces sind zwei unabhaengige Richtungen.
# Voraussetzung: Cluster laeuft. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.1b "Cluster, Node, Namespace" "2.1, Eure Fragen: Cluster, Node, Namespace"

sage "Die Maschinen des Clusters. minikube hat standardmaessig einen Node."
lauf "kubectl get nodes"
sage "Alle Pods aller Namespaces. NAMESPACE und NODE sind zwei verschiedene Spalten."
lauf "kubectl get pods -A -o wide"
sage "Nodes und Namespaces selbst gehoeren zu keinem Namespace (NAMESPACED false)."
lauf "kubectl api-resources --namespaced=false | grep -E '^NAME|^nodes|^namespaces'"
fertig
