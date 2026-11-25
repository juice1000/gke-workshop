# Runbook: Cloud-Umgebung Schritt fuer Schritt

Ergaenzt [README.md](README.md) (Zugriffsmodell, Probelauf, Aufraeumen) um eine Befehlsfolge zum Abarbeiten. Alles wird vom Trainer von Hand ausgefuehrt. Das Repository legt nichts automatisch an. Jeder Abschnitt endet mit einer Pruefung.

Die Trainerumgebung wird im Projekt `lookbeyond-gke-workshop` in Frankfurt aufgebaut. Der tatsaechliche Laufzeitnachweis steht im [Teststatus](../docs/07-teststatus.md). Die Erstellungsbefehle sind fuer den initialen Aufbau gedacht. Vor einem erneuten Lauf vorhandene Ressourcen pruefen und wiederverwenden.

## Lokale Trainerumgebung

Auf dem vorbereiteten Mac liegen minikube 1.39.0 und kubectl 1.35.0 in `.cache/bin`. Das GKE-Auth-Plugin ist im vorhandenen Google Cloud SDK installiert. Diese lokalen Dateien, Clusterdaten und Zugangsdaten werden nicht eingecheckt.

Aus dem Repository-Hauptordner in jedem neuen Terminal:

```bash
source scripts/workshop-env.sh
kubectl config get-contexts
minikube -p minikube status
```

Das Skript verwendet `.cache/workshop.kubeconfig`, den minikube-Datenordner `.cache/minikube-home` und die eigene gcloud-Konfiguration `gke-workshop`. Die global aktive gcloud-Konfiguration bleibt erhalten. Den Workshop-Account vor Cloud-Befehlen mit `gcloud config get-value account` pruefen.

Cloud-Metadaten liegen lokal in `.cache/workshop-cloud.env`. Nach dem Laden wechselt `workshop_gke` zum Trainer-Namespace auf GKE. `workshop_local` wechselt zurueck zu minikube. Beide Funktionen setzen die Checkpoint-Variablen passend zum Kontext. Mit `workshop_gke workshop-person01` kann ein anderer vorbereiteter Namespace gewaehlt werden.

Der persistente lokale Cluster verwendet 2 CPUs und 4096 MiB RAM. Der Namespace heisst `workshop`. Ein Kontextwechsel zur lokalen Umgebung geht nach dem Laden des Skripts mit `workshop_local`.

```bash
minikube start -p minikube --driver=docker --cpus=2 --memory=4096 --nodes=1 --kubernetes-version=v1.35.0
workshop_local
kubectl get pods -n workshop
kubectl port-forward -n workshop service/hallo 18081:80
```

Im zweiten Terminal `curl http://127.0.0.1:18081/`. Port 8080 ist auf diesem Mac bereits durch die IaC-Beispielanwendung belegt. Fuer GKE wird deshalb Port 18080 verwendet:

```bash
workshop_gke
kubectl port-forward service/hallo 18080:80
```

Dann `http://127.0.0.1:18080/` oeffnen. Beide Tunnel koennen in getrennten Terminals laufen. Mit Strg+C den jeweiligen Tunnel beenden. Nach der Arbeit kann der lokale Cluster mit `minikube stop -p minikube` angehalten und mit dem Startbefehl fortgesetzt werden. Der Trainer-Probelauf `scripts/dry-run.sh` verwendet weiterhin ein eigenes temporaeres Profil.

Auf einem anderen Rechner zuerst minikube und kubectl installieren, das GKE-Auth-Plugin einrichten und die gcloud-Konfiguration erstellen:

```bash
gcloud config configurations create gke-workshop --no-activate
gcloud config set account EIGENES_GOOGLE_KONTO --configuration=gke-workshop
gcloud auth login EIGENES_GOOGLE_KONTO --no-activate
```

Anschliessend die lokale Umgebung aus Lab 0 aufbauen. Die folgenden Cloud-Befehle erst mit dem richtigen Workshop-Account und einem Projekt mit aktiver Abrechnung ausfuehren.

## 0. Variablen

Nur im aktuellen Terminal gueltig. Werte anpassen.

