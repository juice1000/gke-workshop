#!/usr/bin/env bash
# Demo 3.4b: Welches Image laeuft wirklich?
# Folie: Tag 3, 3.4 Anbindung an den Build-Prozess
# Zeigt: image ist der Name aus dem Manifest, imageID der Digest, der
# tatsaechlich laeuft. imagePullPolicy entscheidet, ob neu geladen wird.
# Aendert nichts.
# Voraussetzung: 00-vorbereiten.sh aus tag2. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../lib.sh"
titel 3.4b "Welches Image laeuft wirklich?" "3.4 Anbindung an den Build-Prozess"
braucht_betrieb

sage "Name mit Tag, so wie er im Manifest steht:"
lauf "kubectl get deploy hallo -o jsonpath='{.spec.template.spec.containers[0].image}'; echo"
sage "Je Pod: Name aus dem Manifest und der Digest, den der Node gestartet hat."
lauf "kubectl get pods -l app=hallo --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.metadata.name}{\"\\n  image:   \"}{.status.containerStatuses[0].image}{\"\\n  imageID: \"}{.status.containerStatuses[0].imageID}{\"\\n\"}{end}'"
sage "Ein Tag kann spaeter auf ein anderes Image zeigen, ein Digest nicht."
sage "Wann laedt der Node neu?"
lauf "kubectl get deploy hallo -o jsonpath='{.spec.template.spec.containers[0].imagePullPolicy}'; echo"
sage "IfNotPresent: nur wenn das Image auf dem Node fehlt. Always: bei jedem Start."
sage "Ohne Angabe gilt Always fuer :latest und IfNotPresent fuer andere Tags."
sage "Darum baut die Pipeline jedes Release mit neuem Tag, oder deployt gleich mit @sha256:..."
fertig
