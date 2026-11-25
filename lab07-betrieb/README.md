# Lab 7: Vertiefung Betrieb

**Ziel:** Ihr lest Clustereinstellungen und untersucht Scheduling und Pod Disruption Budgets. Dauer: 90 Minuten. Dieses Lab läuft parallel zu Lab 6. Der Cloud-Teil ist lesend. Änderungen an Nodes führt ihr ausschließlich im eigenen lokalen Ein-Node-Cluster aus.

## Teil 1: Betriebsrundgang auf GKE (30 Minuten)

Öffnet die Clusterdetails in der Konsole. Notiert Betriebsart, Standort, Kubernetes-Version, Release Channel und Wartungsfenster. Bei Standard untersucht ihr zusätzlich Node-Pools, Auto-Upgrade und die Upgrade-Strategie. Bei Autopilot verwaltet Google die Nodes; dokumentiert die sichtbaren Einstellungen.

Wenn eure Rolle es erlaubt:

```bash
kubectl get nodes -o wide
kubectl describe node NODE_NAME
```

Findet `Conditions`, `Capacity`, `Allocatable` und `Allocated resources`. Welche Größe beschreibt tatsächlichen Verbrauch, welche eine Reservierung? Die Summe der Requests ist kein Messwert für CPU-Auslastung.

Öffnet Monitoring und vergleicht CPU und Speicher je Namespace. Im Logs Explorer sucht ihr:

```text
resource.type="k8s_container"
resource.labels.cluster_name="workshop"
resource.labels.namespace_name="kube-system"
```

Falls ihr diese Rechte nicht habt, zeigt der Trainer den Rundgang. Änderungen an Release Channel, Wartungsfenstern, Node-Pools oder Alarmrichtlinien gehören nicht zu diesem Lab.

## Teil 2: Scheduling lokal erleben (35 Minuten)

Wechselt ausdrücklich zurück in euren lokalen Cluster. Alle Befehle hier haben zusätzlich einen festen Kontext:

```bash
export WORKSHOP_CONTEXT=minikube
export WORKSHOP_NAMESPACE=workshop
kubectl config use-context minikube
kubectl config set-context minikube --namespace=workshop
kubectl --context minikube get nodes
kubectl --context minikube describe node minikube
kubectl --context minikube -n workshop apply -f lab02-hallo-app/k8s/
kubectl --context minikube -n workshop rollout status deployment/hallo --timeout=180s
```

Voraussetzung: genau ein Node namens `minikube`, lokal geladenes Image `hallo-app:1.0` und keine andere laufende `hallo`-Übung. Bei einem anderen lokalen Profil die Namen gemeinsam mit dem Trainer anpassen.

Öffnet ein zweites Terminal und beobachtet die Pods live, während ihr den Node sperrt:

```bash
kubectl --context minikube -n workshop get pods -w
```

```bash
kubectl --context minikube cordon minikube
kubectl --context minikube get nodes
kubectl --context minikube -n workshop get pods
```

Wählt einen Pod-Namen und ersetzt `POD_NAME`:

```bash
kubectl --context minikube -n workshop delete pod POD_NAME
kubectl --context minikube -n workshop get pods
kubectl --context minikube -n workshop describe pod -l app=hallo
```

Der verbleibende Pod läuft weiter. Der Ersatz-Pod bleibt `Pending`, weil der einzige Node keine neuen Pods annimmt. Hebt die Sperre wieder auf, auch wenn ihr das Experiment abbrecht:

```bash
kubectl --context minikube uncordon minikube
kubectl --context minikube -n workshop rollout status deployment/hallo --timeout=180s
```

## Teil 3: Pod Disruption Budget und Alarm (15 Minuten)

```bash
kubectl --context minikube -n workshop apply -f lab07-betrieb/pdb.yaml
kubectl --context minikube -n workshop get pdb
```

Bei zwei bereiten Pods erlaubt `minAvailable: 1` eine freiwillige Unterbrechung. Ein PDB schützt nicht vor Containerabstürzen, direktem `delete pod` oder jedem Node-Ausfall. Es wird unter anderem von der Eviction-API berücksichtigt. Die Deployment-Rolloutstrategie bleibt eine eigene Einstellung. Ein einzelner Node kann trotz PDB keine Verfügbarkeit während seiner vollständigen Abschaltung garantieren.

Formuliert einen Alarm mit Bedingung, Dauer und Handlung. Beispiel: Ein Container startet innerhalb von zehn Minuten wiederholt neu. Dann prüft der Bereitschaftsdienst zuerst `Last State`, vorige Logs und den letzten Rollout. Legt den Alarm hier als Vorschlag vor. Auf GKE legt ihr ihn in [Lab 5, Abschnitt 5](../lab05-stoerungen/README.md) wirklich an und löst ihn mit einer Störung aus.

**Abgabe, in den Chat:** Clustereinstellungen, Erklärung des `Pending`-Pods, Bedeutung von `ALLOWED DISRUPTIONS` und ein handlungsfähiger Alarmvorschlag.

## Aufräumen (10 Minuten)

```bash
kubectl --context minikube uncordon minikube
kubectl --context minikube -n workshop delete -f lab02-hallo-app/k8s/
kubectl --context minikube -n workshop delete -f lab07-betrieb/pdb.yaml
```

Ohne Cloud führt ihr Teile 2 und 3 aus. Der Trainer bespricht Release Channels und Monitoring anhand der Dokumentation oder einer Demo.
