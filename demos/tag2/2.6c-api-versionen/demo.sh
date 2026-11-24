#!/usr/bin/env bash
# Demo 2.6c (Extra): Nach dem Upgrade
# Folie: Tag 2, Anhang, Extra-Aufloesung "Nach dem Upgrade"
# Zeigt: welche Kubernetes-Version laeuft und welche API-Version ein Objekttyp hat.
# Voraussetzung: Cluster laeuft. Dauer: etwa 1 Minute.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.6c "Nach dem Upgrade (Extra)" "Anhang, Extra-Aufloesung Nach dem Upgrade"

run "kubectl version"
say "Deployments gehoeren zu apps/v1. Ein Manifest mit einer entfernten Version scheitert beim apply."
run "kubectl api-resources | grep -i deployment"
run "grep apiVersion lab02-hallo-app/betrieb/deployment.yaml"
finish
