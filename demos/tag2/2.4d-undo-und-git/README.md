# Demo 2.4d: Undo und Git

**Folie:** Tag 2, Check-in 2.4, Auflösung 2/2 „Undo und Git“  
**Dauer:** etwa 3 Minuten  
**Ändert den Cluster:** ja, setzt Version 1.0 und stellt am Ende die Datei wieder her  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../00-vorbereiten/README.md), `hallo-app:1.0` geladen

```bash
bash demos/tag2/2.4d-undo-und-git/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.4d-undo-und-git/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.4d-undo-und-git/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Eine Änderung direkt im Cluster lässt Cluster und Repository auseinanderlaufen. Das nächste `apply` aus dem Repository setzt die Datei wieder durch.

## Schritte und was ihr zeigt

1. `kubectl set image deployment/hallo hallo=hallo-app:1.0`  
   Zeigen: Notmaßnahme direkt im Cluster: zurück auf 1.0.

2. `kubectl rollout status deployment/hallo --timeout=180s`  
   Zeigen: `successfully rolled out`.

3. `kubectl rollout history deployment/hallo`  
   Zeigen: Eine Revision mehr.

4. `kubectl get deployment hallo -o wide`  
   Zeigen: Spalte `IMAGES`: `hallo-app:1.0`. Das läuft.

5. `grep image: lab02-hallo-app/betrieb/deployment.yaml`  
   Zeigen: `image: hallo-app:2.0`. Das steht im Repository. Der Widerspruch ist der Kern.

6. `kubectl apply -f lab02-hallo-app/betrieb/deployment.yaml (Aufräumen)`  
   Zeigen: Das nächste `apply` oder die Pipeline bringt wieder 2.0.

7. `kubectl get deployment hallo -o wide`  
   Zeigen: `hallo-app:2.0`.

## Häufige Fragen

- **Ist `rollout undo` dann falsch?** Nein, als schnelle Notmaßnahme richtig. Danach muss die Korrektur ins Repository, sonst überschreibt das nächste Deployment sie.
- **Wie erkenne ich so eine Abweichung?** `kubectl diff -f datei.yaml` zeigt sie. GitOps-Werkzeuge melden sie dauerhaft.
- **Wer gewinnt, Cluster oder Datei?** Beim nächsten `apply` die Datei. Darum gilt: Die Datei ist die Wahrheit.

## Wenn es hakt

- `ErrImagePull` mit 1.0: `hallo-app:1.0` fehlt im Cluster. Demo 00 lädt es.

## Aufräumen

Automatisch: `betrieb/deployment.yaml` anwenden.

Alle Demos: [Übersicht](../../README.md)
