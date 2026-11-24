#!/usr/bin/env bash
# Demo 2.1d: Service ohne Endpunkte
# Folie: Tag 2, Check-in 2.1, Aufloesung 1/3 "Service ohne Endpunkte"
# Zeigt: Pods gesund, Service findet sie nicht, weil der Selektor nicht passt.
# Baut den Fehler ein und repariert ihn am Ende wieder.
# Voraussetzung: hallo laeuft. Dauer: etwa 3 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 2.1d "Service ohne Endpunkte" "Check-in 2.1, Aufloesung 1/3"
braucht_hallo
aufraeumen_mit "kubectl patch service hallo -p '{\"spec\":{\"selector\":{\"app\":\"hallo\"}}}'"

sage "Ausgangslage: Der Selektor passt, die EndpointSlice nennt die Pod-IPs."
lauf "kubectl describe service hallo | grep Selector"
lauf "kubectl get endpointslices -l kubernetes.io/service-name=hallo"

sage "Fehler einbauen: Selektor app=hallo-app, wie in der Challenge aus 1.4."
lauf "kubectl patch service hallo -p '{\"spec\":{\"selector\":{\"app\":\"hallo-app\"}}}'"
[ "$MODUS" = trocken ] || sleep 2

sage "Die Pods sind weiter gesund ..."
lauf "kubectl get pods -l app=hallo"
sage "... aber mit dem neuen Selektor findet man keine Pods, und die EndpointSlice ist leer."
lauf "kubectl get pods -l app=hallo-app"
lauf "kubectl get endpointslices -l kubernetes.io/service-name=hallo"
sage "Neu starten oder skalieren aendert daran nichts. Repariert wird der Selektor:"
aufraeumen
[ "$MODUS" = trocken ] || sleep 2
lauf "kubectl get endpointslices -l kubernetes.io/service-name=hallo"
fertig
