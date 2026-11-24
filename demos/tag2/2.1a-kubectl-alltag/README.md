# Demo 2.1a: kubectl im Alltag

**Folie:** Tag 2, 2.1 „1.5 kompakt: kubectl im Alltag“ (Terminal-Streifen)  
**Dauer:** etwa 2 Minuten  
**Ändert den Cluster:** nein  
**Voraussetzung:** Deployment `hallo` läuft

```bash
bash demos/tag2/2.1a-kubectl-alltag/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.1a-kubectl-alltag/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.1a-kubectl-alltag/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Drei Befehle beantworten fast jede Frage zu einem Pod: Wie geht es ihm (`get`), was ist mit ihm passiert (`describe`), was sagt die Anwendung selbst (`logs`).

## Schritte und was ihr zeigt

1. `kubectl get pods`  
   Zeigen: Spalten `READY` (1/1), `STATUS` (Running), `RESTARTS` (0), `AGE`. Zwei Pods mit zufälliger Endung im Namen.

2. `kubectl describe pod -l app=hallo`  
   Zeigen: Ganz nach unten scrollen zu `Events`: Scheduled, Pulled, Created, Started. Auf dem Weg kurz `Image: hallo-app:2.0`, `Limits`/`Requests`, die drei Probes und `Environment` mit `GREETING` aus der ConfigMap.

3. `kubectl logs -l app=hallo --prefix --tail=5`  
   Zeigen: Vor jeder Zeile steht der Pod-Name (`--prefix`). Spring-Boot-Startzeilen aus beiden Pods.

## Häufige Fragen

- **Warum steht in den Events `already present on machine`?** Das Image wurde mit `minikube image load` geladen, und `imagePullPolicy: IfNotPresent` gilt. Es wird nichts heruntergeladen.
- **Wie sehe ich die Logs nur eines Pods?** `kubectl logs POD-NAME`, oder `kubectl logs deploy/hallo` (nimmt einen der Pods).
- **Kann ich die Logs live verfolgen?** `kubectl logs -f -l app=hallo --prefix`, beenden mit Strg+C.
- **Warum `-l app=hallo` statt Pod-Namen?** Pod-Namen ändern sich bei jedem Neustart, das Label bleibt. Über dasselbe Label findet auch der Service die Pods.
- **Wie lange gibt es die Events?** Etwa eine Stunde. Danach sind sie weg, die Logs bleiben bis zum Ende des Pods.

## Wenn es hakt

- `Deployment hallo fehlt`: Demo 00 ist noch nicht gelaufen.

## Aufräumen

Nicht nötig, die Demo ändert nichts.

Alle Demos: [Übersicht](../../README.md)
