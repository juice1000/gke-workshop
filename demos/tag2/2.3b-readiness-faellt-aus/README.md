# Demo 2.3b: Die Anwendung hängt

**Folie:** Tag 2, Check-in 2.3 Probes, Auflösung 1/3 „Die Anwendung hängt“  
**Dauer:** etwa 4 Minuten  
**Ändert den Cluster:** ja, ändert den Readiness-Pfad und rollt am Ende zurück  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../00-vorbereiten/README.md)

```bash
bash demos/tag2/2.3b-readiness-faellt-aus/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.3b-readiness-faellt-aus/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.3b-readiness-faellt-aus/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Eine scheiternde Readiness nimmt den Pod aus dem Service, ohne ihn neu zu starten. Die alten Pods bedienen weiter.

## Schritte und was ihr zeigt

1. `kubectl describe pod -l app=hallo | grep -E 'Liveness|Readiness'`  
   Zeigen: Readiness alle 5 s, nach 3 Fehlschlägen raus (etwa 15 s). Liveness alle 10 s, nach 3 Fehlschlägen Neustart (etwa 30 s).

2. `kubectl describe endpointslices -l kubernetes.io/service-name=hallo | grep -E 'Addresses|Ready|TargetRef'`  
   Zeigen: Ausgangslage: jeder Pod mit `Ready: true`.

3. `kubectl patch deployment hallo --type=json ... /gibtsnicht`  
   Zeigen: Ein neuer Pod fragt einen Pfad, den es nicht gibt.

4. `kubectl get pods -l app=hallo (60 s beobachten)`  
   Zeigen: Neuer Pod: `Running`, `READY 0/1`, `RESTARTS 0`. Die zwei alten bleiben `1/1` (`maxUnavailable: 0`).

5. `kubectl describe endpointslices ... | grep -E 'Addresses|Ready|TargetRef'`  
   Zeigen: Der neue Pod steht mit `Ready: false` in der Liste. Er bekommt keinen Traffic.

6. `kubectl describe pod POD | grep -i 'readiness probe failed'`  
   Zeigen: Der Beleg: `Readiness probe failed: HTTP probe failed with statuscode: 404`.

## Häufige Fragen

- **Warum kein Neustart?** Die Liveness fragt einen anderen Pfad, der antwortet. Readiness entscheidet nur über den Traffic.
- **Merken die Nutzer etwas?** Nein. Die alten Pods bedienen weiter, der neue bekommt nichts. Der Rollout bleibt einfach stehen.
- **Warum wird die Anwendung nicht wirklich zum Hängen gebracht?** Ein hängender Prozess lässt sich nicht sauber nachbauen. Der falsche Pfad zeigt dasselbe Signal: Readiness scheitert, Liveness nicht.
- **Wie repariere ich das im echten Leben?** Pfad in der Datei korrigieren und `apply`. Lab 2 Tag 2, Schritt 6 macht genau das.

## Wenn es hakt

- Der neue Pod bleibt `ContainerCreating`: kurz warten, die JVM startet noch.
- Nach Strg+C rollt das Skript selbst zurück.

## Aufräumen

Automatisch: `rollout undo` und `rollout status`.

Alle Demos: [Übersicht](../../README.md)
