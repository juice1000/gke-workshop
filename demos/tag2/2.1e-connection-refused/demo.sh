#!/usr/bin/env bash
# Demo 2.1e: Connection refused am Morgen
# Folie: Tag 2, Check-in 2.1, Aufloesung 2/3 "Connection refused am Morgen"
# Zeigt: die Meldung, wenn kubectl keinen API-Server erreicht.
# Simuliert mit einer falschen Server-Adresse, der Cluster bleibt an.
# Voraussetzung: Cluster laeuft. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.1e "Connection refused am Morgen" "Check-in 2.1, Aufloesung 2/3"

say "Simulation: kubectl an einen Port schicken, an dem kein API-Server laeuft."
run "kubectl --server=https://127.0.0.1:1 get pods"
say "Die Meldung kommt, bevor kubectl ueberhaupt nach Pods fragt. Sie sagt nichts ueber die Pods."
say "So prueft ihr, ob der lokale Cluster laeuft und erreichbar ist:"
run "minikube status"
run "kubectl cluster-info"
say "Nach einem Neustart des Rechners hilft: minikube start (hier nicht noetig)."
finish
