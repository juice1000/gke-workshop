# Lab 4: hallo-app auf GKE

**Ziel:** Ihr ladet ein Image in Artifact Registry, deployt es auf GKE und findet dieselben Objekte in der Konsole. Dauer: 60 Minuten. Voraussetzung: [Cloud-Vorbereitung durch den Trainer](../trainer/README.md). Ihr erstellt keinen Cluster.

Alle Befehle aus dem Repository-Hauptordner in Bash. Docker und gcloud laufen in derselben Umgebung, unter Windows also in WSL.

## 1. Zugang und Ziel festlegen

Übernehmt die Werte vom Trainer. `REGION` bezeichnet den Standort der Registry. `LOCATION` ist Region oder Zone des Clusters; beides muss nicht identisch sein.

```bash
export PROJECT_ID=PROJEKT_VOM_TRAINER
export REGION=REGISTRY_REGION_VOM_TRAINER
export REPOSITORY=REPOSITORY_VOM_TRAINER
export CLUSTER_NAME=CLUSTER_VOM_TRAINER
export LOCATION=CLUSTER_STANDORT_VOM_TRAINER
export WORKSHOP_NAMESPACE=workshop-person01

gcloud auth login
gke-gcloud-auth-plugin --version
gcloud container clusters get-credentials "$CLUSTER_NAME" \
  --location "$LOCATION" --project "$PROJECT_ID" --dns-endpoint
export WORKSHOP_CONTEXT="$(kubectl config current-context)"
kubectl config set-context "$WORKSHOP_CONTEXT" --namespace="$WORKSHOP_NAMESPACE"
kubectl config get-contexts
bash lab00-check/check.sh cloud
```

Erwartet: ein `gke_...`-Kontext und euer zugewiesener Namespace. Die vorbereitete Trainerumgebung verwendet einen DNS-Endpunkt mit Google-Authentifizierung. Falls ein anderer Übungscluster ausschließlich private IP-Endpunkte bereitstellt, nennt der Trainer den passenden VPN-/Zugangsweg und die angepassten Verbindungsoptionen. Ein erfolgreicher Login allein garantiert noch keinen Netzwerkzugang.

## 2. Image bauen und hochladen

Jede Gruppe bekommt einen eigenen Image-Namen. So überschreibt ihr beim gemeinsamen Repository keine fremden Tags.

```bash
export IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY/hallo-app-$WORKSHOP_NAMESPACE:2.0"
gcloud auth configure-docker "$REGION-docker.pkg.dev"

# Fuer einen GKE-Node mit amd64. Bei ARM-Nodes den Wert laut Trainer anpassen.
docker build --platform linux/amd64 --build-arg APP_VERSION=2.0 \
  -t "$IMAGE" lab02-hallo-app
docker push "$IMAGE"
```

Erwartet: Der Push endet mit einem Digest.

**Aufgabe: Push prüfen.** Zeigt mit `gcloud` alle Images im Repository `$REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY` an und findet euer eigenes mit Tag und Digest. Startet bei `gcloud artifacts --help` und folgt den Unterbefehlen bis zu den Docker-Images. Mit `--include-tags` seht ihr die Tags. Findet danach dasselbe Image in der Konsole unter Artifact Registry.

Hintergrund: Auf einem ARM-Laptop ist ein normales lokales Image meist ebenfalls ARM. Einfaches Taggen genügt dann nicht für einen amd64-Node. Deshalb legt der Build hier die Zielplattform fest. Der Maven-Build läuft auf der nativen Laptop-Plattform und kopiert das portable Java-Archiv in das Laufzeitimage der Zielplattform. Für diesen Build ist keine x86-Emulation auf dem ARM-Laptop nötig.

Push und Pull sind getrennte Rechte: Euer Konto lädt hoch. Die Node-Identität des Clusters lädt das private Image herunter. Workload Identity Federation ist für Anwendungszugriffe auf Cloud-APIs gedacht und ersetzt diese Image-Pull-Berechtigung nicht.

## 3. Manifeste vorbereiten und ausrollen

Lest die drei Dateien unter [k8s/](k8s/). Der Image-Platzhalter wird zunächst nur in eine Arbeitskopie ersetzt:

