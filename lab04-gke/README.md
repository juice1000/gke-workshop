# Lab 4: hallo-app auf GKE

**Ziel:** Ihr ladet ein Image in Artifact Registry, deployt es auf GKE und findet dieselben Objekte in der Konsole. Dauer: 60 Minuten. **Voraussetzung:** [Cloud-Vorbereitung durch den Trainer](../trainer/README.md), euer Google-Konto hat Zugang. Ihr erstellt keinen Cluster.

Alle Befehle aus dem Repository-Hauptordner in Bash. Docker und gcloud laufen in derselben Umgebung, unter Windows also in WSL.

## Das Minimum

- Lokal kopiert ihr das Image mit `minikube image load` in den Cluster. In der Cloud ladet ihr es in Artifact Registry hoch, und der GKE-Node holt es dort ab.
- Die Manifeste sind dieselben wie lokal. Nur der Image-Pfad ändert sich.
- Ein Kontext ist Cluster plus Benutzer plus Standard-Namespace. Vor jeder Änderung prüft ihr ihn.
- Die Konsole zeigt dieselben Objekte wie `kubectl`. Beides liest beim selben API-Server.
- Euer Konto darf nur in eurem Namespace arbeiten.

## Das Bild dazu

```text
Dockerfile --docker build--> Image hallo-app:2.0
                                 |
          lokal: minikube image load      Cloud: docker push
                 v                             v
             minikube                  Artifact Registry
                                               |
                                               v
                                     GKE-Node laedt das Image
```

## Kern

### 1. Verbinden

Was passiert: `gcloud` meldet euch an und schreibt einen neuen Kontext für den GKE-Cluster in eure kubeconfig. Dann setzt ihr euren Namespace als Standard.

Übernehmt die Werte vom Trainer. `REGION` ist der Standort der Registry, `LOCATION` der des Clusters.

```bash
export PROJECT_ID=PROJEKT_VOM_TRAINER
export REGION=REGISTRY_REGION_VOM_TRAINER
export REPOSITORY=REPOSITORY_VOM_TRAINER
export CLUSTER_NAME=CLUSTER_VOM_TRAINER
export LOCATION=CLUSTER_STANDORT_VOM_TRAINER
export WORKSHOP_NAMESPACE=workshop-person01        # euer Namespace

gcloud auth login                                  # Anmeldung im Browser
gke-gcloud-auth-plugin --version                   # Plugin fuer die Anmeldung von kubectl
gcloud container clusters get-credentials "$CLUSTER_NAME" \
  --location "$LOCATION" --project "$PROJECT_ID" --dns-endpoint   # legt den Kontext an
export WORKSHOP_CONTEXT="$(kubectl config current-context)"
kubectl config set-context "$WORKSHOP_CONTEXT" --namespace="$WORKSHOP_NAMESPACE"
kubectl config get-contexts                        # * markiert den aktuellen Kontext
bash lab00-check/check.sh cloud                    # prueft Zugang und Namespace
```

Erwartet: ein Kontext `gke_...` mit eurem Namespace, und `check.sh cloud` ohne Fehler.

> **Hintergrund:** `get-credentials` legt nur die Verbindung an. Ob ihr etwas tun dürft, entscheiden IAM (dürft ihr zum Cluster) und RBAC (was dürft ihr im Namespace). Das vertieft Tag 3.

**Gut zu wissen:** `--dns-endpoint` verbindet über einen DNS-Namen mit Google-Anmeldung statt über eine IP-Adresse. Auf unserem Cluster ist nur dieser Weg offen.

### 2. Image bauen und hochladen

Was passiert: Ihr baut das Image unter dem vollen Registry-Namen und schiebt es nach Artifact Registry. Jede Person hat einen eigenen Image-Namen, damit niemand fremde Tags überschreibt.

```bash
export IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY/hallo-app-$WORKSHOP_NAMESPACE:2.0"
gcloud auth configure-docker "$REGION-docker.pkg.dev"   # Docker darf mit eurem Konto pushen

docker build --platform linux/amd64 --build-arg APP_VERSION=2.0 \
  -t "$IMAGE" lab02-hallo-app                           # Image fuer amd64-Nodes
docker push "$IMAGE"                                    # hochladen
```

