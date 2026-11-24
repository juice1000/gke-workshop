# Demo 2.6a: Wer verantwortet was auf GKE?

**Folie:** Tag 2, Check-in 2.6, Auflösung 1/2 „Wer verantwortet was auf GKE?“  
**Dauer:** etwa 2 Minuten  
**Ändert den Cluster:** nein  
**Voraussetzung:** Cluster läuft

```bash
bash demos/tag2/2.6a-control-plane/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.6a-control-plane/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.6a-control-plane/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Lokal seht ihr die Control Plane als Pods. Auf GKE fehlt sie in der Liste: Google betreibt sie.

## Schritte und was ihr zeigt

1. `kubectl get nodes`  
   Zeigen: Ein Node mit `ROLES control-plane`. In minikube ist er Control Plane und Worker zugleich.

2. `kubectl get pods -n kube-system`  
   Zeigen: `kube-apiserver-minikube`, `etcd-minikube`, `kube-scheduler-minikube`, `kube-controller-manager-minikube`, dazu `coredns`, `kube-proxy`, Netzwerk.

## Häufige Fragen

- **Und auf GKE?** Dieselben Befehle zeigen keine API-Server- und etcd-Pods. Die laufen bei Google. In `kube-system` stehen nur Komponenten auf euren Nodes.
- **Was bleibt bei GKE Standard unsere Aufgabe?** Node-Pools, Größen, Upgrade-Fenster, Requests, Rechte. Bei Autopilot übernimmt Google auch die Nodes.
- **Was macht jeder dieser Pods?** API-Server: Eingang. etcd: Datenbank. Scheduler: wählt Nodes. Controller Manager: gleicht Soll und Ist ab. CoreDNS: Namen. kube-proxy: Service-Weiterleitung.

## Aufräumen

Nicht nötig, die Demo ändert nichts.

Alle Demos: [Übersicht](../../README.md)