```bash
python3 scripts/render.py lab04-gke/k8s --image "$IMAGE" --output out/lab04
kubectl config current-context
kubectl apply -f out/lab04/
kubectl rollout status deployment/hallo --timeout=600s
kubectl get pods -o wide
python3 scripts/pruefen.py gke
```

`render.py` ändert keinen Cluster und überschreibt keine vorhandene Arbeitskopie. Für einen zweiten Versuch mit neuem Ausgabeordner arbeiten, etwa `out/lab04-2`. Wendet die Vorlage mit `WORKSHOP_IMAGE` nicht direkt an.

Erwartet: zwei bereite Pods. Der erste Start auf Autopilot kann länger dauern, wenn neue Nodes bereitgestellt werden. Deshalb haben die Cloud-Manifeste ein Fortschrittsbudget von zehn Minuten. Bei `ImagePullBackOff` prüft ihr Image-Pfad, Architektur und Pull-Rechte. Bei `CreateContainerConfigError` prüft ihr, ob ihr auch die ConfigMap angewendet habt.

## 4. CLI und Konsole vergleichen

```bash
kubectl describe deployment hallo
kubectl logs -l app=hallo --prefix --tail=30
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl port-forward service/hallo 8080:80
```

Im zweiten Terminal `curl http://127.0.0.1:8080/`. Erwartet: `Hallo von GKE von Pod ..., Version 2.0`.

Öffnet im Projekt den Bereich Kubernetes Engine. Findet unter den Workloads euer Deployment anhand des Namespaces. Vergleicht Pod-Namen, Image, Ereignisse und Logs mit der CLI. Sucht danach den Service. Die genaue Anordnung der Konsole kann sich ändern.

**Abgabe:** Pod-Liste aus GKE, HTTP-Antwort und ein übereinstimmender Pod-Name aus der Konsole.

## 5. Kontextwechsel

```bash
kubectl config use-context minikube
kubectl get pods
kubectl config use-context "$WORKSHOP_CONTEXT"
kubectl get pods
```

Welche Pods seht ihr jeweils? Der Namespace ist Teil eines Kontexts. Vor Änderungen immer Kontext und Namespace prüfen.

## 6. Beobachtung für Tag 3

Lasst den Tunnel laufen und erzeugt im zweiten Terminal einen Fehler:

```bash
curl -i http://127.0.0.1:8080/fehler
kubectl logs -l app=hallo --prefix --tail=50
```

HTTP 500 ist hier gewünscht. Die Anwendung bleibt gesund. Sucht im Logs Explorer mit euren Werten:

```text
resource.type="k8s_container"
resource.labels.project_id="EURE_PROJECT_ID"
resource.labels.cluster_name="EUER_CLUSTER_NAME"
resource.labels.namespace_name="EUER_NAMESPACE"
resource.labels.container_name="hallo"
textPayload:"FEHLER"
```

Wählt ein aktuelles Zeitfenster und gebt der Übertragung etwas Zeit. Entfernt die letzte Zeile, um alle Anwendungslogs zu sehen. Im Monitoring untersucht ihr CPU, Speicher und die Metrik `kubernetes.io/container/restart_count`. Die Fehlerroute erzeugt keinen Neustart. Eine fehlende Metrik ist nicht automatisch der Wert null; prüft Zeitraum, Erfassung und Rechte.

## Aufräumen und Fallback

```bash
kubectl config current-context
kubectl delete -f out/lab04/
```

Den Namespace und die Registry verwaltet der Trainer. Für Tag 3 könnt ihr das Deployment nach Absprache stehen lassen. Vor Lab 5 wird es entfernt.

Ohne Cloud: Der Trainer zeigt Konsole und Registry. Ihr setzt Kontext und Namespace auf `minikube`/`workshop`, verwendet `IMAGE=hallo-app:2.0` und ladet das Image mit `minikube image load hallo-app:2.0`. Dann rendert ihr in einen neuen Ausgabeordner und übt Deployment, Checkpoint und Fehlersuche lokal. Cloud Logging, Monitoring und Cloud-Rechte bleiben eine Demo.
