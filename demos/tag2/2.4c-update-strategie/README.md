# Demo 2.4c (Extra): maxSurge und maxUnavailable

**Folie:** Tag 2, Anhang, Extra-Auflösung „maxSurge und maxUnavailable“  
**Dauer:** etwa 3 Minuten  
**Ändert den Cluster:** ja, skaliert auf 4 und am Ende zurück auf 2  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../00-vorbereiten/README.md)

```bash
bash demos/tag2/2.4c-update-strategie/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.4c-update-strategie/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.4c-update-strategie/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> `maxSurge` sagt, wie viele Pods zusätzlich entstehen dürfen. `maxUnavailable` sagt, wie viele bereite Pods fehlen dürfen.

## Schritte und was ihr zeigt

1. `kubectl get deployment hallo -o jsonpath='{.spec.strategy}'; echo`  
   Zeigen: `{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0},"type":"RollingUpdate"}`.

2. `kubectl scale deployment/hallo --replicas=4`  
   Zeigen: Vier Kopien für ein besser sichtbares Update.

3. `kubectl rollout status deployment/hallo --timeout=180s`  
   Zeigen: Warten, bis alle vier bereit sind.

4. `kubectl rollout restart deployment/hallo`  
   Zeigen: Austausch starten.

5. `kubectl get pods -l app=hallo (60 s beobachten)`  
   Zeigen: Höchstens fünf Pods gleichzeitig, nie weniger als vier bereit. Ein neuer Pod nach dem anderen.

## Häufige Fragen

- **Was gilt ohne Angabe?** Je 25 Prozent. Bei 4 Kopien: höchstens 5 Pods, mindestens 3 bereit.
- **Wann `maxUnavailable` größer als 0?** Wenn der Cluster keinen Platz für zusätzliche Pods hat. Dann darf kurz Kapazität fehlen.
- **Warum war ein neuer Pod kurz `Pending`?** Der fünfte Pod musste auf einen Platz warten. Das zeigt, dass `maxSurge` Kapazität braucht.

## Wenn es hakt

- Der Austausch dauert lange: Bei vier Pods startet die JVM viermal nacheinander.

## Aufräumen

Automatisch: zurück auf 2 Kopien.

Alle Demos: [Übersicht](../../README.md)
