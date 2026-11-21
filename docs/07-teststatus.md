# Teststatus

Stand: 21.11.2026. Dieser Status dokumentiert lokale und tatsächliche GKE-Prüfungen sowie verbleibende Nachweise.

## Persistente Trainerumgebung, 21.11.2026

Die lokale Umgebung wurde dauerhaft im Arbeitsordner eingerichtet. Einstieg aus dem Repository-Hauptordner: `source scripts/workshop-env.sh`.

| Bestandteil | Zustand |
| --- | --- |
| Werkzeuge | minikube 1.39.0 und kubectl 1.35.0 in `.cache/bin` |
| Lokaler Cluster | Profil `minikube`, Kubernetes 1.35.0, Docker-Treiber, 2 CPUs und 4096 MiB RAM |
| Clusterdaten | `.cache/minikube-home`, eigene kubeconfig `.cache/workshop.kubeconfig` |
| Anwendung | `hallo-app:2.0`, Deployment `hallo`, zwei verfügbare Replikas im Namespace `workshop` |
| Checkpoint `betrieb` | alle Prüfungen bestanden, inklusive Probes, ConfigMap-/Secret-Referenzen, bereiter Service-Adressen und HTTP-Antwort mit tatsächlichem Pod-Namen |
| Erneuter App-Build | drei Tests bestanden |
| Cloud-CLI | separate Konfiguration `gke-workshop` mit dem autorisierten Look-Beyond-Gmail-Konto; GKE-Auth-Plugin installiert |
| Cloud-Infrastruktur | Projekt `lookbeyond-gke-workshop` mit aktiver Abrechnung, GKE-Standard-Cluster und privater Artifact Registry eingerichtet |
| Kontextwechsel | `workshop_local` und `workshop_gke` aus zsh erfolgreich geprüft; beide Umgebungen haben zwei verfügbare Replikas |

Die Anmeldung erfolgte mit dem autorisierten Look-Beyond-Gmail-Konto. Lokale Clusterdaten und Zugangsdaten bleiben vom Git-Repository ausgeschlossen. Der folgende GKE-Nachweis wurde im tatsächlichen Cloud-Cluster erbracht.

## GKE-Standard-Probelauf, 21.11.2026

| Bestandteil | Beobachteter Zustand |
| --- | --- |
| Projekt und Standort | `lookbeyond-gke-workshop`, `europe-west3-b` (Frankfurt) |
| Cluster | `workshop`, Status `RUNNING`, Kubernetes `1.36.4-gke.2377000`, Regular Channel |
| Node | Probelauf auf einem `e2-standard-2`. Danach Pool `kurs` mit `e2-standard-4`, 50 GB Balanced-PD; Trainer-App umgezogen, Checkpoint `gke` erneut bestanden |
| Netzwerk | eigenes VPC und Subnetz `gke-workshop`; Nodes `10.60.0.0/20`, Pods `10.64.0.0/16`, Services `10.65.0.0/20` |
| API-Zugriff | DNS-Endpunkt mit Google-Authentifizierung; IP-basierter Zugriff deaktiviert |
| Identität | eigenes Node-Servicekonto mit GKE-Node-Rolle und Leserecht am Workshop-Repository; Workload Identity Federation aktiviert |
| Registry | privates Docker-Repository `workshop` in `europe-west3`; Push und Pull auf GKE erfolgreich |
| Image | amd64-Laufzeitimage aus nativem Java-Build auf dem ARM-Mac; drei App-Tests im Build bereits bestanden |
| Bereitgestelltes Image | `europe-west3-docker.pkg.dev/lookbeyond-gke-workshop/workshop/hallo-app@sha256:71e9a121eacd630c520aeb64311ebb71cbccfb8485095ba8a6b823492093e8e2` |
| Anwendung | zwei bereite Replikas von `hallo` im Namespace `workshop-trainer`; Version 2.0 über HTTP erreichbar |
| Service und DNS | zwei bereite EndpointSlice-Adressen; HTTP-Aufruf der internen Service-DNS-Adresse aus einem Anwendungs-Pod erfolgreich |
| Probes und Konfiguration | Checkpoint `gke` bestanden: Startup, Readiness, Liveness, Requests/Limit, ConfigMap und tatsächlicher Pod-Name |
| Fehlerroute | `/fehler` liefert absichtlich HTTP 500, danach bleibt Liveness `UP` |
| Cloud Logging | die ausgelöste `FEHLER`-Zeile aus dem Container wurde über die Logging-API abgerufen |
| Cloud Monitoring | Datenpunkte für CPU-Verbrauch, Speicherverbrauch und `kubernetes.io/container/restart_count` über die Monitoring-API abgerufen |
| Release A | `CreateContainerConfigError` wegen fehlendem Schlüssel beobachtet; Verfügbarkeit, Rollback und Reparatur bestanden |
| Release B | `OOMKilled` beobachtet; Verfügbarkeit, Rollback und Reparatur mit 1-GiB-Limit bestanden |
| Release C | Readiness-404 beobachtet; Verfügbarkeit, Rollback und Reparatur bestanden |
| Namespace-RBAC | `workshop-person01` und `workshop-person02`: per Kubernetes-ServiceAccount-Impersonation im eigenen Namespace Deployments/Secrets erlaubt, anderer Namespace, `kube-system` und Node-Liste verweigert |
| Zustand nach dem Probelauf | gesundes Lab-4-Deployment wiederhergestellt, temporäres Übungs-Secret entfernt |

