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

## GKE vor Tag 2, 24.11.2026

| Bestandteil | Beobachteter Zustand |
| --- | --- |
| gcloud | Konfiguration `gke-workshop`, Konto Look-Beyond-Gmail, Projekt `lookbeyond-gke-workshop` |
| Cluster | `workshop` vorhanden, `RUNNING`, Standard, `europe-west3-b`, Regular Channel, Control Plane und Nodes `1.36.4-gke.2377000`; kein zweiter Cluster angelegt |
| API-Zugriff | nur DNS-Endpunkt, IP-Endpunkte deaktiviert |
| Node-Pool `kurs` | vorher 1 Node `e2-standard-4`; nach Freigabe mit `gcloud container clusters resize workshop --node-pool=kurs --num-nodes=3` auf drei Nodes skaliert, alle drei `Ready`, amd64 |
| Namespaces | `workshop-trainer`, `workshop-person01`, `workshop-person02` sowie System-Namespaces |
| Anwendung | `hallo` in `workshop-trainer`: 2/2 bereit, beide Pods auf dem ursprünglichen Node, Image per Digest `hallo-app@sha256:71e9...`; nicht neu ausgerollt |
| Service | `hallo`, `ClusterIP`, kein Load Balancer |
| HTTP | per `port-forward` auf 18080: `Hallo von GKE von Pod hallo-84cd85c8f5-cc58n, Version 2.0`; `/fehler` liefert 500 |
| Registry | `hallo-app:2.0` (Digest wie oben) und `hallo-app-workshop-person01:2.0` im Repository `workshop` |
| Lokaler Cluster | minikube-Profil `minikube` fehlt; `.cache/workshop.kubeconfig` enthält nur den GKE-Kontext. `workshop_local` schlägt deshalb fehl |
| Konsole | nicht per UI geprüft: Claude in Chrome war nicht verbunden |

Nach dem Kurstag den Pool wieder auf einen Node setzen: `gcloud container clusters resize workshop --node-pool=kurs --num-nodes=1 --zone=europe-west3-b --project=lookbeyond-gke-workshop`. Die zwei bestehenden Pods wurden nicht umverteilt; neue Pods der Teilnehmenden verteilt der Scheduler auf alle drei Nodes.

## Gemeinsames Gateway für Lab 4 Extra 4, 24.11.2026

| Schritt | Beobachtet |
| --- | --- |
| Gateway API | `gcloud container clusters update workshop --gateway-api=standard`; vier GatewayClasses von GKE `Accepted`, laufende Pods unverändert |
| RBAC | Role `workshop-entwickler` in `workshop-person01` und `workshop-person02` um `httproutes` ergänzt; Testidentität darf im eigenen Namespace Routen anlegen, im fremden nicht |
| Gateway | `trainer/gateway.yaml`, Klasse `gke-l7-global-external-managed`, nach etwa 3 Minuten `Programmed`, öffentliche Adresse vergeben |
| Trainer-Route | `/workshop-trainer` zu `hallo:80` in `workshop-trainer`; Namespace dafür mit `workshop=gke-einfuehrung` gelabelt. Erste HTTP-200-Antwort etwa 7 Minuten nach dem Anlegen, vorher Timeout und `502` |
| Von außen | `curl` von außerhalb des Clusters: Antwort beider Pods abwechselnd, `/fehler` liefert `500`, Pfad `/` ohne Route liefert `404` |
| Zweite Route | auf vorhandenem Gateway etwa 4 Minuten bis zur Wirkung, vorher `404` |
| Fehlerfall | Route auf nicht vorhandenen Service: `ResolvedRefs=False`, Grund `BackendNotFound`, `curl` liefert `500`. Testroute danach gelöscht |
| Browser-Ansicht `/ui/` | App mit `/api/info` und `/ui/` als `hallo-app:2.1` gebaut (fünf App-Tests bestanden), amd64 gepusht, Digest `sha256:f5d606d7...`. Trainer-Deployment per Rolling Update umgestellt, Dienst blieb erreichbar. Über das Gateway: `/workshop-trainer/ui/` und `/ui` liefern 200, die Seite zeigt beide Pods abwechselnd. `/` bleibt Text. Am 24.11.2026 aus dem Repository entfernt (beide Branches); auf GKE läuft im Trainer-Namespace weiter `hallo-app:2.1` mit `/ui/`, nicht neu ausgerollt |
| Browser und HTTP | Headless Chrome mit Standardprofil blockierte `http://` zur IP (`ERR_BLOCKED_BY_CLIENT`), erst ohne HTTPS-Upgrade geladen. Normale Browser der Teilnehmenden nicht geprüft |
| Nicht geprüft | Route mit echtem Teilnehmerkonto; die `practice`-Fassung mit TODOs auf dem Cluster |