```bash
source scripts/workshop-env.sh
export PROJECT_ID="lookbeyond-gke-workshop"
export BILLING_ACCOUNT="XXXXXX-XXXXXX-XXXXXX"   # gcloud billing accounts list
export REGION="europe-west3"
export ZONE="europe-west3-b"
export CLUSTER="workshop"
export REPO="workshop"
export NODE_SA="gke-workshop-nodes@${PROJECT_ID}.iam.gserviceaccount.com"
export TRAINER_CONTEXT="gke_${PROJECT_ID}_${ZONE}_${CLUSTER}"   # Standard, zonal
# Autopilot: Standort ist die Region, also gke_${PROJECT_ID}_${REGION}_${CLUSTER}
```

## 1. Projekt und APIs

```bash
gcloud auth login "$(gcloud config get-value account)" --no-activate
gcloud components install gke-gcloud-auth-plugin
gcloud projects create "$PROJECT_ID"
gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT"
gcloud services enable compute.googleapis.com container.googleapis.com artifactregistry.googleapis.com \
  logging.googleapis.com monitoring.googleapis.com iam.googleapis.com iamcredentials.googleapis.com \
  --project="$PROJECT_ID"
```

Pruefen: `gcloud services list --enabled --project="$PROJECT_ID"` zeigt die angeforderten APIs. Budget-Alert in der Konsole unter Billing anlegen.

## 2. Netzwerk und Node-Identitaet

Ein eigenes VPC-Netz verwendet getrennte Bereiche fuer Nodes, Pods und Services. Fuer Nodes wird ein eigenes Servicekonto ohne Schluesseldateien verwendet.

```bash
gcloud compute networks create gke-workshop --subnet-mode=custom --bgp-routing-mode=regional \
  --project="$PROJECT_ID"
gcloud compute networks subnets create gke-workshop --network=gke-workshop --region="$REGION" \
  --range=10.60.0.0/20 --secondary-range=pods=10.64.0.0/16,services=10.65.0.0/20 \
  --enable-private-ip-google-access --project="$PROJECT_ID"
gcloud iam service-accounts create gke-workshop-nodes --display-name='GKE Workshop Nodes' \
  --project="$PROJECT_ID"
gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:${NODE_SA}" \
  --role=roles/container.defaultNodeServiceAccount --condition=None
```

Pruefen: Subnetz und Sekundaerbereiche mit `gcloud compute networks subnets describe gke-workshop --region="$REGION" --project="$PROJECT_ID"` ansehen. Keine allgemeinen SSH-/RDP-Freigaben anlegen. Die fuer Kubernetes erforderlichen Firewall-Regeln legt GKE beim Clusteraufbau an.

## 3. Cluster (Variante Standard)

Der Vorbereitungscluster startet mit einem Node `e2-standard-2` und 30 GB Standard-Persistent-Disk. Die Groesse vor dem Kurs an die Zahl gleichzeitig arbeitender Gruppen anpassen, Kapazitaet je Rollout siehe [README](README.md), Punkt 6. Die Nodezahl ist fest, Cluster-Autoscaling ist nicht aktiviert.

```bash
gcloud container clusters create "$CLUSTER" \
  --location="$ZONE" --6.3-bereitschafthannel=regular --cluster-version=1.36.4-gke.2377000 \
  --num-nodes=1 --machine-type=e2-standard-2 --disk-size=30 --disk-type=pd-standard \
  --image-type=COS_CONTAINERD --network=gke-workshop --subnetwork=gke-workshop \
  --enable-ip-alias --cluster-secondary-range-name=pods --services-secondary-range-name=services \
  --max-pods-per-node=32 --service-account="$NODE_SA" --scopes=cloud-platform \
  --workload-pool="${PROJECT_ID}.svc.id.goog" --workload-metadata=GKE_METADATA \
  --enable-dns-access --no-enable-ip-access --no-enable-basic-auth --no-issue-client-certificate \
  --enable-shielded-nodes --shielded-secure-boot --shielded-integrity-monitoring \
  --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM --no-enable-managed-prometheus \
  --maintenance-window=02:00 --labels=purpose=gke-workshop,managed-by=gcloud \
  --project="$PROJECT_ID"
gcloud container clusters get-credentials "$CLUSTER" \
  --location="$ZONE" --project="$PROJECT_ID" --dns-endpoint
kubectl config get-contexts
kubectl --context "$TRAINER_CONTEXT" get nodes
```

