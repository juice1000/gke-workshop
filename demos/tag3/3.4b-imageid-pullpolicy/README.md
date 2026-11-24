# Demo 3.4b: Welches Image läuft wirklich?

**Folie:** Tag 3, 3.4 Anbindung an den Build-Prozess  
**Dauer:** etwa 2 Minuten  
**Ändert den Cluster:** nein  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../../tag2/00-vorbereiten/README.md)

```bash
bash demos/tag3/3.4b-imageid-pullpolicy/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag3/3.4b-imageid-pullpolicy/demo.sh --auto     # ohne Pausen
bash demos/tag3/3.4b-imageid-pullpolicy/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> `image` ist der Name aus dem Manifest, `imageID` der Digest, der wirklich läuft. Ein Tag kann sich ändern, ein Digest nicht.

## Schritte und was ihr zeigt

1. `kubectl get deploy hallo -o jsonpath='{...image}'; echo`  
   Zeigen: `hallo-app:2.0`: Name mit Tag, wie im Manifest.

2. `kubectl get pods -l app=hallo --field-selector=status.phase=Running -o jsonpath=...`  
   Zeigen: Je Pod `image:` und `imageID: ...sha256:...`. Der Digest ist der Fingerabdruck des Images.

3. `kubectl get deploy hallo -o jsonpath='{...imagePullPolicy}'; echo`  
   Zeigen: `IfNotPresent`: Der Node lädt nur, wenn das Image fehlt.

## Häufige Fragen

- **Was passiert, wenn jemand `2.0` neu pusht?** Nodes mit `IfNotPresent` behalten das alte Image. Verschiedene Nodes können verschiedene Images unter demselben Tag haben.
- **Was gilt ohne `imagePullPolicy`?** `Always` für `:latest` oder ohne Tag, `IfNotPresent` für alle anderen Tags.
- **Was ist der sichere Weg?** Jedes Release mit neuem Tag bauen oder mit `@sha256:...` deployen. Dann ist eindeutig, was läuft.

## Wenn es hakt

- Ein Pod ohne `imageID`: Er startet gerade oder hängt. Das Skript zeigt nur Pods in Phase `Running`.

## Aufräumen

Nicht nötig, die Demo ändert nichts.

Alle Demos: [Übersicht](../../README.md)
