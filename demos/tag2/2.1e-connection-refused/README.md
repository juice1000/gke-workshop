# Demo 2.1e: Connection refused am Morgen

**Folie:** Tag 2, Check-in 2.1, Auflösung 2/3 „Connection refused am Morgen“  
**Dauer:** etwa 2 Minuten  
**Ändert den Cluster:** nein  
**Voraussetzung:** Cluster läuft

```bash
bash demos/tag2/2.1e-connection-refused/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.1e-connection-refused/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.1e-connection-refused/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> `connection refused` heißt: kubectl erreicht keinen API-Server. Die Meldung sagt nichts über eure Pods. Meist ist nach einem Neustart des Rechners minikube nicht gestartet.

## Schritte und was ihr zeigt

1. `kubectl --server=https://127.0.0.1:1 get pods`  
   Zeigen: Simulation mit falscher Adresse, der Cluster bleibt an. Mehrere Zeilen `couldn't get current server API group list ... connect: connection refused`. kubectl versucht es mehrmals.

2. `minikube status`  
   Zeigen: `host: Running`, `kubelet: Running`, `apiserver: Running`. So prüft ihr den lokalen Cluster.

3. `kubectl cluster-info`  
   Zeigen: `Kubernetes control plane is running at https://127.0.0.1:PORT`. Das ist die Adresse aus der kubeconfig.

## Häufige Fragen

- **Sind meine Pods jetzt weg?** Nein. Bei einem gestoppten minikube sind sie nur nicht erreichbar. Nach `minikube start` laufen sie wieder, Deployments starten sie neu.
- **Was ist, wenn ich im falschen Kontext bin?** Dann kommt eine andere Meldung oder, schlimmer, die Antwort eines anderen Clusters. `kubectl config current-context` zuerst prüfen.
- **Warum ändert sich der Port nach jedem Start?** Mit dem Docker-Treiber vergibt minikube den Port neu und schreibt ihn in die kubeconfig.

## Wenn es hakt

- Die vielen `E1124 ... memcache.go`-Zeilen sind normal: kubectl wiederholt die Anfrage.

## Aufräumen

Nicht nötig, die Demo ändert nichts.

Alle Demos: [Übersicht](../../README.md)