Die hier angegebene Version war im Regular Channel verfuegbar. Vor einem spaeteren Neuaufbau mit `gcloud container get-server-config --location="$ZONE" --project="$PROJECT_ID"` erneut pruefen. Auto-Upgrades und Auto-Repair sind aktiv. Das Wartungsfenster beginnt um 02:00 UTC und dauert vier Stunden.

Der API-Zugriff erfolgt ueber den DNS-Endpunkt mit Google-Identitaet. IP-basierte API-Endpunkte sind deaktiviert. Die Nodes verwenden fuer ausgehende Verbindungen externe IPs; es gibt keinen Cloud NAT und keine oeffentlichen Anwendungsservices. Normale Anwendungs-Pods verwenden die GKE-Metadatenidentitaet statt der Node-Identitaet.

Die CLI verlangt `--shielded-secure-boot` und `--shielded-integrity-monitoring` gemeinsam. System- und Workload-Logs sowie Systemmetriken sind aktiviert. Managed Prometheus ist fuer diese Grundlagenumgebung deaktiviert.

Variante Autopilot (nicht angelegt, eigener Probelauf noetig):

```bash
gcloud container clusters create-auto "$CLUSTER" --location="$REGION" --project="$PROJECT_ID"
```

Pruefen: Nodes `Ready`. Kubernetes-Version und Node-Architektur notieren (`kubectl --context "$TRAINER_CONTEXT" get nodes -o wide`), das vorgebaute Image muss dazu passen.

### Kurs-Node-Pool (umgesetzt am 21.11.2026)

Fuer 15 Teilnehmende wurde `default-pool` durch den Pool `kurs` ersetzt. Grundlage: je Person zwei Pods mit 250m CPU und 512 MiB Request, bei einem Rollout ein dritter. Das ergibt 7,5 vCPU im Normalbetrieb und bis zu 11,25 vCPU, wenn alle gleichzeitig ausrollen. Das globale CPU-Kontingent des Projekts betraegt 12 vCPU (`CPUS_ALL_REGIONS`). Drei `e2-standard-4` nutzen es voll aus und lassen nach Abzug der Systempods etwa 10 vCPU fuer Workloads. Ein vierter Node braucht eine Kontingenterhoehung in der Konsole unter IAM, Kontingente.

Am 25.11.2026 lehnte Google Antraege auf 20 und 16 vCPU automatisch ab (junges Rechnungskonto). Deshalb fordern die Tag-3-Labs (Lab 5 und Lab 6) nur 100m CPU pro `hallo`-Pod an. Es gibt kein CPU-Limit, die Pods nutzen freie CPU weiter. Spitzenbedarf mit 17 Namespaces bei gleichzeitigen Rollouts: etwa 3 x 100m + 10m pro Namespace, rund 5,3 vCPU plus Systempods, statt 13,6 vCPU mit 250m. Lab 2 bis 4 und die Tag-2-Demos behalten 250m.

Seit 25.11.2026 hat jeder Kurs-Namespace ein Kontingent ([kontingent.yaml](einrichtung/kontingent.yaml), `teilnehmer-anlegen.sh` wendet es an): hoechstens 4 CPU und 8 GiB Speicher als Requests, 20 Pods, kein eigener `LoadBalancer`. Das ist ein Sicherheitsnetz gegen Versehen wie `kubectl scale --replicas=50`, keine Uebung kommt in die Naehe (die groesste braucht etwa 1 CPU). Keine Uebung darf am Kontingent scheitern; eine neue Uebung mit mehr Bedarf hebt die Grenze an, und externe Adressen (`IN_USE_ADDRESSES`, 8 in `europe-west3`) bleiben frei. Ein Pod ohne `resources` bekommt 100m CPU und 256 MiB als Request, aber kein Limit. Ueberschreitungen erscheinen als Event `FailedCreate ... exceeded quota` am ReplicaSet, nicht als `Pending`. Pruefen: `kubectl -n workshop-personNN describe resourcequota kurs`.

