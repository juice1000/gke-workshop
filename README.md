# GKE Einführung: Workshop-Labs

Übungsmaterial für den dreitägigen Workshop der S-Management Services GmbH. Durchführung: Look Beyond. Die Labs begleiten die vorhandenen Notion-Kapitel. Sie beginnen lokal und führen dieselbe Spring-Boot-Anwendung auf GKE weiter.

## Ablauf

| Lab | Wann | Ziel | Dauer |
| --- | --- | --- | --- |
| [0: Setup-Check](lab00-check/README.md) | Tag 1 | Werkzeuge prüfen, lokalen Cluster starten | 30 Min. |
| [1: kubectl-Rallye](lab01-kubectl/README.md) | Tag 1 | Kontext, Pods, Logs und Events lesen | 25 Min. |
| [2: hallo-app](lab02-hallo-app/README.md) | Tag 1 und Tag 2 | Image bauen, deployen, konfigurieren, Probes und Updates | 60 Min. plus Tag-2-Übungen |
| [3: Fehlersuche](lab03-defekt/README.md) | Tag 2 | Fünf defekte Deployments untersuchen und reparieren | 35 Min. |
| [4: Auf GKE](lab04-gke/README.md) | Tag 2 | Artifact Registry, Kontextwechsel, Konsole | 60 Min. |
| [5: Abschluss](lab05-abschluss/README.md) | Tag 3 | Manifest vervollständigen, drei Releases reparieren, Rollback | 90 Min. |
| [6: Betrieb](lab06-betrieb/README.md) | Tag 3, parallel zu Lab 5 | Cluster lesen, lokal cordon/uncordon und PDB untersuchen | 90 Min. |
| [7: Störungssuche](lab07-stoerungen/README.md) | Tag 3 | Störungen über Logs, Events und Logs Explorer finden | 60 Min. |

## Voraussetzungen

Installationsanleitung für Windows mit WSL2, macOS und Linux: [VORBEREITUNG.md](VORBEREITUNG.md). `bash scripts/setup.sh` installiert fehlende Werkzeuge außer Docker. Wir richten die Rechner gemeinsam am Morgen von Tag 1 ein.

Docker mit laufendem Daemon, Buildx, minikube, kubectl, Git, curl und Python 3.9 oder neuer. Java und Maven laufen im Docker-Build und müssen nicht lokal installiert sein. Unter Windows arbeitet ihr in Bash unter WSL2 mit Docker-Integration. Legt den Klon im Linux-Home ab.

Plant für den lokalen Cluster 2 CPUs und 4 GiB freien Arbeitsspeicher ein, zusätzlich zu Docker und euren anderen Anwendungen. Downloads brauchen Zugriff auf GitHub, Maven Central, Docker Hub und die Kubernetes-Registries. Für GKE kommen gcloud, das GKE-Auth-Plugin und ein vom Trainer vorbereiteter Zugang hinzu.

## Einstieg

```bash
git clone -b practice https://github.com/juice1000/gke-workshop.git
cd gke-workshop
bash lab00-check/check.sh
```

Danach mit [Lab 0](lab00-check/README.md) fortfahren. Alle Befehle in den READMEs werden aus dem Repository-Hauptordner ausgeführt, sofern kein anderer Ordner genannt ist.

Die Checkpoints melden `OK:` oder `FEHLT:` mit einem Hinweis. Exit-Code `0` bedeutet bestanden, `1` bedeutet mindestens eine fehlgeschlagene Prüfung. Sie lesen den Cluster und öffnen kurz einen lokalen HTTP-Tunnel. Sie rollen nichts aus und reparieren nichts.

## Eine Anwendung für den ganzen Kurs

```text
Dockerfile -> hallo-app:1.0 -> minikube
           -> hallo-app:2.0 -> Artifact Registry -> GKE
                              Deployment -> Pods <- Service
                              ConfigMap + Secret + Probes
```

`/` nennt Begrüßung, Pod und Version. Actuator liefert Health-Endpunkte. `/fehler` erzeugt einen absichtlichen HTTP-500-Fehler und eine Logzeile mit `FEHLER`. Das Übungs-Secret enthält keine echten Zugangsdaten. Es gibt keine Datenbank.

Die Anwendung ist textbasiert. So bleiben Kubernetes und die Fehlersuche im Mittelpunkt. Services sind vom Typ `ClusterIP`; der Zugriff erfolgt per `port-forward`.

## Für den Trainer

- Auf diesem vorbereiteten Rechner: `source scripts/workshop-env.sh`. Das lädt die Werkzeuge aus `.cache/bin`, die eigene Workshop-kubeconfig und die gcloud-Konfiguration `gke-workshop`. Mit `workshop_local` und `workshop_gke` zwischen den Umgebungen wechseln. Details stehen im [Runbook](trainer/RUNBOOK.md).
- [Cloud-Vorbereitung, Zugriffe und Aufräumen](trainer/README.md)

```bash
bash scripts/validate.sh   # ShellCheck, Dateiverweise, Kubernetes-Schemas
bash scripts/dry-run.sh    # eigene lokale Testumgebung, inklusive Fehler und Reparaturen
```

Der Probelauf baut beide Images und startet ein eigenes minikube-Profil. Er benutzt eine separate kubeconfig und entfernt sein Profil am Ende. Der erste Lauf braucht mehrere Downloads. Die GitHub-Actions-Checks führen dieselben Prüfungen aus. Ein lokaler Erfolg ersetzt den GKE-Probelauf vor dem Kurs nicht.