Das Gateway läuft bis zum Abend und kostet bis dahin Geld. Abbau steht in [Nach dem Kurs](11-nach-dem-kurs-aufraeumen.md).

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

## Umbau Tag 2 auf Kern und Extra, 24.11.2026

Lokal geprüft in eigenen minikube-Profilen (Kubernetes 1.35.0, ein Node), danach gelöscht. Kein GKE-Lauf.

| Schritt | Ergebnis |
| --- | --- |
| Lab 2 Tag 2, Schritt 5 | `base64 -d` liefert den Klartext des Übungs-Secrets |
| Lab 2 Tag 2, Schritt 6 | kaputter Readiness-Pfad: neuer Pod `Running` `0/1`, zwei alte `1/1`, `rollout status` bricht nach 60 s ab, Event `Readiness probe failed ... 404`, Checkpoint `betrieb` meldet den Pfad als `FEHLT`; nach Reparatur der Datei wieder grün |
| Lab 2 Tag 2, Schritt 7 | `set image` mit falschem Tag hängt, `rollout undo` stellt her |
| Lab 2 Extras | `config-pod.yaml`: Datei unter `/config` nach 85 s aktualisiert, Umgebungsvariable unverändert; `kubectl diff` zeigt `replicas`; `change-cause` erscheint in `rollout history`; `MaxHeapSize` 334 MiB bei 512-MiB-Limit; HPA mit metrics-server zeigt nach 80 s `cpu: 3%/50%` |
| Lab 3 Extra 2 | `oom.yaml`: `OOMKilled`, Exit-Code 137 nach 5 s, `logs --previous` liefert nichts |
| Lab 4 Extra 3 | `spread.yaml` gerendert und lokal ausgerollt, drei Pods bereit. Auf einem Node landen alle drei dort; die Verteilung über drei GKE-Nodes ist **nicht** geprüft |
| Statisch | `validate.sh` auf `main` und `practice` bestanden |

Nicht geprüft: Lab 4 Extras auf GKE (Logs Explorer, `auth can-i`, Verteilung über drei Nodes), Kapazität bei 15 gleichzeitigen `spread.yaml`. `dry-run.sh` wurde nicht erneut ausgeführt, weil sich Prüfskripte und Kern-Manifeste nicht geändert haben.

## Demonstrationen Tag 2 und Kommentare in den Manifesten, 24.11.2026

Alle 25 Skripte in `demos/tag2/` mit `--auto` nacheinander in einem eigenen minikube-Profil (`--cpus=2 --memory=4096`, Kubernetes 1.35.0) ausgeführt, danach gelöscht. Kein GKE-Lauf.

| Ergebnis | Demos |
| --- | --- |
| Exit 0, Ausgangszustand danach wiederhergestellt (`hallo` mit `hallo-app:2.0`, 2 Pods) | alle 25 |
| Fehlerbild sichtbar wie beschrieben | 2.1d leere EndpointSlice, 2.2a alter Wert bis zum Neustart, 2.2b `CreateContainerConfigError` und Start nach Reparatur, 2.3b `0/1` mit `Readiness probe failed ... 404`, 2.3d `CrashLoopBackOff`, 2.3g `OOMKilled`, 2.4b `ErrImagePull` mit alten Pods bereit, 2.4d `1.0` im Cluster und `2.0` in der Datei |
| Korrigiert | 2.3f: Docker Desktop meldet dem minikube-Node alle 8 CPUs des Rechners, trotz `--cpus=2`. Mit 10 Kopien blieb kein Pod `Pending`. Neu: CPU-Request neuer Pods auf 60 Prozent des Nodes, Ergebnis `FailedScheduling ... Insufficient cpu`, danach wieder 250m |
| Angepasst | 2.3h: `kubectl top` lieferte in 60 s noch keine Werte, der HPA kurz danach `cpu: 3%/50%`. Wartezeit auf 90 s. 2.3d: Die Anwendung startet in etwa 2 s; der Neustart kommt, weil die erste Liveness-Prüfung sofort läuft. Text angepasst |

