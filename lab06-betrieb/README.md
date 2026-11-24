# Lab 6: Vertiefung Betrieb

**Ziel:** Ihr lest Clustereinstellungen und untersucht Scheduling und Pod Disruption Budgets. Dauer: 90 Minuten. Dieses Lab läuft parallel zu Lab 5. Der Cloud-Teil ist lesend. Änderungen an Nodes führt ihr ausschließlich im eigenen lokalen Ein-Node-Cluster aus.

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

Voraussetzung: genau ein Node namens `minikube`, lokal geladenes Image `hallo-app:1.0` und keine andere laufende `hallo`-Übung. Der Ordner `lab02-hallo-app/k8s/` enthält Deployment und Service aus Lab 2. Bei einem anderen lokalen Profil die Namen gemeinsam mit dem Trainer anpassen.

**Aufgabe: Node sperren.** Sperrt den Node `minikube` für neue Pods. Laufende Pods sollen dabei weiterlaufen. Den Befehl findet ihr in `kubectl --help` unter den Befehlen zur Clusterverwaltung. Vergesst nicht `--context minikube`. Prüft danach:

```bash
kubectl --context minikube get nodes
kubectl --context minikube -n workshop get pods
```

Erwartet: Der Node zeigt `Ready,SchedulingDisabled`, beide Pods laufen weiter.

Wählt einen Pod-Namen und ersetzt `POD_NAME`:

```bash
kubectl --context minikube -n workshop delete pod POD_NAME
kubectl --context minikube -n workshop get pods
kubectl --context minikube -n workshop describe pod -l app=hallo
```

Der verbleibende Pod läuft weiter. Der Ersatz-Pod bleibt `Pending`, weil der einzige Node keine neuen Pods annimmt. Lest in `describe` das Event, das den Grund nennt.

Hebt die Sperre wieder auf, auch wenn ihr das Experiment abbrecht. Der Befehl steht in `kubectl --help` direkt neben dem zum Sperren. Prüft danach:

```bash
kubectl --context minikube get nodes
kubectl --context minikube -n workshop rollout status deployment/hallo --timeout=180s
```

## Teil 3: Pod Disruption Budget und Alarm (15 Minuten)

**Aufgabe: PDB schreiben.** [pdb.yaml](pdb.yaml) ist unvollständig. Ergänzt die `TODO`-Stellen: Mindestens ein Pod von `hallo` soll bei freiwilligen Unterbrechungen bereit bleiben. Aufbau und Felder: `kubectl explain poddisruptionbudget.spec` und die [Dokumentation zu Disruptions](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/).

```bash
kubectl --context minikube -n workshop apply -f lab06-betrieb/pdb.yaml
kubectl --context minikube -n workshop get pdb
```

Erwartet: `ALLOWED DISRUPTIONS` ist `1`. Steht dort `0`, findet der Selektor keine Pods oder es sind nicht genug bereit.

Bei zwei bereiten Pods erlaubt `minAvailable: 1` eine freiwillige Unterbrechung. Ein PDB schützt nicht vor Containerabstürzen, direktem `delete pod` oder jedem Node-Ausfall. Es wird unter anderem von der Eviction-API berücksichtigt. Die Deployment-Rolloutstrategie bleibt eine eigene Einstellung. Ein einzelner Node kann trotz PDB keine Verfügbarkeit während seiner vollständigen Abschaltung garantieren.

Formuliert einen Alarm mit Bedingung, Dauer und Handlung. Beispiel: Ein Container startet innerhalb von zehn Minuten wiederholt neu. Dann prüft der Bereitschaftsdienst zuerst `Last State`, vorige Logs und den letzten Rollout. Legt den Alarm hier nur als Vorschlag vor.

**Abgabe:** Clustereinstellungen, Erklärung des `Pending`-Pods, Bedeutung von `ALLOWED DISRUPTIONS` und ein handlungsfähiger Alarmvorschlag.

## Aufräumen (10 Minuten)

```bash
kubectl --context minikube uncordon minikube
kubectl --context minikube -n workshop delete -f lab02-hallo-app/k8s/
kubectl --context minikube -n workshop delete -f lab06-betrieb/pdb.yaml
```

Ohne Cloud führt ihr Teile 2 und 3 aus. Der Trainer bespricht Release Channels und Monitoring anhand der Dokumentation oder einer Demo.
