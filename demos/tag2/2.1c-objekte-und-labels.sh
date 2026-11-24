#!/usr/bin/env bash
# Demo 2.1c: Image, Pod, Deployment, Service
# Folie: Tag 2, 2.1 "Eure Fragen: Image, Pod, Deployment, Service" (Terminal-Streifen)
# Zeigt: die ganze Kette und wie Labels sie verbinden.
# Voraussetzung: hallo laeuft. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.1c "Image, Pod, Deployment, Service" "2.1, Eure Fragen: Image, Pod, Deployment, Service"
braucht_hallo

sage "Deployment, ReplicaSet, Pods und Service auf einen Blick."
lauf "kubectl get all"
sage "Die Labels der Pods. Der Pod-Name ist egal, das Label zaehlt."
lauf "kubectl get pods --show-labels"
sage "Der Service sucht nur nach diesem Selektor:"
lauf "kubectl describe service hallo | grep Selector"
sage "Welches Image laeuft in den Pods?"
lauf "kubectl get pods -l app=hallo -o jsonpath='{..image}'; echo"
fertig
