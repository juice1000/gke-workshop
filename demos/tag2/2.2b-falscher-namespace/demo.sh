#!/usr/bin/env bash
# Demo 2.2b: CreateContainerConfigError
# Folie: Tag 2, Check-in 2.2, Aufloesung 2/2 "CreateContainerConfigError"
# Zeigt: Ein Pod sieht nur ConfigMaps aus seinem eigenen Namespace.
# Nutzt Lab 3, Fall 2 und einen Hilfs-Namespace demo-anders. Raeumt alles ab.
# Voraussetzung: Cluster laeuft, hallo-app:1.0 geladen. Dauer: etwa 4 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.2b "CreateContainerConfigError" "Check-in 2.2, Aufloesung 2/2"
cleanup_with "kubectl delete -f lab03-defekt/fall2.yaml --ignore-not-found; kubectl delete configmap fall2-config --ignore-not-found; kubectl delete namespace demo-anders --ignore-not-found --wait=false"

say "Ein Deployment, das die ConfigMap fall2-config braucht (Lab 3, Fall 2):"
run "kubectl apply -f lab03-defekt/fall2.yaml"
observe 15 "kubectl get pods -l app=fall2"
say "Wir legen die ConfigMap an, aber in einem anderen Namespace."
run "kubectl create namespace demo-anders"
run "kubectl create configmap fall2-config -n demo-anders --from-literal=GREETING=Hallo"
say "Mit -A ist sie da ..."
run "kubectl get configmap -A | grep -E 'NAMESPACE|fall2'"
say "... im eigenen Namespace nicht. Und nur dort sucht der Pod."
run "kubectl get configmap"
run "kubectl describe pod -l app=fall2 | tail -n 4"
say "In welchem Namespace arbeitet euer Terminal ohne -n?"
run "kubectl config view --minify | grep namespace"
say "Reparatur: ConfigMap im eigenen Namespace anlegen. Der Pod startet ohne weiteres Zutun."
run "kubectl create configmap fall2-config --from-literal=GREETING=Hallo"
observe 30 "kubectl get pods -l app=fall2"
finish
