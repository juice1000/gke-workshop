# Demo 2.6c (Extra): Nach dem Upgrade

**Folie:** Tag 2, Anhang, Extra-Auflösung „Nach dem Upgrade“  
**Dauer:** etwa 1 Minute  
**Ändert den Cluster:** nein  
**Voraussetzung:** Cluster läuft

```bash
bash demos/tag2/2.6c-api-versionen/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.6c-api-versionen/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.6c-api-versionen/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Jeder Objekttyp hat eine API-Version. Entfernt ein Upgrade eine alte Version, scheitert ein Manifest damit beim `apply`.

## Schritte und was ihr zeigt

1. `kubectl version`  
   Zeigen: `Client Version` und `Server Version`. Sie sollen höchstens eine Minor-Version auseinanderliegen.

2. `kubectl api-resources | grep -i deployment`  
   Zeigen: `deployments  deploy  apps/v1`: Gruppe und Version, die der Cluster anbietet.

3. `grep apiVersion lab02-hallo-app/betrieb/deployment.yaml`  
   Zeigen: `apiVersion: apps/v1`. Passt.

## Häufige Fragen

- **Was passiert mit laufenden Objekten beim Upgrade?** Sie laufen weiter. Kubernetes speichert sie in der aktuellen Version. Nur Manifeste mit der alten Version scheitern beim nächsten `apply`.
- **Wie finde ich veraltete Versionen vorher?** Release Notes lesen. Auf GKE warnt die Konsole vor veralteten APIs. `validate.sh` prüft die Manifeste gegen die Schemas.
- **Warum zeigt `kubectl version` auch Kustomize?** Kustomize ist in kubectl eingebaut. Im Kurs nutzen wir es nicht.

## Aufräumen

Nicht nötig, die Demo ändert nichts.

Alle Demos: [Übersicht](../../README.md)
