# Übergabe für die nächste Sitzung

Stand: 21.11.2026. Lokale Trainerumgebung und GKE-Standard sind eingerichtet. Die Anwendung läuft in beiden Umgebungen mit zwei bereiten Replikas. Die Cloud-Prüfungen wurden mit Trainerrechten durchgeführt. Teilnehmerzugänge und Kurskapazität sind die nächsten Aufgaben.

## Einstieg auf diesem Rechner

Arbeitsordner: `/Users/julienlook/Documents/Coding/gke-workshop`.

```bash
cd /Users/julienlook/Documents/Coding/gke-workshop
source scripts/workshop-env.sh
gcloud config get-value account
workshop_gke
kubectl --context "$GKE_CONTEXT" -n workshop-trainer get pods
python3 scripts/pruefen.py gke
kubectl --context "$GKE_CONTEXT" -n workshop-trainer port-forward service/hallo 18080:80
```

Der Account muss das Look-Beyond-Workshop-Konto sein (`WORKSHOP_CLOUD_ACCOUNT` in `.cache/workshop-cloud.env`). Im Browser `http://127.0.0.1:18080/` öffnen. Den Tunnel mit Strg+C beenden. Für die lokale Anwendung:

```bash
workshop_local
kubectl --context minikube -n workshop get pods
python3 scripts/pruefen.py betrieb
kubectl --context minikube -n workshop port-forward service/hallo 18081:80
```

Port 8080 ist auf diesem Rechner durch die bestehende IaC-Beispielanwendung belegt. Diese Container wurden nicht verändert. Beim Sitzungsende läuft kein von dieser Sitzung gestarteter Port-Forward weiter.

## Vorhandene Infrastruktur

| Bestandteil | Stand beim Sitzungsende |
| --- | --- |
| Google-Konto | Look-Beyond-Workshop-Konto, separate gcloud-Konfiguration `gke-workshop` |
| Projekt | `lookbeyond-gke-workshop`, Abrechnung aktiviert |
| GKE | Cluster `workshop`, Standard, `europe-west3-b`, Regular Channel, Kubernetes `1.36.4-gke.2377000` |
| Node-Pool | `kurs`, `e2-standard-4`, amd64, 50 GB Balanced-PD, kein Autoscaling. Ein Node bis Tag 2, dann drei. `default-pool` gelöscht. CPU-Kontingent 12 vCPU |
| Netzwerk | eigenes VPC/Subnetz `gke-workshop`; Nodes `10.60.0.0/20`, Pods `10.64.0.0/16`, Services `10.65.0.0/20` |
| API-Zugriff | DNS-Endpunkt; `get-credentials` benötigt `--dns-endpoint`; IP-Endpunkte deaktiviert |
| Identität | Workload Identity Federation; eigenes Node-Servicekonto `gke-workshop-nodes@lookbeyond-gke-workshop.iam.gserviceaccount.com` |
| Registry | privates Docker-Repository `workshop` in `europe-west3`; Image `europe-west3-docker.pkg.dev/lookbeyond-gke-workshop/workshop/hallo-app:2.0` |
| GKE-Anwendung | Namespace `workshop-trainer`, Deployment/Service `hallo`, zwei bereite Replikas; Deployment auf Image-Digest fixiert |
| Teilnehmer-Vorbereitung | `workshop-person01` und `workshop-person02`, Namespace-Rolle und Kubernetes-Testidentitäten vorhanden; echte Google-Konten noch nicht gebunden |
| Lokaler Cluster | minikube-Profil `minikube`, Kubernetes 1.35.0, 2 CPUs, 4096 MiB RAM, Namespace `workshop`, `hallo-app:2.0` |

