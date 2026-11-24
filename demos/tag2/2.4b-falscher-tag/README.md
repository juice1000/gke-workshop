# Demo 2.4b: Rollout mit falschem Tag

**Folie:** Tag 2, Check-in 2.4, Auflösung 1/2 „Rollout mit falschem Tag“  
**Dauer:** etwa 3 Minuten  
**Ändert den Cluster:** ja, setzt einen falschen Image-Tag und rollt am Ende zurück  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../00-vorbereiten/README.md)

```bash
bash demos/tag2/2.4b-falscher-tag/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.4b-falscher-tag/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.4b-falscher-tag/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Ein kaputtes Release stoppt den Rollout, die alten Pods bedienen weiter. Kubernetes rollt aber nicht von selbst zurück.

## Schritte und was ihr zeigt

1. `kubectl set image deployment/hallo hallo=hallo-app:nicht-vorhanden`  
   Zeigen: Ein Tag, den es nicht gibt. `hallo=` ist der Container-Name.

2. `kubectl rollout status deployment/hallo --timeout=30s`  
   Zeigen: `error: timed out waiting for the condition`.

3. `kubectl get pods -l app=hallo`  
   Zeigen: Zwei alte Pods `1/1 Running`, ein neuer `ErrImagePull` oder `ImagePullBackOff`.

4. `kubectl get deploy hallo -o jsonpath='{.spec.progressDeadlineSeconds}'; echo`  
   Zeigen: `180`. So lange wartet das Deployment, bevor es `ProgressDeadlineExceeded` meldet (Standard 600).

5. `kubectl rollout undo deployment/hallo (Aufräumen)`  
   Zeigen: Zurückrollen muss ein Mensch oder die Pipeline.

## Häufige Fragen

- **Warum rollt Kubernetes nicht selbst zurück?** Es kennt nur den Sollzustand. Ob zurückgerollt wird, entscheidet ein Mensch oder die Pipeline, z. B. am Exit-Code von `rollout status` (Demo 3.4a).
- **Was ist `ProgressDeadlineExceeded`?** Eine Bedingung am Deployment, sichtbar in `kubectl describe deployment`. Ein Signal, keine Aktion.
- **Ist `set image` der normale Weg?** Nein, nur für Tests. Der Tag gehört ins Manifest im Repository. Sonst laufen Cluster und Datei auseinander (Demo 2.4d).

## Wenn es hakt

- Nach Strg+C rollt das Skript selbst zurück.

## Aufräumen

Automatisch: `rollout undo` und `rollout status`.

Alle Demos: [Übersicht](../../README.md)