Erwartet: Der Push endet mit einer Zeile `digest: sha256:...`.

Prüft den Push: Listet alle Images im Repository und findet eures mit Tag und Digest. Findet es danach in der Konsole unter Artifact Registry.

```bash
gcloud artifacts docker images list "$REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY" --include-tags
```

> **Hintergrund:** Push und Pull sind getrennte Rechte. Euer Konto lädt hoch, die Identität der Nodes lädt herunter.

**Gut zu wissen:** `--platform linux/amd64` baut für die Prozessorarchitektur der GKE-Nodes. Auf einem Mac mit Apple-Chip wäre das Image sonst ARM und liefe auf den Nodes nicht.

### 3. Manifeste vorbereiten und ausrollen

Was passiert: In [k8s/](k8s/) steht statt eines Images der Platzhalter `WORKSHOP_IMAGE`. `render.py` schreibt eine Arbeitskopie mit eurem Image nach `out/lab04/`. Die rollt ihr aus.

```bash
python3 scripts/render.py lab04-gke/k8s --image "$IMAGE" --output out/lab04   # nur Dateien, kein Cluster
kubectl config current-context                     # erwartet: gke_...
kubectl apply -f out/lab04/
kubectl rollout status deployment/hallo --timeout=600s
kubectl get pods -o wide                           # NODE zeigt, wo die Pods laufen
```

Erwartet: zwei Pods `Running` mit `1/1`.

**Gut zu wissen:** `render.py` ersetzt nur den Platzhalter und überschreibt keine vorhandene Arbeitskopie. Für einen zweiten Versuch nehmt einen neuen Ordner, etwa `out/lab04-2`.

### 4. CLI und Konsole vergleichen

Was passiert: Ihr seht dieselben Objekte zweimal, einmal mit `kubectl`, einmal in der Google Cloud Console.

```bash
kubectl describe deployment hallo                       # Image, Replikas, Events
kubectl logs -l app=hallo --prefix --tail=30            # Logs beider Pods
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl port-forward service/hallo 8080:80              # im zweiten Terminal: curl http://127.0.0.1:8080/
```

Erwartet: `Hallo von GKE von Pod ..., Version 2.0`.

Öffnet in der Konsole Kubernetes Engine, dann Workloads. Findet euer Deployment über den Namespace. Vergleicht Pod-Namen, Image, Ereignisse und Logs mit der CLI. Sucht danach den Service.

### 5. Kontext wechseln

Was passiert: Ihr springt zwischen minikube und GKE. Derselbe Befehl zeigt je nach Kontext einen anderen Cluster.

```bash
kubectl config use-context minikube
kubectl get pods                                  # euer lokaler Cluster
kubectl config use-context "$WORKSHOP_CONTEXT"
kubectl get pods                                  # GKE, euer Namespace
```

Erwartet: zwei verschiedene Pod-Listen.

```text
kubeconfig
  +-- minikube                              -> lokaler Cluster
  +-- gke_lookbeyond-gke-workshop_..._workshop -> GKE
        (Kontext = Cluster + Benutzer + Standard-Namespace)
```

> **Hintergrund:** Ein Kontext ist ein Verbindungsprofil, kein Recht. Wer den falschen Kontext aktiv hat, ändert den falschen Cluster. Deshalb vor jedem `apply` und `delete`: `kubectl config current-context`.

## Checkpoint

```bash
kubectl config use-context "$WORKSHOP_CONTEXT"
python3 scripts/pruefen.py gke
```

Erwartet: `Ergebnis: 0 Pruefung(en) fehlgeschlagen`.

**Abgabe:** Pod-Liste aus GKE, HTTP-Antwort und ein übereinstimmender Pod-Name aus der Konsole.

## Extra zum Ausprobieren

Für alle, die mit dem Kern fertig sind. Jedes Extra bleibt in eurem Namespace und räumt am Ende selbst auf.

### Extra 1: Einen Fehler im Logs Explorer finden

Das bereitet Tag 3 vor. Lasst den Tunnel aus Schritt 4 laufen und erzeugt im zweiten Terminal einen Fehler:

```bash
curl -i http://127.0.0.1:8080/fehler              # HTTP 500 ist hier gewollt
kubectl logs -l app=hallo --prefix --tail=50      # Zeile mit FEHLER
```

