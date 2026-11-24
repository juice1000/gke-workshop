# Demo 2.3c: Liveness hängt an der Datenbank

**Folie:** Tag 2, Check-in 2.3 Probes, Auflösung 2/3 „Liveness hängt an der Datenbank“  
**Dauer:** etwa 2 Minuten  
**Ändert den Cluster:** nein, startet aber einen Tunnel im Hintergrund und beendet ihn  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../00-vorbereiten/README.md), `curl`

```bash
bash demos/tag2/2.3c-health-endpunkte/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.3c-health-endpunkte/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.3c-health-endpunkte/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Die Probes fragen nur die Anwendung selbst, keine Datenbank und keinen externen Dienst. Sonst starten bei einem Datenbankausfall alle Pods neu, ohne dass es hilft.

## Schritte und was ihr zeigt

1. `kubectl port-forward service/hallo 8080:80 & sleep 3`  
   Zeigen: Tunnel im Hintergrund. Sonst bräuchte es ein zweites Terminal.

2. `curl -s localhost:8080/actuator/health/liveness`  
   Zeigen: `{"status":"UP"}`: das fragt die Liveness.

3. `curl -s localhost:8080/actuator/health/readiness`  
   Zeigen: `{"status":"UP"}`: das fragt die Readiness.

4. `curl -s localhost:8080/`  
   Zeigen: Die normale Antwort mit Begrüßung, Pod-Name und Version.

## Häufige Fragen

- **Wo ist festgelegt, was die Endpunkte prüfen?** In Spring Boot Actuator (`management.endpoint.health.probes.enabled=true`). Ohne Zusatzkonfiguration prüfen sie nur den Zustand der Anwendung.
- **Darf Readiness die Datenbank prüfen?** Mit Vorsicht. Dann nimmt der Service alle Pods heraus, wenn die Datenbank fehlt. Manchmal gewollt, oft nicht.
- **Warum sehe ich die Details nicht?** `show-details=never` in `application.properties`. Der Endpunkt zeigt nur `UP` oder `DOWN`.

## Wenn es hakt

- Port 8080 belegt: `DEMO_PORT=18080 bash demos/tag2/2.3c-health-endpunkte/demo.sh`.

## Aufräumen

Automatisch: Der Tunnel wird beendet.

Alle Demos: [Übersicht](../../README.md)