```bash
gcloud container node-pools create kurs \
  --cluster="$CLUSTER" --location="$ZONE" --project="$PROJECT_ID" \
  --machine-type=e2-standard-4 --num-nodes=1 --disk-size=50 --disk-type=pd-balanced \
  --image-type=COS_CONTAINERD --service-account="$NODE_SA" \
  --scopes=cloud-platform --workload-metadata=GKE_METADATA --max-pods-per-node=32 \
  --shielded-secure-boot --shielded-integrity-monitoring --enable-autorepair --enable-autoupgrade \
  --node-labels=workshop-pool=kurs
# Danach den alten Node sperren, leeren und den alten Pool loeschen.
kubectl --context "$TRAINER_CONTEXT" drain NODE_NAME --ignore-daemonsets --delete-emptydir-data
gcloud container node-pools delete default-pool --cluster="$CLUSTER" --location="$ZONE" --project="$PROJECT_ID"
```

Bis zum Cloud-Teil laeuft ein Node. Am Morgen von Tag 2 auf drei Nodes skalieren und abends wieder auf einen:

```bash
gcloud container clusters resize "$CLUSTER" --node-pool=kurs --num-nodes=3 \
  --location="$ZONE" --project="$PROJECT_ID"
kubectl --context "$TRAINER_CONTEXT" get nodes
```

Kein Cluster-Autoscaling: Waehrend der Labs sollen keine Pods wegen eines laufenden Scale-ups kurz `Pending` sein. Das waere fuer Einsteiger nicht von einem echten Fehler zu unterscheiden.

## 4. Registry

```bash
gcloud artifacts repositories create "$REPO" \
  --repository-format=docker --location="$REGION" --project="$PROJECT_ID"
gcloud auth configure-docker "${REGION}-docker.pkg.dev"
```

Die Nodes bekommen Lesezugriff nur auf das Workshop-Repository:

```bash
gcloud artifacts repositories add-iam-policy-binding "$REPO" \
  --location="$REGION" --project="$PROJECT_ID" \
  --member="serviceAccount:${NODE_SA}" --role="roles/artifactregistry.reader"
```

Pruefen: Image mit `docker build --platform linux/amd64 --build-arg APP_VERSION=2.0 -t "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/hallo-app:2.0" lab02-hallo-app` bauen und hochladen. Der Maven-Build laeuft dabei nativ, das Laufzeitimage entspricht der Zielarchitektur. Die Cloud-Umgebung muss beim Push geladen sein, damit der Docker-Credential-Helper den richtigen gcloud-Account nutzt. Push und Pull getrennt testen. Fuer die Trainerbereitstellung wird die hochgeladene Image-Version per Digest referenziert (`DEPLOY_IMAGE` in der lokalen Cloud-Umgebung).

## 5. Teilnehmer

Fuer den Kurs alle Konten in einem Schritt: Adressen in eine Datei schreiben, eine pro Zeile. Die Reihenfolge ergibt die Nummer. Erst ohne `--apply` laufen lassen und die Arbeitskopien in `out/trainer/` lesen:

```bash
bash trainer/einrichtung/teilnehmer-anlegen.sh out/konten.txt
bash trainer/einrichtung/teilnehmer-anlegen.sh out/konten.txt --apply
```

Das Skript legt Namespace und RoleBinding an und vergibt `container.clusterViewer`, `logging.viewer`, `monitoring.viewer` am Projekt und `artifactregistry.writer` am Repository. `out/trainer/teilnehmer.tsv` ordnet Nummer, Namespace und Konto zu. Die Kontoliste und die Tabelle enthalten personenbezogene Daten und bleiben unter `out/` (nicht in Git).

Die Einzelschritte je Person oder Paar `NN` und Google-Konto:

