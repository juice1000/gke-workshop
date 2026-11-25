# Lab 4: hallo-app auf GKE

**Ziel:** Ihr ladet ein Image in Artifact Registry, deployt es auf euren eigenen GKE-Cluster und findet dieselben Objekte in der Konsole. Dauer: 60 Minuten. **Voraussetzung:** Projekt, Cluster und Registry aus [SELBST-WEITERMACHEN.md](../SELBST-WEITERMACHEN.md).

Alle Befehle aus dem Repository-Hauptordner in Bash. Docker und gcloud laufen in derselben Umgebung, unter Windows also in WSL.

## Das Minimum

- Lokal kopiert ihr das Image mit `minikube image load` in den Cluster. In der Cloud ladet ihr es in Artifact Registry hoch, und der GKE-Node holt es dort ab.
- Die Manifeste sind dieselben wie lokal. Nur der Image-Pfad ändert sich.
- Ein Kontext ist Cluster plus Benutzer plus Standard-Namespace. Vor jeder Änderung prüft ihr ihn.
- Die Konsole zeigt dieselben Objekte wie `kubectl`. Beides liest beim selben API-Server.

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

Was passiert: `gcloud` schreibt einen Kontext für euren Cluster in die kubeconfig. Dann legt ihr den Namespace `workshop` an und macht ihn zum Standard.

```bash
export PROJECT_ID=EURE_PROJEKT_ID
export REGION=europe-west3
export ZONE=europe-west3-b

gcloud container clusters get-credentials workshop --zone "$ZONE" --project "$PROJECT_ID"
kubectl create namespace workshop
kubectl config set-context --current --namespace=workshop
kubectl config get-contexts                        # * markiert den aktuellen Kontext
bash lab00-check/check.sh cloud
```

Erwartet: ein Kontext `gke_...` mit Namespace `workshop`, und `check.sh cloud` ohne Fehler.

Diese drei `export`-Zeilen und `IMAGE` aus Schritt 2 braucht ihr in jedem neuen Terminal, auch in Lab 5 und 6.

### 2. Image bauen und hochladen

```bash
export IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/workshop/hallo-app:2.0"
docker build --platform linux/amd64 --build-arg APP_VERSION=2.0 -t "$IMAGE" lab02-hallo-app
docker push "$IMAGE"
gcloud artifacts docker images list "$REGION-docker.pkg.dev/$PROJECT_ID/workshop" --include-tags
```

Erwartet: Der Push endet mit `digest: sha256:...`, die Liste zeigt das Image mit Tag `2.0`. Findet es danach in der Konsole unter Artifact Registry.

**Gut zu wissen:** `--platform linux/amd64` baut für die Prozessorarchitektur der GKE-Nodes. Auf einem Mac mit Apple-Chip wäre das Image sonst ARM und liefe auf den Nodes nicht.

### 3. Ausrollen

In [k8s/deployment.yaml](k8s/deployment.yaml) steht statt eines Images der Platzhalter `WORKSHOP_IMAGE`. `sed` setzt euer Image ein und gibt das Ergebnis direkt an `kubectl`. Die Dateien im Repository bleiben unverändert.

```bash
sed "s#WORKSHOP_IMAGE#$IMAGE#" lab04-gke/k8s/*.yaml        # nur ansehen
sed "s#WORKSHOP_IMAGE#$IMAGE#" lab04-gke/k8s/*.yaml | kubectl apply -f -
kubectl rollout status deployment/hallo --timeout=600s
kubectl get pods -o wide                                     # NODE zeigt, wo die Pods laufen
```

Erwartet: zwei Pods `Running` mit `1/1`.

**Gut zu wissen:** `kubectl apply -f -` liest die Manifeste von der Standardeingabe. Jede Datei beginnt mit `---`, deshalb trennt `kubectl` die aneinandergehängten Dateien sauber.

### 4. CLI und Konsole vergleichen

```bash
kubectl describe deployment hallo                       # Image, Replikas, Events
kubectl logs -l app=hallo --prefix --tail=30            # Logs beider Pods
kubectl get events --sort-by=.lastTimestamp
kubectl port-forward service/hallo 8080:80              # im zweiten Terminal: curl http://127.0.0.1:8080/
```

Erwartet: `Hallo von GKE von Pod ..., Version 2.0`.

Öffnet in der Konsole Kubernetes Engine, dann Workloads. Vergleicht Pod-Namen, Image, Ereignisse und Logs mit der CLI. Ändert dann etwas und aktualisiert die Seite nach jedem Befehl:

