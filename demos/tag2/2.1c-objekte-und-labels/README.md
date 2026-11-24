# Demo 2.1c: Image, Pod, Deployment, Service

**Folie:** Tag 2, 2.1 „Eure Fragen: Image, Pod, Deployment, Service“ (Terminal-Streifen)  
**Dauer:** etwa 2 Minuten  
**Ändert den Cluster:** nein  
**Voraussetzung:** Deployment `hallo` läuft

```bash
bash demos/tag2/2.1c-objekte-und-labels/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.1c-objekte-und-labels/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.1c-objekte-und-labels/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Die Objekte kennen sich nicht über Namen, sondern über Labels. Das Deployment erzeugt Pods mit `app=hallo`, der Service sucht Pods mit `app=hallo`.

## Schritte und was ihr zeigt

1. `kubectl get all`  
   Zeigen: Die Kette: `deployment.apps/hallo`, `replicaset.apps/hallo-...`, zwei `pod/hallo-...`, `service/hallo`. Der ReplicaSet-Name steckt im Pod-Namen.

2. `kubectl get pods --show-labels`  
   Zeigen: `app=hallo` an jedem Pod, dazu `pod-template-hash=...`, das das Deployment selbst anhängt.

3. `kubectl describe service hallo | grep Selector`  
   Zeigen: `Selector: app=hallo`. Der Service kennt nur dieses Label, keine Pod-Namen und kein Deployment.

4. `kubectl get pods -l app=hallo -o jsonpath='{..image}'; echo`  
   Zeigen: `hallo-app:2.0` je Pod. Das Image ist die Vorlage, der Container läuft daraus im Pod.

## Häufige Fragen

- **Zeigt `get all` wirklich alles?** Nein. ConfigMaps, Secrets und EndpointSlices fehlen zum Beispiel. `get all` zeigt nur die gängigen Workload- und Service-Objekte.
- **Woher kommt `pod-template-hash`?** Das Deployment hängt es an, um die Pods verschiedener ReplicaSets zu unterscheiden. Demo 2.1f zeigt, warum es mehrere gibt.
- **Müssen Pod-Name, Label, Container-Name und Image gleich heißen?** Nein. Passen müssen nur Selektor und Pod-Labels.
- **Warum gibt es ein ReplicaSet, wenn ich es nie angelegt habe?** Das Deployment legt es an und hält darüber die Anzahl Pods. Bei jedem Update entsteht ein neues.

## Wenn es hakt

- `Deployment hallo fehlt`: Demo 00 ist noch nicht gelaufen.

## Aufräumen

Nicht nötig, die Demo ändert nichts.

Alle Demos: [Übersicht](../../README.md)