Sucht dieselbe Zeile in der Konsole unter Logging, Logs Explorer, mit euren Werten:

```text
resource.type="k8s_container"
resource.labels.project_id="EURE_PROJECT_ID"
resource.labels.cluster_name="EUER_CLUSTER_NAME"
resource.labels.namespace_name="EUER_NAMESPACE"
resource.labels.container_name="hallo"
textPayload:"FEHLER"
```

Wählt ein aktuelles Zeitfenster und gebt der Übertragung etwas Zeit. Ohne die letzte Zeile seht ihr alle Logs der Anwendung. Im Monitoring findet ihr CPU, Speicher und `kubernetes.io/container/restart_count`. Die Fehlerroute erzeugt keinen Neustart.

### Extra 2: Was darf ich?

```bash
kubectl auth can-i create deployments                     # in eurem Namespace
kubectl auth can-i get secrets
kubectl auth can-i create deployments -n kube-system      # im Systembereich
kubectl auth can-i list nodes                             # clusterweit
kubectl auth can-i --list                                 # alles, was ihr hier duerft
```

Welche Antworten sind `yes`, welche `no`? Woher kommt der Unterschied?

### Extra 3: Replikas auf Nodes verteilen

Ohne Regel können alle Replikas auf einem Node landen. [extra/spread.yaml](extra/spread.yaml) verlangt mit `topologySpreadConstraints` eine Verteilung über die Nodes.

```bash
python3 scripts/render.py lab04-gke/extra --image "$IMAGE" --output out/lab04-extra
kubectl apply -f out/lab04-extra/
kubectl rollout status deployment/hallo-spread --timeout=600s
kubectl get pods -l app=hallo-spread -o wide      # Spalte NODE
```

Landen die drei Pods auf drei verschiedenen Nodes? Vergleicht mit der Spalte `NODE` eures Deployments `hallo`.

Aufräumen: `kubectl delete -f out/lab04-extra/`. Bitte gleich danach, die Nodes teilen sich alle.

### Extra 4: Von außen per Gateway erreichbar

Bisher erreicht ihr die Anwendung nur über `port-forward`. Der Trainer hat einen gemeinsamen Eingang angelegt: ein Gateway mit einer öffentlichen Adresse. Ihr hängt mit einer `HTTPRoute` euren Service daran. Jede Person bekommt einen eigenen Pfad, alle teilen sich die Adresse.

```text
curl -> GATEWAY_IP/workshop-person01/ -> Gateway (Load Balancer von Google)
     -> HTTPRoute in eurem Namespace -> Service hallo:80 -> Pods :8080
```

[gateway/httproute.yaml](gateway/httproute.yaml) verbindet Pfad und Service. Setzt euren Namespace ein und rollt die Route aus:

```bash
export GATEWAY_IP=ADRESSE_VOM_TRAINER
sed "s/workshop-person01/$WORKSHOP_NAMESPACE/g" lab04-gke/gateway/httproute.yaml > out/lab04-route.yaml
kubectl apply -f out/lab04-route.yaml
kubectl describe httproute hallo                  # Conditions: Accepted und ResolvedRefs
curl "http://$GATEWAY_IP/$WORKSHOP_NAMESPACE/"
curl -i "http://$GATEWAY_IP/$WORKSHOP_NAMESPACE/fehler"
```

Erwartet: `Hallo von GKE von Pod ...`. Mehrmals aufrufen: Der Pod-Name wechselt. Bis der Load Balancer eure Route kennt, dauert es einige Minuten (im Test etwa vier). Bis dahin kommt `404`. Wartet und wiederholt den Aufruf.

Fragt eure Nachbarn nach ihrem Pfad und ruft deren Anwendung auf. Was passiert mit eurer Route, wenn ihr den Service `hallo` löscht?

Aufräumen: `kubectl delete -f out/lab04-route.yaml`. Die Adresse ist öffentlich, die Route bleibt nicht über Nacht stehen.

## Aufräumen und Fallback

```bash
kubectl config current-context    # erwartet: gke_...
kubectl delete -f out/lab04/
```

Den Namespace und die Registry verwaltet der Trainer. Für Tag 3 könnt ihr das Deployment nach Absprache stehen lassen. Vor Lab 5 wird es entfernt.

