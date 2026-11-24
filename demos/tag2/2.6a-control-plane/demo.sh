#!/usr/bin/env bash
# Demo 2.6a: Wer verantwortet was auf GKE?
# Folie: Tag 2, Check-in 2.6, Aufloesung 1/2 "Wer verantwortet was auf GKE?"
# Zeigt: lokal seht ihr die Control Plane als Pods. Auf GKE fehlt sie, Google betreibt sie.
# Voraussetzung: Cluster laeuft. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.6a "Wer verantwortet was auf GKE?" "Check-in 2.6, Aufloesung 1/2"

say "minikube: ein Node mit der Rolle control-plane."
run "kubectl get nodes"
say "API-Server, etcd, Scheduler und Controller Manager laufen hier als Pods:"
run "kubectl get pods -n kube-system"
say "Auf GKE zeigen dieselben Befehle keine Control Plane. Nach dem Kontextwechsel in 2.7 vergleichen."
finish