Die Services verwenden `ClusterIP`. Die Anwendung hat keinen öffentlichen Load Balancer. Der Node läuft weiter und verursacht Kosten. Pause, Fortsetzung und Abbau stehen im [Runbook](../trainer/RUNBOOK.md#7-aufraeumen). In dieser Sitzung wurde keine Pause oder Löschung ausgeführt.

## Was geprüft wurde

Die vollständigen Belege und Grenzen stehen im [Teststatus](07-teststatus.md).

- Lokaler Checkpoint `betrieb` und GKE-Checkpoint `gke` bestanden, einschließlich Probes, Konfiguration, Service-Zielen und HTTP-Antwort mit tatsächlichem Pod-Namen.
- amd64-Image auf dem ARM-Mac gebaut, in die private Registry gepusht und vom echten GKE-Node geladen. Der Dockerfile-Build läuft nativ und kopiert das portable Java-Archiv in das Zielimage.
- Interne Service-DNS-Auflösung und HTTP-Aufruf auf GKE geprüft.
- Absichtlicher HTTP-500-Fehler, danach gesunde Liveness; zugehörige Fehlerzeile aus Cloud Logging abgerufen.
- CPU-, Speicher- und Restart-Metrikdaten über die Cloud-Monitoring-API abgerufen. Die Konsolenoberfläche und Teilnehmerrechte bleiben offen.
- Alle drei Lab-5-Fehler auf GKE beobachtet: fehlender ConfigMap-Schlüssel, `OOMKilled`, falscher Readiness-Pfad. Verfügbarkeit, Rollback und Reparaturen bestanden. Danach gesundes Lab 4 wiederhergestellt.
- Namespace-RBAC mit Kubernetes-ServiceAccount-Impersonation geprüft. Eigener Namespace erlaubt; fremder Namespace, `kube-system` und Node-Liste verweigert. Echte Google-Teilnehmerkonten bleiben separat zu prüfen.
- Statische Validierung bestanden. Vollständiger lokaler Dry-Run am 17.11.2026 bestanden. Ein GitHub-Actions-Ergebnis wurde noch nicht bestätigt. Autopilot wurde nicht getestet.

## Dateien und Git-Stand

Branch `main`, Remote `https://github.com/juice1000/gke-workshop.git`. Letzter gepushter Commit: `0b3b57d` (`Build GKE workshop labs and trainer material`).

Die Infrastrukturänderungen dieser Sitzung sind noch nicht committed oder gepusht:

- `README.md`, `docs/06-labs-und-trainer.md`, `docs/07-teststatus.md`
- `lab02-hallo-app/Dockerfile`, `lab04-gke/README.md`
- `trainer/README.md`, `trainer/RUNBOOK.md`
- neu: `scripts/workshop-env.sh` und diese Übergabe `docs/09-uebergabe.md`

Die Änderungen dokumentieren die tatsächliche Infrastruktur, den DNS-API-Zugriff, den Build für eine andere Zielarchitektur und die geprüften Abläufe. Vor dem nächsten Commit `git diff` und `bash scripts/validate.sh` ausführen.

Lokale Dateien bleiben durch `.gitignore` ausgeschlossen:

- `.cache/workshop-cloud.env`: Cloud-Metadaten für die Hilfsfunktionen.
- `.cache/workshop.kubeconfig`: getrennte lokale und GKE-Kontexte, Auth-Plugin an Workshop-Konto gebunden.
- `.cache/bin`, `.cache/minikube-home`: Werkzeuge und persistente lokale Clusterdaten.
- `.cache/gke-verification.json`, `.cache/gke-metrics-verification.json`: Prüfergebnisse des Cloud-Probelaufs.
- `out/live-gke/`: gerenderte Manifeste und Zugriffsvorbereitung.

Die bisher global aktive gcloud-Konfiguration wurde erhalten. Das Workshop-Skript setzt die passende Konfiguration nur für das jeweilige Terminal. Keine Tokens, kubeconfig-Inhalte oder Schlüssel in Git oder Kursunterlagen übernehmen. Auf einem anderen Rechner die Anmeldung und lokale Einrichtung nach [Runbook](../trainer/RUNBOOK.md) neu ausführen.

## Nächste Schritte

Kursstart 23.11.2026, etwa 15 Teilnehmende, jede Person mit eigenem Namespace. Am 21.11. erledigt: Node-Pool `kurs`, Notion an die Labs angeglichen, [VORBEREITUNG.md](../VORBEREITUNG.md) und [teilnehmer-anlegen.sh](../trainer/teilnehmer-anlegen.sh) erstellt.

1. Vorbereitungsseite an die Teilnehmenden senden. Lizenz für Docker Desktop mit der Kunden-IT klären.
2. Tag 1 morgens Google-Konten einsammeln. Abends `bash trainer/teilnehmer-anlegen.sh out/konten.txt`, lesen, dann `--apply`. Zwei Konten mit `kubectl auth can-i` und Lab 4 prüfen.
3. Tag 2 morgens Pool `kurs` auf drei Nodes skalieren (Runbook). Nach dem Kurs Namespaces, IAM-Bindungen, Images und Cluster entfernen.
4. Konsolenrundgang und Logs Explorer mit einem Teilnehmerkonto prüfen.
5. Folien und Diagramme. GitHub-Actions-Ergebnis prüfen.

Weitere offene Kursdetails stehen in [Lernumgebung und offene Punkte](04-lernumgebung-und-offene-punkte.md). Bei der Fortsetzung vorhandene Ressourcen zuerst lesen und wiederverwenden. Die initialen Erstellungsbefehle aus dem Runbook nicht erneut pauschal ausführen.