Die Cloud-kubeconfig bindet den Auth-Plugin-Aufruf ausdrücklich an die Workshop-Konfiguration und den autorisierten Account. Die Daten unter `.cache/` und die gerenderten Arbeitskopien unter `out/` sind lokal und nicht versioniert.

Der RBAC-Nachweis verwendet Kubernetes-Testidentitäten. Er ersetzt nicht den noch ausstehenden Test mit zwei echten Google-Teilnehmerkonten und deren IAM-Rollen. Cloud-Logging- und Monitoring-Abfragen liefen mit Trainerrechten. Die Konsole wurde dabei nicht per UI geprüft. Autopilot wurde nicht angelegt oder getestet.

Der Cluster ist für Vorbereitung und Probelauf dimensioniert. Vor dem Kurs sind Teilnehmerkonten und Kapazität an die tatsächlich gleichzeitig arbeitenden Gruppen anzupassen. Der Node bleibt laufend; Anhalten bzw. Löschen ist im [Runbook](../trainer/RUNBOOK.md) beschrieben.

## Lokale Prüfungen

`bash scripts/validate.sh` und `bash scripts/dry-run.sh` sind am 17.11.2026 lokal erfolgreich durchgelaufen.

Umgebung: macOS auf ARM64 mit OrbStack/Docker 29.4.0, minikube 1.39.0, Kubernetes 1.35.0 und passendem kubectl 1.35.0. Der Testcluster hatte einen Node, 2 CPUs und 4096 MiB Speicher. Der Container-Build verwendet Maven 3.9.11, Java 21 und Spring Boot 3.5.16. Die Basisimages sind im Dockerfile per Digest fixiert.

| Prüfung | Ergebnis |
| --- | --- |
| ShellCheck, Python-Syntax und lokale Markdown-Verweise | bestanden |
| kubeconform 0.7.0, alle Lab- und Trainer-Manifeste | 35 Ressourcen in 33 Dateien gültig, keine Fehler oder übersprungenen Ressourcen |
| App-Tests im Docker-Build | 3 Tests bestanden: konfigurierte Antwort ohne Secret-Ausgabe, Actuator-Probes, HTTP-Fehler ohne anschließenden Health-Ausfall |
| DNS-Rallye | DNS-Pods mit `k8s-app=kube-dns` gefunden und laufend |
| Lokales Deployment | HTTP-Antwort mit tatsächlichem Pod-Namen und Version, zwei bereite Service-Ziele |
| Selbstheilung und Skalierung | Pod ersetzt, vier Kopien bereit, zurück auf zwei |
| ConfigMap und Secret | Referenzen korrekt, neue Env-Begrüßung erst nach Neustart, Version 2.0 erreichbar |
| Fünf Troubleshooting-Fälle | alle beabsichtigten Fehler erkannt, jede Lösung erfolgreich ausgerollt |
| GKE-Manifeste mit lokalem Image | gerendert und lokal erfolgreich ausgerollt; kein Cloud-Nachweis |
| Abschluss Release A | fehlender ConfigMap-Schlüssel beobachtet, Rollback und Reparatur bestanden |
| Abschluss Release B | `OOMKilled` nachgewiesen, Rollback und Reparatur mit 1-GiB-Limit bestanden |
| Abschluss Release C | Readiness-404 nachgewiesen, Rollback und Reparatur bestanden |
| Verfügbarkeit bei allen drei Fehler-Releases | die vorherigen bereiten Pods blieben erhalten und HTTP antwortete weiter |
| Namespace-RBAC | per Impersonation eigener Zugriff erlaubt, fremder Namespace und Node-Liste verweigert |
| Lokales Node-Experiment | Ersatz-Pod nach `cordon` nicht planbar, nach `uncordon` wieder bereit |
| PDB | bei zwei bereiten Pods genau eine freiwillige Unterbrechung erlaubt |
| Aufräumen des Probelaufs | eigenes Testprofil entfernt, separate kubeconfig verwendet |

