# Nach dem Kurs: Cloud-Ressourcen entfernen

Erinnerung für den Trainer. Kursende ist der 25.11.2026. Bis alles gelöscht ist, laufen Kosten für Nodes, Cluster und Registry.

Stand 24.11.2026: Node-Pool `kurs` hat drei `e2-standard-4`. Das Deployment `hallo` läuft in `workshop-trainer`. In der Registry liegen `hallo-app` und `hallo-app-workshop-person01`, dazu kommen die Images der Teilnehmenden.

Jeden Schritt von Hand ausführen. Vor jedem Löschen erst ansehen, was betroffen ist. Ablauf und Hintergründe: [trainer/README.md](../trainer/README.md#nach-dem-kurs) und [Runbook, Abschnitt 7](../trainer/RUNBOOK.md#7-aufraeumen).

```bash
source scripts/workshop-env.sh
gcloud config get-value account        # Look-Beyond-Workshop-Konto
export PROJECT_ID=lookbeyond-gke-workshop ZONE=europe-west3-b REGION=europe-west3
export CTX=gke_lookbeyond-gke-workshop_europe-west3-b_workshop
```

## Jeden Kursabend

- [ ] Gemeinsames Gateway und alle Routen löschen. Erst ansehen, dann löschen:

```bash
kubectl --context "$CTX" get httproutes -A
kubectl --context "$CTX" delete httproutes --all -n workshop-trainer   # je Namespace mit Route
kubectl --context "$CTX" delete -f trainer/gateway.yaml
gcloud compute forwarding-rules list --global --project="$PROJECT_ID"   # erwartet: leer
```

- [ ] Node-Pool wieder auf einen Node setzen, wenn am nächsten Tag kein Cloud-Teil folgt:

```bash
gcloud container clusters resize workshop --node-pool=kurs --num-nodes=1 \
  --zone="$ZONE" --project="$PROJECT_ID"
```

## Direkt nach dem Kurs

- [ ] Übrige Load Balancer prüfen, erwartet: keine. `kubectl --context "$CTX" get services -A | grep LoadBalancer`
- [ ] Teilnehmer-Namespaces ansehen, dann löschen: `kubectl --context "$CTX" get namespaces`, je Namespace `kubectl --context "$CTX" delete namespace workshop-personNN`.
- [ ] IAM-Bindungen der Teilnehmenden entfernen. Die Zuordnung steht in `out/trainer/teilnehmer.tsv`. Je Konto `remove-iam-policy-binding` für `container.clusterViewer`, `logging.viewer`, `monitoring.viewer` und `monitoring.alertPolicyEditor` am Projekt sowie `artifactregistry.writer` am Repository `workshop`. Prüfen: `gcloud projects get-iam-policy "$PROJECT_ID"`.
- [ ] Demo 3.4d (GitHub Actions) abbauen: RoleBinding und Role `workshop-entwickler` in `workshop-trainer` (`kubectl delete -f out/trainer/github/rbac.yaml`), Dienstkonto `gh-deployer` (`gcloud iam service-accounts delete gh-deployer@lookbeyond-gke-workshop.iam.gserviceaccount.com`), dazu seine Bindungen an `container.clusterViewer` am Projekt und `artifactregistry.writer` am Repository `workshop`, Provider und Pool (`gcloud iam workload-identity-pools providers delete github-oidc --workload-identity-pool=github --location=global`, dann `gcloud iam workload-identity-pools delete github --location=global`), Demo-Images `hallo-app:2.0-*` im Repository `workshop`.
- [ ] Alarmrichtlinien aus Lab 5 löschen. Ansehen: Monitoring, Alerting, Policies, Namen beginnen mit `workshop-`. Löschen dort oder per API mit `curl -X DELETE` auf den Namen der Richtlinie.
- [ ] E-Mail-Kanäle `workshop-* E-Mail` löschen (Monitoring, Alerting, Edit notification channels), erst nach den Richtlinien. Sonst gehen Alarme weiter an Kundenadressen.
- [ ] Lab-Routen: `kubectl delete httproute hallo` in jedem Kurs-Namespace, falls Lab 6 Aufräumen ausgelassen wurde. Das Gateway selbst löscht der Trainer ohnehin nach jedem Kurstag.
- [ ] Kontingente in den Namespaces verschwinden mit den Namespaces. `workshop-trainer` behält sein Kontingent, bis der Namespace gelöscht wird.
- [ ] Personenbezogene Dateien lokal löschen: `out/konten.txt`, `out/trainer/`.

## Nach der vereinbarten Aufbewahrung

Cluster und Registry erst löschen, wenn nichts mehr gezeigt oder nachgereicht werden muss.

- [ ] Cluster löschen (entfernt Node-Pool, Nodes und `workshop-trainer`):

```bash
gcloud container clusters delete workshop --zone="$ZONE" --project="$PROJECT_ID"
```

- [ ] Registry löschen (alle Images): `gcloud artifacts repositories delete workshop --location="$REGION" --project="$PROJECT_ID"`
- [ ] Netzwerk erst nach dem Cluster: Subnetz `gke-workshop` (Region `europe-west3`), dann VPC `gke-workshop`.
- [ ] Node-Servicekonto `gke-workshop-nodes@lookbeyond-gke-workshop.iam.gserviceaccount.com` und seine Projektbindung entfernen.
- [ ] Wenn das Projekt nur für den Kurs bestand: `gcloud projects delete "$PROJECT_ID"` statt der Einzelschritte.
- [ ] Lokal: `GKE_CONTEXT` aus `.cache/workshop.kubeconfig` entfernen, `.cache/workshop-cloud.env` und `out/live-gke/` löschen.
- [ ] Nach einigen Tagen in der Konsole unter Abrechnung prüfen, dass keine Kosten mehr anfallen.
- [ ] Ergebnis mit Datum in [Teststatus](07-teststatus.md) eintragen.
