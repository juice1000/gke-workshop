# Demo 2.3d: Langsamer Start

**Folie:** Tag 2, Check-in 2.3 Probes, Auflösung 3/3 „Langsamer Start“  
**Dauer:** etwa 4 Minuten  
**Ändert den Cluster:** ja, entfernt die Startup-Probe und rollt am Ende zurück  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../00-vorbereiten/README.md)

```bash
bash demos/tag2/2.3d-langsamer-start/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.3d-langsamer-start/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.3d-langsamer-start/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Ohne Startup-Probe kann eine strenge Liveness den Container töten, bevor die Anwendung fertig gestartet ist. Ergebnis: Neustarts bis CrashLoopBackOff.

## Schritte und was ihr zeigt

1. `kubectl describe pod -l app=hallo | grep -E 'Startup|Liveness'`  
   Zeigen: So steht es im Repository: Startup alle 5 s, 30 Versuche, bis zu 150 s für den Start.

2. `kubectl patch deployment hallo --type=json ... (Startup weg, Liveness alle 2 s, ein Fehlschlag)`  
   Zeigen: Die Frage von der Folie nachbauen. Die alten Pods bleiben bereit.

3. `kubectl get pods -l app=hallo (90 s beobachten)`  
   Zeigen: Neuer Pod: `RESTARTS` steigt, später `CrashLoopBackOff`. Die alten bleiben `1/1`.

4. `kubectl describe pod POD | grep -E 'Liveness probe failed|Killing|Back-off'`  
   Zeigen: Der Beleg: `Liveness probe failed ... connection refused`, `failed liveness probe, will be restarted`, `Back-off restarting failed container`.

5. `kubectl logs POD --previous | tail -n 5`  
   Zeigen: `Started HalloApplication ...`, direkt danach `Commencing graceful shutdown`. Der Start war fast fertig, dann kam der Neustart.

## Häufige Fragen

- **Warum ein Neustart, die Anwendung startet doch in 2 Sekunden?** Die erste Liveness-Prüfung kommt sofort, bevor Tomcat lauscht. Bei `failureThreshold: 1` reicht ein Fehlschlag. Auf einem vollen Rechner oder Node dauert der Start viel länger.
- **Warum nicht einfach `initialDelaySeconds`?** Ginge, ist aber ein fester Wert. Die Startup-Probe wartet genau so lange wie nötig und gibt dann die Liveness frei.
- **Manchmal überlebt ein Pod nach einem Neustart?** Ja, wenn die zweite Prüfung zufällig nach dem Start kommt. Darum ist das Verhalten unzuverlässig, genau wie im echten Betrieb.

## Wenn es hakt

- Nach Strg+C rollt das Skript selbst zurück.

## Aufräumen

Automatisch: `rollout undo` und `rollout status`.

Alle Demos: [Übersicht](../../README.md)
