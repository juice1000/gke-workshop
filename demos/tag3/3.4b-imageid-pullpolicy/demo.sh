#!/usr/bin/env bash
# Demo 3.4b: Welches Image laeuft wirklich?
# Folie: Tag 3, 3.4 Anbindung an den Build-Prozess
# Zeigt: image ist der Name aus dem Manifest, imageID der Digest, der
# tatsaechlich laeuft. imagePullPolicy entscheidet, ob neu geladen wird.
# Aendert nichts.
# Voraussetzung: demos/tag2/00-vorbereiten/demo.sh. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 3.4b "Welches Image laeuft wirklich?" "3.4 Anbindung an den Build-Prozess"
require_betrieb

say "Name mit Tag, so wie er im Manifest steht:"
run "kubectl get deploy hallo -o jsonpath='{.spec.template.spec.containers[0].image}'; echo"
say "Je Pod: Name aus dem Manifest und der Digest, den der Node gestartet hat."
run "kubectl get pods -l app=hallo --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.metadata.name}{\"\\n  image:   \"}{.status.containerStatuses[0].image}{\"\\n  imageID: \"}{.status.containerStatuses[0].imageID}{\"\\n\"}{end}'"
say "Ein Tag kann spaeter auf ein anderes Image zeigen, ein Digest nicht."
say "Wann laedt der Node neu?"
run "kubectl get deploy hallo -o jsonpath='{.spec.template.spec.containers[0].imagePullPolicy}'; echo"
say "IfNotPresent: nur wenn das Image auf dem Node fehlt. Always: bei jedem Start."
say "Ohne Angabe gilt Always fuer :latest und IfNotPresent fuer andere Tags."
say "Darum baut die Pipeline jedes Release mit neuem Tag, oder deployt gleich mit @sha256:..."
finish