Beim Probelauf wurden zwei zeitliche Effekte berücksichtigt: Ein Tag-1-Container kann vor dem HTTP-Server als bereit erscheinen, und Crash-Logs können kurz nach dem Prozessende noch nicht abrufbar sein. Die Prüfungen warten begrenzt auf die tatsächlichen Belege. Die Pod-Namen werden ausdrücklich per Downward API gesetzt.

Die GitHub-Actions-Workflowdatei führt diese Prüfungen bei Push/PR aus. Ein Lauf auf GitHub Actions wurde in dieser Arbeitskopie nicht ausgelöst. Die Linux-/amd64-Variante der CI muss daher noch dort bestätigt werden.

## Probelauf als Teilnehmer auf GKE, 21.11.2026

Nach dem Umzug auf den Pool `kurs` (ein `e2-standard-4`). Kubernetes-Aktionen liefen per Impersonation als `system:serviceaccount:workshop-person01:workshop-checker`, also nur mit der Namespace-Rolle aus `trainer/rbac.yaml`. Build und Push liefen mit Trainerrechten, weil diese Identität keine IAM-Rolle hat.

| Schritt | Ergebnis |
| --- | --- |
| Rechte | eigener Namespace: Deployments und Secrets `yes`; `kube-system`, `workshop-person02`, Nodes `no` |
| Lab 4 | eigenes Image `hallo-app-workshop-person01:2.0` (amd64) gepusht, Rollout in 17 s, Checkpoint `gke` grün, HTTP-Antwort aus GKE, `/fehler` liefert 500 und Logzeile `FEHLER` |
| Lab 5 A | Lösung ausgerollt, Checkpoint `abschluss` grün |
| Release A, B, C | `CreateContainerConfigError`, `OOMKilled`, Readiness 404 beobachtet; jeweils zwei alte Pods bereit und HTTP erreichbar; Rollback und Reparatur grün |

Gesamtdauer 8 Minuten. Der gleichzeitige lokale Probelauf `scripts/dry-run.sh` bestand ebenfalls. Danach blieb Lab 4 in `workshop-person01` zum Ansehen in der Konsole stehen.

## Vor Durchführung noch nötig

- [x] GKE-Standard bereitstellen, Anwendung und fehlerhafte Releases mit Trainerrechten durchspielen.
- [ ] Alle Cloud-Schritte mit echten Google-Teilnehmerkonten ausführen.
- [ ] Autopilot separat testen, wenn dieser Modus im Kurs verwendet werden soll. Admission-Änderungen, Speicherfall und Wartezeiten dokumentieren.
- [x] Registry-Push und privater Image-Pull mit der tatsächlichen Node-Identität prüfen.
- [ ] Test mit zwei Teilnehmerkonten und getrennten Namespaces; IAM darf die RBAC-Trennung nicht aufheben.
- [ ] Logs Explorer, CPU-/Speicher-Metriken und Restart-Metrik mit Teilnehmerrechten nachweisen.
- [ ] Konsolennavigation, Release Channel, Wartungsfenster und Node-Pools im tatsächlichen Projekt prüfen.
- [ ] Frischen Windows-/WSL-Rechner testen: bewusst ausgelassen, siehe unten.
- [ ] Noch offene Kursdetails aus [Lernumgebung](04-lernumgebung-und-offene-punkte.md) mit dem Kunden klären.
- [x] Notion-Differenzen aus [Lab-Zuordnung](06-labs-und-trainer.md) in die Kursunterlagen übernehmen (21.11.2026).
- [x] Node-Pool für 15 Personen bemessen und angelegt (`kurs`, siehe [Runbook](../trainer/RUNBOOK.md#kurs-node-pool-umgesetzt-am-21112026)). Am Morgen von Tag 2 auf drei Nodes skalieren.
- [x] `trainer/teilnehmer-anlegen.sh` mit Testliste im Planmodus und unter Bash 3.2 geprüft. Das Anwenden mit echten Konten steht aus.
- [ ] Installationsbefehle aus [VORBEREITUNG.md](../VORBEREITUNG.md) auf Windows/WSL2 und Linux: bewusst nicht vorab getestet (Entscheidung 21.11.2026). Die Befehle folgen den Herstelleranleitungen. Probleme fängt Lab 0 am ersten Morgen ab, Ausweg Paararbeit und Cloud Shell.

Die GKE-Ergebnisse beziehen sich auf Standard mit Trainerrechten. Autopilot, Kundennetz, Konsolennavigation und tatsächliche Teilnehmerkonten brauchen getrennte Prüfungen.
