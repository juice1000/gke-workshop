# Demo 2.3h (Extra): Autoscaler bei Lastspitze

**Folie:** Tag 2, Anhang, Extra-Auflösung „Autoscaler bei Lastspitze“  
**Dauer:** etwa 3 Minuten  
**Ändert den Cluster:** ja, schaltet `metrics-server` ein (bleibt an) und legt einen HPA an, der am Ende gelöscht wird  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../00-vorbereiten/README.md)

```bash
bash demos/tag2/2.3h-metriken/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.3h-metriken/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.3h-metriken/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Der HPA ändert nur die Anzahl der Pods, nach Messwerten im Verhältnis zu den Requests. Wohin Anfragen gehen, entscheidet er nicht.

## Schritte und was ihr zeigt

1. `kubectl get hpa`  
   Zeigen: Noch kein HPA.

2. `minikube addons enable metrics-server`  
   Zeigen: `The 'metrics-server' addon is enabled`. Ohne ihn gibt es keine Messwerte.

3. `kubectl top pods (90 s beobachten)`  
   Zeigen: Zuerst `Metrics API not available`, nach ein bis zwei Minuten CPU und Speicher je Pod.

4. `kubectl apply -f lab02-hallo-app/extra/hpa.yaml`  
   Zeigen: HPA für hallo: 2 bis 4 Pods, Ziel 50 Prozent der CPU-Requests.

5. `kubectl get hpa (30 s beobachten)`  
   Zeigen: `TARGETS` erst `<unknown>/50%`, dann z. B. `cpu: 3%/50%`, `REPLICAS 2`.

## Häufige Fragen

- **Warum `<unknown>`?** Der metrics-server sammelt erst. Nach etwa einer Minute kommen Werte.
- **Fügt der HPA auch Nodes hinzu?** Nein. Das macht der Cluster Autoscaler auf GKE, wenn Pods Pending bleiben.
- **Bekommt der neue Pod sofort Anfragen?** Erst wenn er bereit ist (Readiness). Bis dahin vergehen Messintervall, Planung und Start.
- **Schickt der Service Anfragen an den am wenigsten ausgelasteten Pod?** Nein. Der Service verteilt auf alle bereiten Pods, ohne auf die CPU zu schauen.

## Wenn es hakt

- Nach 90 s immer noch keine Werte: `kubectl -n kube-system get pods | grep metrics` prüfen und etwas warten.

## Aufräumen

Automatisch: HPA löschen. `metrics-server` bleibt an.

Alle Demos: [Übersicht](../../README.md)
