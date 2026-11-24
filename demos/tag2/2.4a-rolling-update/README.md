# Demo 2.4a: Rolling Update

**Folie:** Tag 2, 2.4 „Rolling Update: Austausch im Betrieb“ (Terminal-Streifen)  
**Dauer:** etwa 3 Minuten  
**Ändert den Cluster:** ja, ersetzt die Pods durch neue (rollout restart)  
**Voraussetzung:** Deployment `hallo` läuft

```bash
bash demos/tag2/2.4a-rolling-update/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.4a-rolling-update/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.4a-rolling-update/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Pods werden einzeln getauscht: Erst ist ein neuer bereit, dann geht ein alter. So bleibt die Anwendung erreichbar.

## Schritte und was ihr zeigt

1. `kubectl rollout restart deployment/hallo`  
   Zeigen: Startet den Austausch, gleiches Image.

2. `kubectl get pods -l app=hallo (60 s beobachten)`  
   Zeigen: Die Reihenfolge: ein neuer Pod `0/1`, dann `1/1`, erst danach wird ein alter `Terminating`. Zeitweise drei Pods (`maxSurge: 1`).

3. `kubectl rollout status deployment/hallo --timeout=180s`  
   Zeigen: `successfully rolled out`.

## Häufige Fragen

- **Woran erkennt das Deployment, dass ein neuer Pod bereit ist?** An der Readiness-Probe, plus `minReadySeconds: 3`.
- **Was passiert, wenn der neue Pod nie bereit wird?** Der Austausch bleibt stehen, die alten Pods bleiben. Demo 2.4b.
- **Gibt es Alternativen zu RollingUpdate?** `Recreate`: erst alle alten weg, dann alle neuen. Mit Ausfallzeit, nur für Fälle, in denen zwei Versionen nicht gleichzeitig laufen dürfen.

## Wenn es hakt

- Der Austausch hängt: `kubectl describe pod` des neuen Pods, Events lesen.

## Aufräumen

Nicht nötig. Danach laufen zwei neue Pods mit demselben Stand.

Alle Demos: [Übersicht](../../README.md)