```bash
kubectl delete pod -l app=hallo --wait=false   # neue Pod-Namen, Ereignisse zum Ersatz
kubectl scale deployment/hallo --replicas=3    # drei Pods, Ereignis ScalingReplicaSet
kubectl scale deployment/hallo --replicas=2    # zurück auf den Stand der Datei
```

### 5. Kontext wechseln

```bash
kubectl config use-context minikube
kubectl get pods                                  # euer lokaler Cluster
kubectl config use-context gke_${PROJECT_ID}_${ZONE}_workshop
kubectl get pods                                  # GKE
```

Erwartet: zwei verschiedene Pod-Listen. Ein Kontext ist ein Verbindungsprofil. Wer den falschen aktiv hat, ändert den falschen Cluster. Deshalb vor jedem `apply` und `delete`: `kubectl config current-context`.

## Checkpoint

```bash
python3 scripts/pruefen.py gke
```

Erwartet: `Ergebnis: 0 Pruefung(en) fehlgeschlagen`.

## Extra zum Ausprobieren

### Extra 1: Einen Fehler im Logs Explorer finden

Lasst den Tunnel aus Schritt 4 laufen und erzeugt im zweiten Terminal einen Fehler:

```bash
curl -i http://127.0.0.1:8080/fehler              # HTTP 500 ist hier gewollt
```

Sucht die Zeile in der Konsole unter Logging, Logs Explorer:

```text
resource.type="k8s_container"
resource.labels.namespace_name="workshop"
resource.labels.container_name="hallo"
severity>=ERROR
```

Gebt der Übertragung etwa eine Minute. Im Monitoring findet ihr CPU, Speicher und `kubernetes.io/container/restart_count`.

### Extra 2: Replikas auf Nodes verteilen

Ohne Regel können alle Replikas auf einem Node landen. [extra/spread.yaml](extra/spread.yaml) verlangt mit `topologySpreadConstraints` eine Verteilung über die Nodes.

```bash
sed "s#WORKSHOP_IMAGE#$IMAGE#" lab04-gke/extra/spread.yaml | kubectl apply -f -
kubectl rollout status deployment/hallo-spread --timeout=600s
kubectl get pods -l app=hallo-spread -o wide      # Spalte NODE
kubectl delete deployment hallo-spread
```

### Extra 3: Von außen erreichbar

Bisher erreicht ihr die Anwendung nur über `port-forward`. Ein Service vom Typ `LoadBalancer` bekommt von Google eine öffentliche IP:

```bash
kubectl expose deployment hallo --name=hallo-extern --type=LoadBalancer --port=80 --target-port=8080
kubectl get service hallo-extern -w               # warten, bis EXTERNAL-IP eine Adresse zeigt
curl http://EXTERNAL-IP/
kubectl delete service hallo-extern               # kostet Geld, solange er steht
```

Mehrmals aufrufen: Der Pod-Name wechselt. Findet den Load Balancer in der Konsole unter Netzwerkdienste.

## Aufräumen

```bash
kubectl config current-context    # erwartet: gke_...
sed "s#WORKSHOP_IMAGE#$IMAGE#" lab04-gke/k8s/*.yaml | kubectl delete -f -
```

Für Lab 5 könnt ihr das Deployment stehen lassen. `stoerung.sh start` ersetzt es.

## Fragen und Antworten

- *Ist ein Kontext ein Recht?* Nein. Er wählt Cluster, Benutzer und Namespace. Was ihr dürft, entscheiden IAM und RBAC (Lab 6, Etappe C).
- *Wechsle ich mit dem Namespace den Node?* Nein. Nodes gehören zu keinem Namespace.
- *Läuft der Traffic meiner Nutzer über kubectl?* Nein. `kubectl` und `port-forward` sind nur für euch. Nutzer kommen über Load Balancer oder Ingress zum Service.
- *Warum GKE statt Cloud Run?* GKE gibt mehr Kontrolle über Nodes, Netz und komplexe Anwendungen, dafür mehr Betrieb. Für eine einfache zustandslose API ist Cloud Run oft einfacher.

**Wenn es hakt:**

- `ImagePullBackOff`: `echo "$IMAGE"` mit `kubectl describe pod` vergleichen. Push mit Digest beendet? Architektur `amd64`? Leserecht der Nodes auf die Registry, siehe [SELBST-WEITERMACHEN.md](../SELBST-WEITERMACHEN.md).
- Falsche Pods oder `NotFound`: falscher Kontext oder Namespace. `kubectl config get-contexts` zeigt beides.
