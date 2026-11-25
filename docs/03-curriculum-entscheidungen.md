# 03 Curriculum-Entscheidungen

## Ausgangspunkt: GFU-Gliederung S5549

Die GFU-Gliederung hat acht Module plus Praxisübung:

1. Einführung in Kubernetes und GKE
2. GKE-Cluster erstellen und verwalten (Console, gcloud, Terraform, Node Pools, Spot VMs, Upgrades)
3. Workloads deployen (Rolling Updates, Blue-Green, Canary mit Istio, Helm, Autoscaling)
4. Networking und Sicherheit (VPC-native, Load Balancing, IAM, Network Policies, Service Mesh)
5. Monitoring und Logging (Cloud Operations, Prometheus und Grafana, Troubleshooting)
6. Storage (Persistent Volumes, GCS-FUSE, Filestore, Backup mit Velero)
7. CI/CD (Cloud Build, GitHub Actions, GitOps mit Anthos Config Management, Security Scans)
8. Best Practices und Kostenoptimierung

Die Praxisübung sieht einen Cluster mit zwei Node Pools (davon einer Spot), ein Helm-Deployment, HPA, Cloud Monitoring und ein Canary Deployment vor.

Das ist für drei Tage mit gemischtem Niveau deutlich zu viel und setzt Cluster-Betrieb voraus, den die Zielgruppe nicht braucht.

## Entscheidungen

| Entscheidung | Begründung |
|---|---|
| Tag 1 komplett lokal (minikube) | Grundlagen ohne Cloud-Komplexität; Juniors nicht mit zwei neuen Welten gleichzeitig überfordern (Vorschlag Julien, vom Kunden nicht beanstandet) |
| GKE erst ab Tag 2 nachmittags | Wiederverwendung des Gelernten, Cloud-Zugang ist zudem das größte organisatorische Risiko |
| Cluster-Erstellung nur gezeigt, nicht von den Teilnehmenden gemacht | Der Infrastrukturanbieter legt Cluster per Terraform an; Entwickler brauchen Betrieb von Workloads, nicht Cluster-Bau |
| Autopilot und Standard erklären, Standard planen | Kunde plant mit Standard (ZIMDB Plus); Autopilot wird als Vergleich eingeordnet |
| Troubleshooting als eigener Block mit Lab | Direkt aus den Kundenwünschen (Pod startet hundertmal neu) |
| Probes, Requests und Limits früh | Häufigste reale Fehlerursachen bei Spring-Boot-Anwendungen (OOMKilled, Startzeit) |
| IAM gegen RBAC abgrenzen | Kunde fühlt sich von der Konsole erschlagen; Abgrenzung der Zuständigkeiten ist ein Kernwunsch |
| Pipeline nur konzeptionell | Der Kunde nutzt TeamCity und Artifactory, die wir nicht im Zugriff haben; wir zeigen, wo Kubernetes andockt |
| Terraform nur kurz einordnen | Kein Alltag beim Kunden, Zusammenhang trotzdem relevant |
| Ops-Themen als Vertiefung | Wenige Ops-Kollegen; Tag 3 Lab 7 und optionale Themen bedienen sie |

## Im Kernprogramm gestrichen oder nur optional

Helm, HPA/VPA/Cluster Autoscaler, Spot VMs, Taints und Tolerations, Blue-Green und Canary mit Istio, Service Mesh, Network Policies im Detail, Storage und Backup, GitOps mit Anthos Config Management, Binary Authorization, FinOps. Diese Themen stehen auf der Liste der optionalen Vertiefungen im Notion-Überblick und können je nach Teilnehmerfeld ergänzt werden.

## Veraltetes in der GFU-Gliederung

Vor der Verwendung zu prüfen und nicht unbesehen zu übernehmen: Pod Security Policies (aus Kubernetes entfernt, Nachfolger Pod Security Standards), Container Registry (abgelöst durch Artifact Registry), Anthos-Namensgebung, Helm 2 vs. 3 (Helm 2 ist irrelevant). Der Kunde hat zudem ausdrücklich darum gebeten, tagesaktuelle Produkte von Legacy zu trennen.

## Aufbau der drei Tage

| Tag | Thema | Umgebung |
|---|---|---|
| 1 | Grundlagen: Container, Architektur, Kernobjekte, kubectl | lokal (minikube) |
| 2 | Betreiben und erste Schritte auf GKE: YAML, Probes, Updates, Troubleshooting, GKE-Überblick, erstes Deployment | lokal, ab Nachmittag GKE |
| 3 | Betrieb auf GKE: Logging und Monitoring, Zugriffsrechte, Pipeline-Anbindung, Abschlussübung | GKE |

Pro Tag sind Pufferzeiten für Fragen eingeplant, und es gibt Streichlisten in den Lecturer-Notizen.

## Material-Kette

Notion (Dokumentation, Lecturer's Edition, Glossar) zuerst, dann Beispielanwendung und Labs in diesem Repository, danach Folien.
