#!/usr/bin/env bash
# Demo 2.1c: Image, Pod, Deployment, Service
# Folie: Tag 2, 2.1 "Eure Fragen: Image, Pod, Deployment, Service" (Terminal-Streifen)
# Zeigt: die ganze Kette und wie Labels sie verbinden.
# Voraussetzung: hallo laeuft. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.1c "Image, Pod, Deployment, Service" "2.1, Eure Fragen: Image, Pod, Deployment, Service"
require_hallo

say "Deployment, ReplicaSet, Pods und Service auf einen Blick."
run "kubectl get all"
say "Die Labels der Pods. Der Pod-Name ist egal, das Label zaehlt."
run "kubectl get pods --show-labels"
say "Der Service sucht nur nach diesem Selektor:"
run "kubectl describe service hallo | grep Selector"
say "Welches Image laeuft in den Pods?"
run "kubectl get pods -l app=hallo -o jsonpath='{..image}'; echo"
finish
