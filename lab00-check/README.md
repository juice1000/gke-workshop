# Lab 0: Umgebung prüfen

**Ziel:** Ihr habt einen erreichbaren lokalen Cluster und wisst, wohin kubectl zeigt. Dauer: 30 Minuten. Installationen möglichst vor dem Kurs mit der IT klären.

## 1. Werkzeuge

Im Hauptordner des Repositorys:

```bash
bash lab00-check/check.sh
```

Bei `FEHLT` lest ihr den Hinweis und prüft die Installation oder das Netzwerk. Das Skript installiert nichts. Es legt keinen Cluster an und führt keinen Cloud-Login durch.

Installationsanleitungen: [Docker](https://docs.docker.com/get-started/get-docker/), [minikube](https://minikube.sigs.k8s.io/docs/start/), [kubectl](https://kubernetes.io/docs/tasks/tools/). Unter Windows laufen alle weiteren Befehle in WSL-Bash. Bei Docker Desktop muss die Integration für eure WSL-Distribution eingeschaltet sein.

## 2. Cluster starten

```bash
minikube start --driver=docker --cpus=2 --memory=4096 --kubernetes-version=v1.35.0
minikube status
kubectl config use-context minikube
kubectl get nodes
```

Der erste Start lädt Images. Wartet auf einen Node mit `STATUS Ready`. Die hier angegebene Kubernetes-Version ist die Version des lokalen Probelaufs. Falls sie im Firmennetz nicht verfügbar ist, stimmt die Alternative mit dem Trainer ab. kubectl soll höchstens eine Minor-Version von der Serverversion abweichen. Prüft die Client-Version mit `kubectl version --client`. Bei einem älteren Client könnt ihr lokal vorläufig `minikube kubectl -- get nodes` verwenden und danach eine passende kubectl-Version installieren. Die Checkpoints rufen das installierte `kubectl` auf.

## 3. Eigenen lokalen Namespace verwenden

```bash
export WORKSHOP_CONTEXT=minikube
export WORKSHOP_NAMESPACE=workshop
kubectl --context "$WORKSHOP_CONTEXT" create namespace "$WORKSHOP_NAMESPACE"
kubectl config set-context "$WORKSHOP_CONTEXT" --namespace="$WORKSHOP_NAMESPACE"
kubectl config current-context
kubectl config view --minify -o jsonpath='{..namespace}'
```

`AlreadyExists` beim Namespace ist beim zweiten Durchlauf in Ordnung. Erwartet: Kontext `minikube`, Namespace `workshop`. Die Variablen gelten nur im aktuellen Terminal. Setzt sie in einem neuen Terminal erneut.

Manuelle `kubectl`-Befehle verwenden den aktuellen Kontext. Die Checkpoint-Skripte verwenden ausdrücklich `WORKSHOP_CONTEXT` und `WORKSHOP_NAMESPACE`, standardmäßig `minikube` und `workshop`. Haltet beides zusammen passend.

## 4. Visueller Rundgang

```bash
minikube dashboard
```

Der Befehl läuft im Vordergrund. Öffnet ein zweites Terminal für weitere Befehle. Im Dashboard den Namespace `workshop` auswählen. Noch sind dort keine Workloads. Beendet das Dashboard mit Strg+C, wenn ihr es nicht mehr braucht.

**Abgabe:** Kontext, Namespace und Ausgabe von `kubectl get nodes`.

## Wenn es hakt

| Beobachtung | Nächster Schritt |
| --- | --- |
| Docker nicht erreichbar | Docker starten, WSL-Integration und `docker info` prüfen |
| Zu wenig Speicher | Andere Anwendungen schließen, Docker-Ressourcen mit der IT prüfen |
| Pull oder Download scheitert | Genaue Registry/URL und Proxy-Einstellungen mit der IT prüfen |
| kubectl zeigt Cloud-Pods | `kubectl config use-context minikube`, Kontext erneut prüfen |
| Lokaler Cluster nicht möglich | In Paaren am funktionierenden Rechner arbeiten; Trainer zeigt die Demo |

Den Cluster für die nächsten Labs laufen lassen. Nach dem Kurs: `minikube stop`. Ein vollständiges Entfernen des lokalen Übungsclusters erfolgt mit `minikube delete -p minikube`.
