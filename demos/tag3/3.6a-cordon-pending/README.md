# Demo 3.6a: Gesperrter Node, Ersatz-Pod Pending

**Folie:** Tag 3, 3.6 Lab 6: Vertiefung Betrieb  
**Dauer:** etwa 3 Minuten  
**Ändert den Cluster:** ja, sperrt den Node und hebt die Sperre am Ende auf, auch bei Strg+C  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../../tag2/00-vorbereiten/README.md)

```bash
bash demos/tag3/3.6a-cordon-pending/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag3/3.6a-cordon-pending/demo.sh --auto     # ohne Pausen
bash demos/tag3/3.6a-cordon-pending/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> `cordon` sperrt einen Node für neue Pods. Laufende Pods bleiben. Ein Ersatz-Pod findet im Ein-Node-Cluster keinen Platz.

## Schritte und was ihr zeigt

1. `kubectl cordon minikube`  
   Zeigen: `node/minikube cordoned`.

2. `kubectl get nodes`  
   Zeigen: `STATUS Ready,SchedulingDisabled`.

3. `kubectl get pods -l app=hallo`  
   Zeigen: Die laufenden Pods merken nichts, weiter `1/1`.

4. `kubectl delete pod POD`  
   Zeigen: Ein Pod geht verloren, das Deployment will Ersatz.

5. `kubectl get pods -l app=hallo (15 s beobachten)`  
   Zeigen: Der Ersatz bleibt `Pending`.

6. `kubectl describe pod PENDING-POD | tail -n 4`  
   Zeigen: Der Beleg: `1 node(s) were unschedulable`.

7. `kubectl uncordon minikube (Aufräumen)`  
   Zeigen: Der Ersatz-Pod startet.

## Häufige Fragen

- **Wozu sperrt man einen Node?** Vor Wartung oder Upgrade: keine neuen Pods mehr dorthin. Danach `drain`, um die laufenden zu verschieben (Demo 3.6b).
- **Und mit mehreren Nodes?** Dann landet der Ersatz auf einem anderen Node. Hier gibt es nur einen, darum Pending.
- **Macht GKE das selbst?** Ja, bei Node-Upgrades sperrt und leert GKE die Nodes nacheinander.

## Wenn es hakt

- Node bleibt gesperrt nach hartem Abbruch: `kubectl uncordon minikube`.

## Aufräumen

Automatisch: `uncordon` und `rollout status`.

Alle Demos: [Übersicht](../../README.md)
