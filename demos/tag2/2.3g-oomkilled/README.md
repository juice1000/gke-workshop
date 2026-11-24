# Demo 2.3g: OOMKilled

**Folie:** Tag 2, Check-in 2.3 Ressourcen, Auflösung 2/2 „OOMKilled“  
**Dauer:** etwa 3 Minuten  
**Ändert den Cluster:** ja, legt das Deployment `oom` an und löscht es  
**Voraussetzung:** `hallo-app:1.0` geladen

```bash
bash demos/tag2/2.3g-oomkilled/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.3g-oomkilled/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.3g-oomkilled/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Ein Container über seinem Speicherlimit wird vom Kernel beendet. Die Anwendung kann vorher nichts mehr schreiben.

## Schritte und was ihr zeigt

1. `grep -E 'Xms|memory' lab03-defekt/extra/oom.yaml`  
   Zeigen: `-Xms200m` (JVM belegt sofort 200 MiB) gegen `memory: 128Mi` als Limit.

2. `kubectl apply -f lab03-defekt/extra/oom.yaml`  
   Zeigen: `deployment.apps/oom created`.

3. `kubectl get pods -l app=oom (60 s beobachten)`  
   Zeigen: `OOMKilled`, `RESTARTS` steigt alle paar Sekunden, später `CrashLoopBackOff`.

4. `kubectl describe pod POD | grep -A4 'Last State'`  
   Zeigen: Der Beleg: `Reason: OOMKilled`, `Exit Code: 137`.

## Häufige Fragen

- **Was heißt 137?** 128 + 9: Der Prozess wurde mit Signal 9 (SIGKILL) beendet, von außen, nicht von der Anwendung.
- **Warum zeigt `logs --previous` keine Fehlermeldung?** Der Kernel beendet den Prozess sofort. Die JVM kann nichts mehr ausgeben.
- **Ist das ein Java-OutOfMemoryError?** Nein. Ein OutOfMemoryError passiert im Heap und steht im Log. OOMKilled kommt vom Kernel, weil der ganze Container über dem Limit ist.
- **Wie viel Speicher braucht die JVM?** Heap plus Nebenspeicher. Im Kurs-Image ist der Heap 65 Prozent des Limits (`MaxRAMPercentage`), Lab 2 Tag 2 Extra 5 rechnet es nach.

## Wenn es hakt

- Der Pod bleibt `Running`: `-Xms200m` fehlt in der Datei. `grep Xms lab03-defekt/extra/oom.yaml`.

## Aufräumen

Automatisch: `oom.yaml` löschen.

Alle Demos: [Übersicht](../../README.md)
