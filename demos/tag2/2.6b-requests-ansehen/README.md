# Demo 2.6b: Autopilot ohne Requests

**Folie:** Tag 2, Check-in 2.6, Auflösung 2/2 „Autopilot ohne Requests“  
**Dauer:** etwa 1 Minute  
**Ändert den Cluster:** nein  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../00-vorbereiten/README.md)

```bash
bash demos/tag2/2.6b-requests-ansehen/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.6b-requests-ansehen/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.6b-requests-ansehen/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Lokal stehen die Requests im Manifest. Autopilot setzt fehlende selbst und rechnet danach ab.

## Schritte und was ihr zeigt

1. `kubectl get pods -l app=hallo -o jsonpath='{..resources}'; echo`  
   Zeigen: Je Pod: `{"limits":{"memory":"512Mi"},"requests":{"cpu":"250m","memory":"512Mi"}}`.

## Häufige Fragen

- **Was passiert auf Autopilot ohne Requests?** Autopilot setzt Standardwerte und kann Werte anpassen. Ihr zahlt nach diesen Requests.
- **Zu hoch oder zu niedrig, was ist schlimmer?** Zu hoch kostet Geld und Platz. Zu niedrig führt zu Drosselung oder OOMKilled.
- **Und auf GKE Standard?** Dort zahlt ihr die Nodes. Requests entscheiden, wie viele Pods auf einen Node passen.

## Aufräumen

Nicht nötig, die Demo ändert nichts.

Alle Demos: [Übersicht](../../README.md)