```bash
NN=01
ACCOUNT="person01@example.com"
mkdir -p "out/trainer/person${NN}"
sed "s/workshop-person01/workshop-person${NN}/g" trainer/einrichtung/namespace.yaml > "out/trainer/person${NN}/namespace.yaml"
sed -e "s/workshop-person01/workshop-person${NN}/g" -e "s/TEILNEHMER_KONTO_ERSETZEN/${ACCOUNT}/g" \
  trainer/rbac.yaml > "out/trainer/person${NN}/rbac.yaml"
cat "out/trainer/person${NN}/"*.yaml     # vor dem Anwenden lesen
kubectl --context "$TRAINER_CONTEXT" apply -f "out/trainer/person${NN}/namespace.yaml"
kubectl --context "$TRAINER_CONTEXT" apply -f "out/trainer/person${NN}/rbac.yaml"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:${ACCOUNT}" --role="roles/container.clusterViewer" --condition=None
gcloud artifacts repositories add-iam-policy-binding "$REPO" \
  --location="$REGION" --project="$PROJECT_ID" \
  --member="user:${ACCOUNT}" --role="roles/artifactregistry.writer"
```

`roles/logging.viewer` und `roles/monitoring.viewer` nur vergeben, wenn projektweite Sicht gewollt ist, sonst als Demo zeigen (siehe README). Keine Owner-, Editor- oder Developer-Rollen.

## 6. Pruefung als Teilnehmer

Mit einem echten Testkonto auf einem Rechner ohne Trainerrechte:

```bash
gcloud auth login
gcloud container clusters get-credentials "$CLUSTER" --location="$ZONE" --project="$PROJECT_ID"
kubectl auth can-i create deployments.apps -n workshop-person01   # yes
kubectl auth can-i get secrets -n workshop-person01               # yes
kubectl auth can-i create deployments.apps -n kube-system         # no
kubectl auth can-i create deployments.apps -n workshop-person02   # no
kubectl auth can-i patch nodes                                    # no
```

Danach Lab 4 als Teilnehmer durchspielen und den GKE-Probelauf aus der [README](README.md) abarbeiten. Aus dem Kundennetz wiederholen (API-Endpunkt, Proxy).

## 7. Aufraeumen

Siehe README, Abschnitt "Nach dem Kurs". Zusaetzlich Cluster und Registry loeschen, sonst laufen Kosten weiter:

```bash
gcloud container clusters delete "$CLUSTER" --location="$ZONE" --project="$PROJECT_ID"
gcloud artifacts repositories delete "$REPO" --location="$REGION" --project="$PROJECT_ID"
```

Temporaere IAM-Bindings der Teilnehmer entfernen (`remove-iam-policy-binding` mit denselben Mitgliedern und Rollen). Wenn das Projekt nur fuer den Kurs existierte: `gcloud projects delete "$PROJECT_ID"`.

Die loeschbaren Projektressourcen umfassen auch das Subnetz `gke-workshop`, das gleichnamige VPC-Netz und das Servicekonto `gke-workshop-nodes`. Erst den Cluster entfernen, bevor dessen Netzwerk entfernt wird. Fuer eine kuerzere Vorbereitungspause kann der Node-Pool `kurs` auf null Nodes skaliert werden; danach vor den Labs wieder auf die benoetigte Anzahl skalieren. Das entfernt keine Clustergebuehren oder gespeicherten Artefakte.

Nur den passenden Befehl ausfuehren. Bei null Nodes ist die Anwendung nicht erreichbar:

```bash
# Vorbereitungspause: Node-Pool auf null setzen.
gcloud container clusters resize "$CLUSTER_NAME" --node-pool=kurs --num-nodes=0 \
  --location="$LOCATION" --project="$PROJECT_ID"

# Vorbereitung fortsetzen: einen Node bereitstellen und Readiness abwarten.
gcloud container clusters resize "$CLUSTER_NAME" --node-pool=kurs --num-nodes=1 \
  --location="$LOCATION" --project="$PROJECT_ID"
kubectl --context "$TRAINER_CONTEXT" -n workshop-trainer rollout status deployment/hallo --timeout=600s
```
