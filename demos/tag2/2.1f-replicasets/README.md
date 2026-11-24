# Demo 2.1f: Zwei ReplicaSets

**Folie:** Tag 2, Check-in 2.1, Auflösung 3/3 „Zwei ReplicaSets“  
**Dauer:** etwa 3 Minuten  
**Ändert den Cluster:** ja, ersetzt die Pods durch neue (rollout restart)  
**Voraussetzung:** Deployment `hallo` läuft

```bash
bash demos/tag2/2.1f-replicasets/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.1f-replicasets/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.1f-replicasets/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Jede Änderung am Pod-Template erzeugt ein neues ReplicaSet. Das alte bleibt mit 0 Pods stehen. Genau das ist das Ziel für ein Rollback.

## Schritte und was ihr zeigt

1. `kubectl get replicasets -l app=hallo`  
   Zeigen: Ein ReplicaSet mit `DESIRED 2`, `READY 2`.

2. `kubectl rollout restart deployment/hallo`  
   Zeigen: Schreibt die Uhrzeit als Annotation ins Pod-Template. Das zählt als Änderung.

3. `kubectl rollout status deployment/hallo --timeout=180s`  
   Zeigen: `1 out of 2 new replicas have been updated`, `1 old replicas are pending termination`, dann `successfully rolled out`.

4. `kubectl get replicasets -l app=hallo`  
   Zeigen: Jetzt zwei: das neue mit `2 2 2`, das alte mit `0 0 0`. Der Hash im Namen unterscheidet sie.

5. `kubectl rollout history deployment/hallo`  
   Zeigen: Revisionen. Genau diese Liste nutzt `rollout undo` in 2.4.

## Häufige Fragen

- **Warum wird das alte ReplicaSet nicht gelöscht?** Es ist das Ziel für `rollout undo`. `revisionHistoryLimit: 5` im Deployment legt fest, wie viele alte stehen bleiben.
- **Erzeugt `scale` auch ein neues ReplicaSet?** Nein. `replicas` gehört nicht zum Pod-Template. Nur Änderungen unter `template` erzeugen ein neues.
- **Warum steht bei `CHANGE-CAUSE` `<none>`?** Der Wert kommt aus der Annotation `kubernetes.io/change-cause`. Lab 2 Tag 2 Extra 4 setzt sie.

## Wenn es hakt

- Der Rollout hängt: `kubectl describe pod -l app=hallo` und die Events lesen.

## Aufräumen

Nicht nötig. Es laufen danach zwei neue Pods mit demselben Stand.

Alle Demos: [Übersicht](../../README.md)