Ohne Cloud: Der Trainer zeigt Konsole und Registry. Ihr setzt Kontext und Namespace auf `minikube`/`workshop`, verwendet `IMAGE=hallo-app:2.0` und ladet das Image mit `minikube image load hallo-app:2.0`. Dann rendert ihr in einen neuen Ausgabeordner und übt Deployment, Checkpoint und Fehlersuche lokal. Cloud Logging, Monitoring und Cloud-Rechte bleiben eine Demo.

## Für den Trainer

**So erklärt ihr es:**

- Artifact Registry ist für GKE, was `minikube image load` lokal war: der Ort, von dem der Cluster das Image holt.
- Dieselben Manifeste wie lokal. Wer Lab 2 verstanden hat, versteht Lab 4. Neu sind nur Anmeldung, Registry und Konsole.
- Kontext wie ein Lesezeichen im Browser: Es führt zu einem Cluster, gibt aber keine Rechte.
- Google betreibt die Control Plane. Ihr seht sie nicht als Pods, ihr sprecht nur mit dem API-Server.

**Häufige Fragen:**

- *Ist ein Kontext ein Recht?* Nein. Er wählt Cluster, Benutzer und Namespace. Was ihr dürft, entscheiden IAM und RBAC.
- *Wechsle ich mit dem Namespace den Node?* Nein. Nodes gehören zu keinem Namespace. Pods aus verschiedenen Namespaces teilen sich die Nodes.
- *Läuft der Traffic meiner Nutzer über kubectl?* Nein. `kubectl` und `port-forward` sind nur für euch. Nutzer kommen über Load Balancer oder Ingress zum Service.
- *Warum GKE statt Cloud Run?* GKE gibt mehr Kontrolle über Nodes, Netz und komplexe Anwendungen, dafür mehr Betrieb. Für eine einfache zustandslose API ist Cloud Run oft einfacher.
- *Füllt der Scheduler erst Node 1, dann Node 2?* Nein, das ist nicht garantiert. Verteilen erzwingt man mit `topologySpreadConstraints`, siehe Extra 3.

**Nur nennen, nicht erklären:** DNS-Endpunkt, Auth-Plugin, `--platform`, was `render.py` intern tut, Autopilot-Details, die Rollen hinter `get-credentials`.

**Wenn es hakt:**

- `ImagePullBackOff`: Image-Pfad in `out/lab04/deployment.yaml` mit `echo "$IMAGE"` vergleichen, Push wirklich mit Digest beendet, Architektur `amd64`.
- `Forbidden` oder falsche Pods: falscher Kontext oder Namespace. `kubectl config get-contexts` zeigt beides.
- `render.py` meldet, dass Dateien existieren: neuen Ausgabeordner wählen, etwa `out/lab04-2`.

**Kapazität für Extra 3:** Das Deployment `hallo-spread` fordert je Pod nur `10m` CPU und `384Mi` Speicher an. 15 Personen mit je drei Pods passen rechnerisch neben Lab 4 auf drei `e2-standard-4`, aber ohne viel Reserve. Lasst es trotzdem nicht stehen.

**Vorbereitung Extra 4:** Gateway API im Cluster aktiv, [trainer/gateway.yaml](../trainer/gateway.yaml) angewendet, RBAC mit `httproutes`. Die Adresse steht in `kubectl -n workshop-gateway get gateway workshop`. Nur Namespaces mit dem Label `workshop=gke-einfuehrung` dürfen Routen anhängen. Das Gateway braucht beim Anlegen 5 bis 10 Minuten bis zur ersten Antwort, also vor dem Lab anlegen. Eine neue Route braucht etwa vier Minuten. Das Gateway am Abend löschen.

**Lösung Extra 4:** Die Route bleibt nach dem Löschen des Service bestehen, meldet aber `ResolvedRefs: False` mit Grund `BackendNotFound`, und `curl` liefert nach einigen Minuten `500`. Gateway, Route und Service sind getrennte Objekte, verbunden nur über Namen.

**Lösung Extra 2:** `yes` für Deployments und Secrets im eigenen Namespace, `no` für `kube-system` und für Nodes. Die Role `workshop-entwickler` gilt nur im eigenen Namespace und enthält keine clusterweiten Objekte.