| Korrigiert | `demos/lib.sh`: Auf dem Trainerrechner läuft minikube unter `~/.kube` und `~/.minikube`, nicht in `.cache/`. Fehlt der Kontext in der Workshop-kubeconfig, nutzt `lib.sh` jetzt die Umgebung von vorher. Geprüft mit 2.1b und 2.1e gegen den echten Cluster (nur lesend) |

Nicht geprüft: interaktiver Modus mit Strg+C mitten in einer Demonstration.

## Demonstrationen Tag 3, 24.11.2026

Alle 7 Skripte in `demos/tag3/` mit `--auto` gegen das lokale Profil `minikube` (ein Node, Kubernetes 1.37.0) ausgeführt, vorher `demos/tag2/00-vorbereiten.sh --auto`. Kein GKE-Lauf.

| Ergebnis | Demos |
| --- | --- |
| Wie beschrieben, Exit 0, Ausgangszustand danach wiederhergestellt | 3.1a, 3.2a, 3.3a, 3.4a, 3.4b, 3.6a, 3.6b |
| Beobachtet | 3.4a: `rollout status --timeout=30s` Exit 1, nach `undo` Exit 0. 3.6a: Ersatz-Pod `Pending`, Event `1 node(s) were unschedulable`. 3.6b: `ALLOWED DISRUPTIONS 0`, drain wiederholt `Cannot evict pod as it would violate the pod's disruption budget`, Exit 1 nach 30 s, beide Pods laufen weiter |
| Korrigiert | 3.4b zeigt nur Pods in Phase `Running`. Direkt nach 3.4a war sonst noch der Pod mit `hallo-app:gibtsnicht` ohne imageID zu sehen |
| Strg+C | 3.6b mit SIGINT an die Prozessgruppe mitten im drain abgebrochen: Exit 130, Node danach entsperrt, PDB gelöscht |

Nicht geprüft: interaktiver Modus, Lauf in einem frischen minikube-Profil, Mehr-Node-Cluster.

Alle Manifeste auf `main` tragen Kommentare `FEST`, `FREI` und `PASST ZU` (Legende im Kopf von `lab02-hallo-app/k8s/deployment.yaml`). Geprüft: Ohne Kommentar- und Leerzeilen sind alle 37 Dateien unverändert, `validate.sh` bestanden. Fehlerdateien aus Lab 3 und Lab 5 haben nur einen Kopfkommentar, damit sie den Fehler nicht verraten. Auf `practice` bleiben die Manifeste ohne diese Kommentare.

## NodePort ohne Tunnel, 24.11.2026

Lab 2, Abschnitt 2.4 „Gut zu wissen“ und `lab02-hallo-app/extra/nodeport.yaml`, geprüft auf macOS mit Docker Desktop in einem eigenen minikube-Profil, danach gelöscht.

| Fall | Ergebnis |
| --- | --- |
| `--ports=30080:30080` | Docker bindet `0.0.0.0:30080`, also aus dem ganzen Netzwerk erreichbar. `curl localhost:30080` antwortet, Anfragen verteilt auf beide Pods (3 und 5 von 8) |
| `--ports=127.0.0.1:30080:30080` | Docker bindet nur `127.0.0.1`. Über die LAN-Adresse des Rechners keine Antwort. Über `127.0.0.1:30080` nach etwa 8 s stabil: 15 von 15 Anfragen mit HTTP 200, abwechselnd beide Pods |
| Direkt nach dem Anlegen des Service | die ersten Sekunden `Connection reset by peer`, danach stabil |

Nicht geprüft: Linux ohne `--ports` über `minikube ip`, Windows mit WSL.

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
