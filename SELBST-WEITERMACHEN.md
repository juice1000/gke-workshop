# Selbst weitermachen: eigenes GKE-Projekt

Der Kurscluster ist nach dem Workshop gelöscht. Mit diesem Leitfaden richtet ihr euch ein eigenes Google-Cloud-Projekt mit einem kleinen GKE-Cluster ein und macht die Labs 4 bis 6 dort weiter. Labs 0 bis 3 und 7 laufen lokal mit minikube und kosten nichts.

Dauer der Einrichtung: etwa 30 Minuten, davon 10 Minuten Warten auf den Cluster.

## Was das kostet

- Die Verwaltungsgebühr für **einen** zonalen Cluster deckt das kostenlose Kontingent von GKE.
- Bezahlt werden die Nodes (hier zwei `e2-standard-2`), ihre Festplatten, ein Load Balancer aus Lab 5 und gespeicherte Images.
- Wer abends den Node-Pool auf 0 setzt oder nach dem Üben alles löscht, zahlt wenig. Aktuelle Preise: [Google Cloud Preisrechner](https://cloud.google.com/products/calculator).
- Neue Google-Cloud-Konten bekommen oft ein Startguthaben. Prüft das bei der Anmeldung.

Löscht am Ende alles, siehe [Aufräumen](#aufräumen). Ein vergessener Cluster kostet jeden Tag Geld.

## 1. Projekt und Abrechnung

Legt in der [Konsole](https://console.cloud.google.com/projectcreate) ein Projekt an und verknüpft es unter Abrechnung mit einem Rechnungskonto. Dann im Terminal:

```bash
export PROJECT_ID=EURE_PROJEKT_ID
export REGION=europe-west3
export ZONE=europe-west3-b

gcloud auth login
gcloud config set project "$PROJECT_ID"
gcloud services enable container.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com
```

Werkzeuge fehlen? [VORBEREITUNG.md](VORBEREITUNG.md) oder `bash scripts/setup.sh`.

## 2. Cluster anlegen

Ein zonaler Cluster mit zwei kleinen Nodes. Workload Identity und das Secret-Manager-Add-on braucht Lab 6, Etappe D.

```bash
gcloud container clusters create workshop --zone "$ZONE" \
  --num-nodes=2 --machine-type=e2-standard-2 --disk-size=30 \
  --workload-pool="$PROJECT_ID.svc.id.goog" \
  --enable-secret-manager \
  --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM
```

Dauert etwa 5 bis 10 Minuten. Erwartet am Ende: `STATUS: RUNNING`.

## 3. Registry anlegen

```bash
gcloud artifacts repositories create workshop --repository-format=docker --location="$REGION"
gcloud auth configure-docker "$REGION-docker.pkg.dev"
```

Die Nodes laden Images mit dem Standard-Dienstkonto von Compute Engine. In manchen Projekten fehlt ihm das Leserecht. Dann gebt es ihm ausdrücklich, sonst kommt in Lab 4 `ImagePullBackOff` mit `403`:

```bash
NR=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
gcloud artifacts repositories add-iam-policy-binding workshop --location="$REGION" \
  --member="serviceAccount:$NR-compute@developer.gserviceaccount.com" --role=roles/artifactregistry.reader
```

## 4. Weiter mit Lab 4

[Lab 4](lab04-gke/README.md) verbindet kubectl mit dem Cluster, legt den Namespace `workshop` an, baut das Image und rollt es aus. Danach folgen [Lab 5](lab05-stoerungen/README.md) und [Lab 6](lab06-abschluss/README.md).

In jedem neuen Terminal braucht ihr:

```bash
export PROJECT_ID=EURE_PROJEKT_ID
export REGION=europe-west3
export ZONE=europe-west3-b
export IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/workshop/hallo-app:2.0"
kubectl config current-context     # erwartet: gke_..._workshop
```

## Pause machen

Nodes auf 0 setzen spart die Node-Kosten. Die Objekte im Cluster bleiben erhalten, Pods starten beim Hochfahren neu:

```bash
gcloud container clusters resize workshop --zone "$ZONE" --num-nodes=0 --quiet
gcloud container clusters resize workshop --zone "$ZONE" --num-nodes=2 --quiet   # weiter
```

Ein Load Balancer aus Lab 5 kostet auch ohne Nodes weiter: `kubectl delete service hallo-extern`.

## Aufräumen

Am einfachsten löscht ihr das ganze Projekt. Das entfernt Cluster, Registry, Secrets, Alarme und Load Balancer auf einmal:

```bash
gcloud projects delete "$PROJECT_ID"
```

Oder einzeln, wenn das Projekt bleiben soll:

```bash
gcloud container clusters delete workshop --zone "$ZONE" --quiet
gcloud artifacts repositories delete workshop --location="$REGION" --quiet
gcloud secrets delete hallo-db --quiet
gcloud secrets delete hallo-db-fremd --quiet
```

Alarmrichtlinien und Benachrichtigungskanäle aus Lab 5 löscht ihr in der Konsole unter Monitoring, Alerting. Prüft nach einigen Tagen unter Abrechnung, dass keine Kosten mehr anfallen.
