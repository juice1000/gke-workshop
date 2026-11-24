# Demo 2.2a: ConfigMap geändert, alte Begrüßung

**Folie:** Tag 2, Check-in 2.2, Auflösung 1/2 „ConfigMap geändert, alte Begrüßung“  
**Dauer:** etwa 4 Minuten  
**Ändert den Cluster:** ja, ändert die ConfigMap und setzt sie am Ende auf die Datei zurück  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../00-vorbereiten/README.md)

```bash
bash demos/tag2/2.2a-configmap-neustart/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.2a-configmap-neustart/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.2a-configmap-neustart/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Umgebungsvariablen werden nur beim Start des Containers gelesen. Eine geänderte ConfigMap kommt erst in neuen Pods an, ohne neues Image.

## Schritte und was ihr zeigt

1. `kubectl exec deploy/hallo -- printenv GREETING`  
   Zeigen: `Hallo aus der ConfigMap`: der Wert im laufenden Container.

2. `kubectl patch configmap hallo-config -p '{"data":{"GREETING":"Hallo aus der Demo"}}'`  
   Zeigen: ConfigMap im Cluster ändern.

3. `kubectl get configmap hallo-config -o jsonpath='{.data.GREETING}'; echo`  
   Zeigen: `Hallo aus der Demo`: Die ConfigMap ist geändert.

4. `kubectl exec deploy/hallo -- printenv GREETING`  
   Zeigen: Der Kernmoment: weiter `Hallo aus der ConfigMap`. Der Container hat den alten Wert.

5. `kubectl rollout restart deployment/hallo`  
   Zeigen: Neue Pods aus demselben Image und Template.

6. `kubectl rollout status deployment/hallo --timeout=180s`  
   Zeigen: `successfully rolled out`.

7. `kubectl exec deploy/hallo -- printenv GREETING`  
   Zeigen: `Hallo aus der Demo`. Kein Rebuild, nur neue Pods.

## Häufige Fragen

- **Geht es auch ohne Neustart?** Als Datei eingebunden (Volume) aktualisiert Kubernetes die ConfigMap nach etwa einer Minute. Die Anwendung muss die Datei dann aber selbst neu lesen. Lab 2 Tag 2 Extra 1 zeigt es.
- **Ist `rollout restart` ein Neustart desselben Pods?** Nein. Es entstehen neue Pods mit neuen Namen, nacheinander, ohne Ausfall.
- **Warum nicht einfach `kubectl delete pod`?** Ginge auch, aber beide Pods auf einmal heißt kurz keine Antwort. `rollout restart` tauscht sie einzeln.
- **Und im Repository?** Hier wurde nur der Cluster geändert. Dauerhaft gehört der neue Wert in `configmap.yaml`, dann `apply` und `rollout restart`.

## Wenn es hakt

- Nach Strg+C stellt das Skript die ConfigMap aus der Datei wieder her und startet neu.

## Aufräumen

Automatisch: `configmap.yaml` anwenden und `rollout restart`.

Alle Demos: [Übersicht](../../README.md)
