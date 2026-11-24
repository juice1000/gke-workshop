#!/usr/bin/env bash
# Demo 2.1e: Connection refused am Morgen
# Folie: Tag 2, Check-in 2.1, Aufloesung 2/3 "Connection refused am Morgen"
# Zeigt: die Meldung, wenn kubectl keinen API-Server erreicht.
# Simuliert mit einer falschen Server-Adresse, der Cluster bleibt an.
# Voraussetzung: Cluster laeuft. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.1e "Connection refused am Morgen" "Check-in 2.1, Aufloesung 2/3"

sage "Simulation: kubectl an einen Port schicken, an dem kein API-Server laeuft."
lauf "kubectl --server=https://127.0.0.1:1 get pods"
sage "Die Meldung kommt, bevor kubectl ueberhaupt nach Pods fragt. Sie sagt nichts ueber die Pods."
sage "So prueft ihr, ob der lokale Cluster laeuft und erreichbar ist:"
lauf "minikube status"
lauf "kubectl cluster-info"
sage "Nach einem Neustart des Rechners hilft: minikube start (hier nicht noetig)."
fertig
