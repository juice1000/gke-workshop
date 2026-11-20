# Runbook: Cloud-Umgebung Schritt fuer Schritt

Ergaenzt [README.md](README.md) (Zugriffsmodell, Probelauf, Aufraeumen) um eine Befehlsfolge zum Abarbeiten. Alles wird vom Trainer von Hand ausgefuehrt. Das Repository legt nichts automatisch an. Jeder Abschnitt endet mit einer Pruefung.

Status: Die Befehle sind noch nicht gegen ein echtes Projekt gelaufen. Nach dem Probelauf Ergebnis in [Teststatus](../docs/07-teststatus.md) eintragen und Abweichungen hier korrigieren. Flags vor dem ersten Lauf mit `gcloud ... --help` gegenpruefen.

## 0. Variablen

Nur im aktuellen Terminal gueltig. Werte anpassen.

```bash
export PROJECT_ID="gke-workshop-CHANGEME"
export BILLING_ACCOUNT="XXXXXX-XXXXXX-XXXXXX"   # gcloud billing accounts list
export REGION="europe-west3"
export ZONE="europe-west3-a"
export CLUSTER="workshop"
export REPO="workshop"
export TRAINER_CONTEXT="gke_${PROJECT_ID}_${ZONE}_${CLUSTER}"   # Standard, zonal
# Autopilot: Standort ist die Region, also gke_${PROJECT_ID}_${REGION}_${CLUSTER}
```

## 1. Projekt und APIs

```bash
gcloud auth login
gcloud components install gke-gcloud-auth-plugin
gcloud projects create "$PROJECT_ID"
gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT"
gcloud services enable container.googleapis.com artifactregistry.googleapis.com \
  logging.googleapis.com monitoring.googleapis.com --project="$PROJECT_ID"
```

Pruefen: `gcloud services list --enabled --project="$PROJECT_ID"` zeigt die vier APIs. Budget-Alert in der Konsole unter Billing anlegen.

## 2. Cluster (Variante Standard)

Groesse an die Gruppen anpassen, Kapazitaet je Rollout siehe [README](README.md), Punkt 6.

```bash
gcloud container clusters create "$CLUSTER" \
  --location="$ZONE" --num-nodes=3 --machine-type=e2-standard-4 \
  --project="$PROJECT_ID"
gcloud container clusters get-credentials "$CLUSTER" \
  --location="$ZONE" --project="$PROJECT_ID"
kubectl config get-contexts
kubectl --context "$TRAINER_CONTEXT" get nodes
```

Variante Autopilot (eigener Probelauf noetig):

```bash
gcloud container clusters create-auto "$CLUSTER" --location="$REGION" --project="$PROJECT_ID"
```

Pruefen: Nodes `Ready`. Kubernetes-Version und Node-Architektur notieren (`kubectl --context "$TRAINER_CONTEXT" get nodes -o wide`), das vorgebaute Image muss dazu passen.

## 3. Registry

```bash
gcloud artifacts repositories create "$REPO" \
  --repository-format=docker --location="$REGION" --project="$PROJECT_ID"
gcloud auth configure-docker "${REGION}-docker.pkg.dev"
```

Die Nodes brauchen Lesezugriff. Bei Standard mit dem Compute-Standardkonto im selben Projekt pruefen, ob er schon besteht. Sonst:

```bash
NODE_SA="$(gcloud iam service-accounts list --project="$PROJECT_ID" \
  --filter='displayName:Compute Engine default service account' --format='value(email)')"
gcloud artifacts repositories add-iam-policy-binding "$REPO" \
  --location="$REGION" --project="$PROJECT_ID" \
  --member="serviceAccount:${NODE_SA}" --role="roles/artifactregistry.reader"
```

Pruefen: Testimage pushen (`docker tag`, `docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/hallo-app:2.0`) und in einem Test-Pod ziehen. Push und Pull getrennt testen.

## 4. Teilnehmer

Je Person oder Paar `NN` und Google-Konto. Zuerst die Arbeitskopien der Vorlagen erzeugen und lesen.

```bash
NN=01
ACCOUNT="person01@example.com"
mkdir -p "out/trainer/person${NN}"
sed "s/workshop-person01/workshop-person${NN}/g" trainer/namespace.yaml > "out/trainer/person${NN}/namespace.yaml"
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

## 5. Pruefung als Teilnehmer

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

## 6. Aufraeumen

Siehe README, Abschnitt "Nach dem Kurs". Zusaetzlich Cluster und Registry loeschen, sonst laufen Kosten weiter:

```bash
gcloud container clusters delete "$CLUSTER" --location="$ZONE" --project="$PROJECT_ID"
gcloud artifacts repositories delete "$REPO" --location="$REGION" --project="$PROJECT_ID"
```

Temporaere IAM-Bindings der Teilnehmer entfernen (`remove-iam-policy-binding` mit denselben Mitgliedern und Rollen). Wenn das Projekt nur fuer den Kurs existierte: `gcloud projects delete "$PROJECT_ID"`.
