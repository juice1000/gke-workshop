#!/usr/bin/env bash
# Demo 2.1b: Cluster, Node, Namespace
# Folie: Tag 2, 2.1 "Eure Fragen: Cluster, Node, Namespace" (Terminal-Streifen)
# Zeigt: Nodes und Namespaces sind zwei unabhaengige Richtungen.
# Voraussetzung: Cluster laeuft. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.1b "Cluster, Node, Namespace" "2.1, Eure Fragen: Cluster, Node, Namespace"

say "Die Maschinen des Clusters. minikube hat standardmaessig einen Node."
run "kubectl get nodes"
say "Alle Pods aller Namespaces. NAMESPACE und NODE sind zwei verschiedene Spalten."
run "kubectl get pods -A -o wide"
say "Nodes und Namespaces selbst gehoeren zu keinem Namespace (NAMESPACED false)."
run "kubectl api-resources --namespaced=false | grep -E '^NAME|^nodes|^namespaces'"
finish
