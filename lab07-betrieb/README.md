# Lab 7: Vertiefung Betrieb

**Ziel:** Ihr lest Clustereinstellungen, sperrt Nodes und seht, wie ein Pod Disruption Budget eine Wartung bremst. Dauer: 60 Minuten. **Voraussetzung:** Cluster, Namespace `workshop` und `IMAGE` aus [Lab 4](../lab04-gke/README.md). Es ist euer Cluster, ihr dürft auch Nodes ändern.

## Teil 1: Betriebsrundgang (20 Minuten)

Öffnet die Clusterdetails in der Konsole. Notiert Betriebsart, Standort, Kubernetes-Version, Release Channel und Wartungsfenster. Untersucht Node-Pools, Auto-Upgrade und die Upgrade-Strategie.

```bash
kubectl get nodes -o wide
kubectl describe node NODE_NAME
```

Findet `Conditions`, `Capacity`, `Allocatable` und `Allocated resources`. Welche Größe beschreibt tatsächlichen Verbrauch, welche eine Reservierung? Die Summe der Requests ist kein Messwert für CPU-Auslastung. `kubectl top nodes` zeigt den Verbrauch.

Im Logs Explorer seht ihr, was Google und Kubernetes selbst im Cluster betreiben:

```text
resource.type="k8s_container"
resource.labels.namespace_name="kube-system"
```

## Teil 2: Scheduling erleben (25 Minuten)

Ausgangslage ist der Stand aus Lab 4:

```bash
kubectl create namespace workshop                 # nach Lab 6 Aufräumen; sonst "already exists"
kubectl create secret generic hallo-secret --from-literal=DB_PASSWORT=uebung123
sed "s#image: hallo-app:2.0#image: $IMAGE#" lab02-hallo-app/betrieb/*.yaml | kubectl apply -f -
kubectl rollout status deployment/hallo --timeout=300s
kubectl get pods -o wide                          # auf welchen Nodes?
```

Zweites Terminal, läuft mit:

```bash
kubectl get pods -o wide -w
```

Sperrt alle Nodes für neue Pods. Laufende Pods bleiben:

```bash
kubectl cordon -l cloud.google.com/gke-nodepool=default-pool
kubectl get nodes                                 # STATUS: SchedulingDisabled
kubectl delete pod POD_NAME                       # einen Pod-Namen einsetzen
kubectl get pods
kubectl describe pod -l app=hallo | grep -A3 Events
```

Der verbleibende Pod läuft weiter. Der Ersatz-Pod bleibt `Pending` mit `node(s) were unschedulable`. Hebt die Sperre wieder auf, auch wenn ihr abbrecht:

```bash
kubectl uncordon -l cloud.google.com/gke-nodepool=default-pool
kubectl rollout status deployment/hallo --timeout=180s
```

## Teil 3: Pod Disruption Budget bei einer Wartung (15 Minuten)

Eine Wartung leert einen Node mit `drain`. Ohne Budget darf sie alle Pods einer Anwendung gleichzeitig verdrängen. [pdb.yaml](pdb.yaml) verlangt, dass immer mindestens ein Pod von `hallo` läuft:

```bash
kubectl apply -f lab07-betrieb/pdb.yaml
kubectl get pdb                                   # ALLOWED DISRUPTIONS: 1
kubectl scale deployment/hallo --replicas=2
kubectl get pods -o wide                          # Node mit einem hallo-Pod wählen
kubectl drain NODE_NAME --ignore-daemonsets --delete-emptydir-data
kubectl get pods -o wide
kubectl uncordon NODE_NAME
```

Liegen beide `hallo`-Pods auf demselben Node, wartet `drain` mit `Cannot evict pod as it would violate the pod's disruption budget`, bis der erste Ersatz bereit ist. So bleibt die Anwendung erreichbar.

Ein PDB schützt nicht vor Containerabstürzen, direktem `delete pod` oder dem Ausfall eines Nodes. Es wirkt bei freiwilligen Unterbrechungen über die Eviction-API, etwa bei `drain` und Node-Upgrades.

Formuliert dann einen Alarm mit Bedingung, Dauer und Handlung. Beispiel: Ein Container startet innerhalb von zehn Minuten wiederholt neu. Dann prüft der Bereitschaftsdienst zuerst `Last State`, vorige Logs und den letzten Rollout. In [Lab 5, Abschnitt 5](../lab05-stoerungen/README.md) legt ihr so einen Alarm wirklich an.

## Aufräumen

```bash
kubectl uncordon -l cloud.google.com/gke-nodepool=default-pool
kubectl delete -f lab07-betrieb/pdb.yaml
kubectl delete -f lab02-hallo-app/betrieb/
```

Lokal geht Teil 2 genauso mit minikube: ein Node, also `kubectl cordon minikube`.
