# Demo 3.2a: Logs verschwinden mit dem Pod

**Folie:** Tag 3, 3.2 Logging und Monitoring  
**Dauer:** etwa 2 Minuten  
**Ändert den Cluster:** ja, löscht einen Pod von hallo, das Deployment ersetzt ihn  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../../tag2/00-vorbereiten/README.md)

```bash
bash demos/tag3/3.2a-logs-weg/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag3/3.2a-logs-weg/demo.sh --auto     # ohne Pausen
bash demos/tag3/3.2a-logs-weg/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> `kubectl logs` liest nur vom laufenden Pod. Ist der Pod weg, sind seine Logs für kubectl weg. Darum braucht es zentrales Logging.

## Schritte und was ihr zeigt

1. `kubectl logs POD --tail=5`  
   Zeigen: Die letzten Zeilen eines laufenden Pods.

2. `kubectl delete pod POD`  
   Zeigen: Pod löschen, das Deployment startet einen neuen.

3. `kubectl logs POD --tail=5`  
   Zeigen: Der Kernmoment: `NotFound`. Kubernetes kennt den Pod nicht mehr.

4. `kubectl rollout status deployment/hallo --timeout=180s`  
   Zeigen: Der Ersatz ist bereit.

5. `kubectl logs NEUER-POD --tail=5`  
   Zeigen: Der neue Pod beginnt mit eigenen, frischen Logs.

## Häufige Fragen

- **Hilft `--previous`?** Nur nach einem Container-Neustart im selben Pod, nicht nach einem neuen Pod.
- **Wo sind die Logs auf GKE?** Cloud Logging sammelt sie ein. Im Logs Explorer findet ihr sie auch nach dem Löschen, gefiltert nach Cluster, Namespace und Pod.
- **Wie lange bleiben sie dort?** Nach der Aufbewahrungsfrist des Log-Buckets, standardmäßig 30 Tage.

## Aufräumen

Automatisch: warten, bis das Deployment wieder zwei bereite Pods hat.

Alle Demos: [Übersicht](../../README.md)
