# Demo 2.1d: Service ohne Endpunkte

**Folie:** Tag 2, Check-in 2.1, Auflösung 1/3 „Service ohne Endpunkte“  
**Dauer:** etwa 3 Minuten  
**Ändert den Cluster:** ja, ändert den Selektor des Service und stellt ihn wieder her  
**Voraussetzung:** Deployment `hallo` läuft

```bash
bash demos/tag2/2.1d-service-ohne-endpunkte/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.1d-service-ohne-endpunkte/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.1d-service-ohne-endpunkte/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Die Pods sind gesund, trotzdem kommt keine Anfrage an: Der Selektor des Service passt zu keinem Pod. Neu starten hilft nicht, nur der richtige Selektor.

## Schritte und was ihr zeigt

1. `kubectl describe service hallo | grep Selector`  
   Zeigen: Ausgangslage: `Selector: app=hallo`.

2. `kubectl get endpointslices -l kubernetes.io/service-name=hallo`  
   Zeigen: `ENDPOINTS` mit zwei Pod-IPs, z. B. `10.244.0.3,10.244.0.4`, `PORTS 8080`.

3. `kubectl patch service hallo -p '{"spec":{"selector":{"app":"hallo-app"}}}'`  
   Zeigen: Fehler einbauen, wie in der Challenge aus 1.4: `service/hallo patched`.

4. `kubectl get pods -l app=hallo`  
   Zeigen: Beide Pods weiter `1/1 Running`. An den Pods liegt es nicht.

5. `kubectl get pods -l app=hallo-app`  
   Zeigen: `No resources found`. So sieht der Service die Welt jetzt.

6. `kubectl get endpointslices -l kubernetes.io/service-name=hallo`  
   Zeigen: Der Beleg: `ENDPOINTS <unset>`, `PORTS <unset>`. Der Service hat kein Ziel.

7. `kubectl patch service hallo ... app: hallo (Aufräumen)`  
   Zeigen: Danach wieder zwei IPs in der EndpointSlice.

## Häufige Fragen

- **Warum meldet der Service keinen Fehler?** Ein Selektor ohne Treffer ist gültig. Kubernetes prüft nicht, ob der Service sinnvoll ist. Die leere EndpointSlice ist der einzige Hinweis.
- **Hilft `rollout restart` oder `scale`?** Nein. Die neuen Pods tragen wieder `app=hallo`, der Service sucht weiter `app=hallo-app`.
- **Was sieht ein Nutzer?** Mit `port-forward service/hallo` kommt keine Verbindung zustande. Im Cluster liefert `http://hallo` keine Antwort, weil es kein Ziel gibt.
- **Welches Label ist das richtige?** Das aus `template.metadata.labels` im Deployment, nicht `metadata.labels` des Deployments.

## Wenn es hakt

- Nach Strg+C stellt das Skript den Selektor selbst wieder her. Sonst: `kubectl apply -f lab02-hallo-app/betrieb/service.yaml`.

## Aufräumen

Automatisch am Ende: Selektor wieder `app=hallo`.

Alle Demos: [Übersicht](../../README.md)
