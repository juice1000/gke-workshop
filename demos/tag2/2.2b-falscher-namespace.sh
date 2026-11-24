#!/usr/bin/env bash
# Demo 2.2b: CreateContainerConfigError
# Folie: Tag 2, Check-in 2.2, Aufloesung 2/2 "CreateContainerConfigError"
# Zeigt: Ein Pod sieht nur ConfigMaps aus seinem eigenen Namespace.
# Nutzt Lab 3, Fall 2 und einen Hilfs-Namespace demo-anders. Raeumt alles ab.
# Voraussetzung: Cluster laeuft, hallo-app:1.0 geladen. Dauer: etwa 4 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.2b "CreateContainerConfigError" "Check-in 2.2, Aufloesung 2/2"
aufraeumen_mit "kubectl delete -f lab03-defekt/fall2.yaml --ignore-not-found; kubectl delete configmap fall2-config --ignore-not-found; kubectl delete namespace demo-anders --ignore-not-found --wait=false"

sage "Ein Deployment, das die ConfigMap fall2-config braucht (Lab 3, Fall 2):"
lauf "kubectl apply -f lab03-defekt/fall2.yaml"
beobachte 15 "kubectl get pods -l app=fall2"
sage "Wir legen die ConfigMap an, aber in einem anderen Namespace."
lauf "kubectl create namespace demo-anders"
lauf "kubectl create configmap fall2-config -n demo-anders --from-literal=GREETING=Hallo"
sage "Mit -A ist sie da ..."
lauf "kubectl get configmap -A | grep -E 'NAMESPACE|fall2'"
sage "... im eigenen Namespace nicht. Und nur dort sucht der Pod."
lauf "kubectl get configmap"
lauf "kubectl describe pod -l app=fall2 | tail -n 4"
sage "In welchem Namespace arbeitet euer Terminal ohne -n?"
lauf "kubectl config view --minify | grep namespace"
sage "Reparatur: ConfigMap im eigenen Namespace anlegen. Der Pod startet ohne weiteres Zutun."
lauf "kubectl create configmap fall2-config --from-literal=GREETING=Hallo"
beobachte 30 "kubectl get pods -l app=fall2"
fertig
