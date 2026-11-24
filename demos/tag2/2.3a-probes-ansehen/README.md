# Demo 2.3a: Zwei Probes, zwei Fragen

**Folie:** Tag 2, 2.3 „Zwei Probes, zwei Fragen“ (Terminal-Streifen)  
**Dauer:** etwa 2 Minuten  
**Ändert den Cluster:** nein  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../00-vorbereiten/README.md)

```bash
bash demos/tag2/2.3a-probes-ansehen/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.3a-probes-ansehen/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.3a-probes-ansehen/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Readiness fragt: Darf der Pod Anfragen bekommen? Liveness fragt: Muss der Container neu starten? Startup schützt den langsamen Start.

## Schritte und was ihr zeigt

1. `kubectl get pods -l app=hallo`  
   Zeigen: `READY` ist das Ergebnis der Readiness. `RESTARTS` zählt Neustarts durch die Liveness.

2. `kubectl describe pod -l app=hallo | grep -E 'Liveness|Readiness|Startup'`  
   Zeigen: Je Probe: Pfad, `period` (Abstand), `#failure` (erlaubte Fehlschläge). Readiness alle 5 s, Liveness alle 10 s, Startup 30 Versuche à 5 s.

## Häufige Fragen

- **Laufen Readiness und Liveness nur beim Start?** Nein, beide laufen ständig. Nur die Startup-Probe läuft einmal am Anfang, bis sie erfolgreich ist.
- **Was passiert bei einer kaputten Readiness?** Der Pod bleibt laufen, bekommt aber keine Anfragen mehr: `0/1`, kein Neustart. Demo 2.3b.
- **Warum prüft Liveness nicht die Datenbank?** Fiele die Datenbank aus, würden alle Pods neu starten, ohne dass es hilft. Demo 2.3c.
- **Wie lange darf der Start dauern?** 30 × 5 s, also etwa 150 Sekunden. Ohne Startup-Probe kann die Liveness zu früh zuschlagen. Demo 2.3d.

## Wenn es hakt

- Keine Probes in der Ausgabe: `hallo` läuft noch mit dem Stand von Tag 1. Demo 00 ausführen.

## Aufräumen

Nicht nötig, die Demo ändert nichts.

Alle Demos: [Übersicht](../../README.md)
