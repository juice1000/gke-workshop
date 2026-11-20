# Teststatus

Stand: 17.11.2026. Dieser Status trennt lokale Laufzeitprüfungen von noch nötigen Cloud-Prüfungen.

## Lokale Prüfungen

`bash scripts/validate.sh` und `bash scripts/dry-run.sh` sind lokal erfolgreich durchgelaufen.

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

## Vor Durchführung noch nötig

- [ ] Alle Cloud-Schritte in einem echten GKE-Standard-Cluster mit Teilnehmerkonten ausführen.
- [ ] Autopilot separat testen, wenn dieser Modus im Kurs verwendet werden soll. Admission-Änderungen, Speicherfall und Wartezeiten dokumentieren.
- [ ] Registry-Push und privater Image-Pull mit der tatsächlichen Node-Identität prüfen.
- [ ] Test mit zwei Teilnehmerkonten und getrennten Namespaces; IAM darf die RBAC-Trennung nicht aufheben.
- [ ] Logs Explorer, CPU-/Speicher-Metriken und Restart-Metrik mit Teilnehmerrechten nachweisen.
- [ ] Konsolennavigation, Release Channel, Wartungsfenster und Node-Pools im tatsächlichen Projekt prüfen.
- [ ] Frischen Windows-/WSL-Rechner einschließlich Proxy, Docker-Integration und Registryzugriff testen.
- [ ] Noch offene Kursdetails aus [Lernumgebung](04-lernumgebung-und-offene-punkte.md) mit dem Kunden klären.
- [ ] Notion-Differenzen aus [Lab-Zuordnung](06-labs-und-trainer.md) in die Kursunterlagen übernehmen.

Lokale Läufe beweisen keine GKE-IAM-Freigaben, Cloud-Kosten, Autopilot-Admission oder Verfügbarkeit der Konsole.
