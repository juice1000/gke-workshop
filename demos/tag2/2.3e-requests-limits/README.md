# Demo 2.3e: Requests und Limits

**Folie:** Tag 2, 2.3 „Requests und Limits“ (Terminal-Streifen)  
**Dauer:** etwa 2 Minuten  
**Ändert den Cluster:** nein  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../00-vorbereiten/README.md)

```bash
bash demos/tag2/2.3e-requests-limits/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.3e-requests-limits/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.3e-requests-limits/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Requests sind Reservierungen für die Planung, Limits sind Obergrenzen zur Laufzeit. Der Node rechnet mit den Requests, nicht mit der echten Last.

## Schritte und was ihr zeigt

1. `kubectl describe pod -l app=hallo | grep -A4 Limits`  
   Zeigen: Je Pod: `Limits memory 512Mi`, `Requests cpu 250m, memory 512Mi`. Kein CPU-Limit, mit Absicht.

2. `kubectl describe nodes | grep -A8 'Allocated resources'`  
   Zeigen: `cpu` und `memory` mit Summe und Prozent der Node-Kapazität. Das ist verplant, egal ob genutzt.

## Häufige Fragen

- **Warum kein CPU-Limit?** Ein CPU-Limit bremst die JVM, auch wenn der Node frei ist. Speicher braucht ein Limit, sonst kann ein Pod den Node füllen.
- **Was passiert über dem Speicherlimit?** Der Kernel beendet den Container: `OOMKilled`, Exit Code 137. Demo 2.3g.
- **Was passiert, wenn die Requests nicht mehr passen?** Neue Pods bleiben `Pending`. Demo 2.3f.
- **Warum ist Request gleich Limit beim Speicher?** Dann rechnet der Scheduler mit dem, was der Pod wirklich darf. Kein Überbuchen des Speichers.

## Wenn es hakt

- Prozentwerte wirken klein: Docker Desktop gibt minikube oft alle CPUs des Rechners, trotz `--cpus=2`.

## Aufräumen

Nicht nötig, die Demo ändert nichts.

Alle Demos: [Übersicht](../../README.md)
