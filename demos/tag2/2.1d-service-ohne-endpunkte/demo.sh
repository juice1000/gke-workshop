#!/usr/bin/env bash
# Demo 2.1d: Service ohne Endpunkte
# Folie: Tag 2, Check-in 2.1, Aufloesung 1/3 "Service ohne Endpunkte"
# Zeigt: Pods gesund, Service findet sie nicht, weil der Selektor nicht passt.
# Baut den Fehler ein und repariert ihn am Ende wieder.
# Voraussetzung: hallo laeuft. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.1d "Service ohne Endpunkte" "Check-in 2.1, Aufloesung 1/3"
require_hallo
cleanup_with "kubectl patch service hallo -p '{\"spec\":{\"selector\":{\"app\":\"hallo\"}}}'"

say "Ausgangslage: Der Selektor passt, die EndpointSlice nennt die Pod-IPs."
run "kubectl describe service hallo | grep Selector"
run "kubectl get endpointslices -l kubernetes.io/service-name=hallo"

say "Fehler einbauen: Selektor app=hallo-app, wie in der Challenge aus 1.4."
run "kubectl patch service hallo -p '{\"spec\":{\"selector\":{\"app\":\"hallo-app\"}}}'"
[ "$MODE" = dry ] || sleep 2

say "Die Pods sind weiter gesund ..."
run "kubectl get pods -l app=hallo"
say "... aber mit dem neuen Selektor findet man keine Pods, und die EndpointSlice ist leer."
run "kubectl get pods -l app=hallo-app"
run "kubectl get endpointslices -l kubernetes.io/service-name=hallo"
say "Neu starten oder skalieren aendert daran nichts. Repariert wird der Selektor:"
cleanup
[ "$MODE" = dry ] || sleep 2
run "kubectl get endpointslices -l kubernetes.io/service-name=hallo"
finish
