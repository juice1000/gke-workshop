# Labs und Trainerhinweise

## Didaktik

Die Labs übernehmen die Struktur des IaC-Workshops: kleine Ordner, deutsche Aufgaben, beobachtbare Ergebnisse, Checkpoints und direkt auffindbare Lösungen. Statt eines separaten `start`-Branches liegen unvollständige Starter und Lösungen nebeneinander. So bleiben Übungen und Lösungen in einem gemeinsamen Prüfablauf.

Die ersten beiden Labs sind geführt. Lab 3 gibt ein festes Diagnoseverfahren vor, nennt die Ursache erst in der Auflösung. Lab 5 fordert das Schreiben der zuvor verwendeten Felder. Ein Repository allein ersetzt keine Erklärung: vor jeder Änderung den erwarteten Zustand abfragen und danach den Beleg ansehen.

Alle Befehle werden aus dem Repository-Hauptordner ausgeführt. Die Übungsanwendung und die Objektnamen bleiben gleich. Lab 3 verwendet eigene Namen. Auf GKE arbeitet jede Person oder Gruppe in einem eigenen Namespace und nutzt einen eigenen Image-Namen.

## Zuordnung zur vorhandenen Notion-Fassung

| Kapitel | Repository | Notion |
| --- | --- | --- |
| 1.1 Setup | `lab00-check` | [Tag 1](https://app.notion.com/p/41b7a614759581e58d69d201411d07e1) |
| 1.5 kubectl | `lab01-kubectl` | [Lab 1](https://app.notion.com/p/41b7a61475958119aacaec95d227da24) |
| 1.6 Anwendung lokal | `lab02-hallo-app/k8s` | [Lab 2](https://app.notion.com/p/41b7a6147595815d8cd6fc39ede576a9) |
| 2.2 bis 2.4 Betrieb | `lab02-hallo-app/betrieb` | [Tag 2](https://app.notion.com/p/41b7a614759581b3a351dd044517c281) |
| 2.5 Fehlersuche | `lab03-defekt` | [Lab 3](https://app.notion.com/p/41b7a614759581d088dbc3e0d76a2531) |
| 2.8 GKE | `lab04-gke` | [Lab 4](https://app.notion.com/p/41b7a61475958122b72bfe6684c0ada6) |
| 3.2 Beobachtung | Lab 4 Abschnitt 6, Pipeline-Cheat-Sheet | [Tag 3](https://app.notion.com/p/41b7a61475958152a452ee3523787434) |
| 3.5 Abschluss | `lab05-abschluss` | [Lab 5](https://app.notion.com/p/41b7a614759581e3a5aada0b4749c2ff) |
| 3.6 Betrieb | `lab06-betrieb` | [Lab 6](https://app.notion.com/p/41b7a614759581a0b0a7f5e9e0c02041) |

Die folgenden Unterschiede wurden am 21.11.2026 in die Notion-Kapitel übernommen. Die Theorie in Notion blieb, Lab-Schritte, Lösungen und Trainerhinweise folgen jetzt den READMEs. Die Seite "Repository und Lernumgebung" entspricht [VORBEREITUNG.md](../VORBEREITUNG.md). Zusätzlich geändert: kein GitHub-Konto nötig, kein öffentlicher LoadBalancer als Bonus in Lab 4, Google-Konten werden in 1.1 eingesammelt. Bei späteren Änderungen an den Labs beide Stellen anpassen.

- Ein lokaler Namespace `workshop` statt Übungen in `default`.
- Der Pod-Name wird ausdrücklich über `fieldRef: metadata.name` als `HOSTNAME` gesetzt. Das vermeidet die Abhängigkeit von einer automatisch gesetzten Container-Umgebungsvariable.
- Befehle laufen aus dem Repository-Hauptordner, der Docker-Build bekommt `lab02-hallo-app` als Kontext.
- Die Tag-2-Manifeste liegen vollständig unter `lab02-hallo-app/betrieb/`.
- Cloud-Images tragen einen gruppenspezifischen Namen und werden für die tatsächliche Node-Architektur gebaut.
- Der vorbereitete GKE-Cluster verwendet DNS-basierten API-Zugriff. Die Verbindungsbefehle nutzen ausdrücklich `--dns-endpoint`. IP-basierter API-Zugriff ist dort deaktiviert.
- Der Maven-Build verwendet die native Build-Plattform. Das portable Java-Archiv wird in das Laufzeitimage der Zielplattform kopiert. So funktioniert der amd64-Build auch auf ARM-Laptops ohne x86-Emulation.
- `scripts/render.py` erstellt Arbeitskopien mit passendem Image. Dadurch bleiben Registry-Platzhalter nicht versehentlich im Cluster.
- Cloud-Deployments geben neuen Nodes und Image-Pulls ein Fortschrittsbudget von zehn Minuten. Die absichtlichen Fehler-Rollouts werden weiterhin nach 60 Sekunden untersucht.
- Release B nutzt einen fest vorbelegten 512-MiB-Heap bei 512-MiB-Containerlimit. Die Korrektur erhöht das Limit auf 1 GiB. Das ersetzt das unzuverlässigere Beispiel mit 64 MiB, das auf Autopilot auch angepasst oder abgelehnt werden könnte.
- Vor jedem neuen Release in Lab 5 wird der gesunde Starter wieder angewendet. `rollout undo` zeigt sonst auf den jeweils letzten Stand, nicht zwingend auf den ursprünglichen Ausgangszustand.
- EndpointSlices ersetzen die Betrachtung alter Endpoints-Objekte. Unbereite Adressen können weiterhin enthalten sein, entscheidend ist `conditions.ready`.
- Das PDB begrenzt bestimmte freiwillige Unterbrechungen. Es schützt weder vor jedem Ausfall noch vor direktem Pod-Löschen.

## Beobachtungspunkte

| Zeitpunkt | Beleg | Falls jemand hängt |
| --- | --- | --- |
| Lab 0 fertig | Ready-Node, richtiger Kontext/Namespace | Netzwerk oder Docker gemeinsam prüfen; Paarbildung |
| Lab 2 deployt | zwei Pods plus HTTP-Antwort | Image-Load, Labels und Ports prüfen |
| Tag 2 Konfiguration | geänderte Begrüßung nach Rollout | Env-Werte werden erst beim Start gesetzt |
| Lab 3 je Fall | Symptom und eine Event-/Logzeile | Nach dem Diagnosebefehl fragen, keine Lösung vorwegnehmen |
| Lab 4 Push | Digest in der Push-Ausgabe | Push-Recht, Docker-Login, Proxy und Zielarchitektur trennen |
| Lab 5 A | `pruefen.py abschluss` grün | Muster aus Lab 2, notfalls gerenderte Lösung |
| Lab 5 B | alter Service funktioniert trotz Fehler | neue Pods gezielt untersuchen, `maxUnavailable` erklären |
| Lab 6 fertig | Node wieder entsperrt | `uncordon` vor dem Wechsel zur nächsten Aufgabe |

## Kürzungen und Vertiefungen

Tag 1: HTTP und Selbstheilung priorisieren. Dashboard, Lastverteilung und zusätzliche `exec`-Befehle bei Bedarf kurz halten.

Tag 2: ConfigMap, Readiness, Requests, Rollback und zwei Troubleshooting-Fälle gemeinsam sicher abschließen. Fälle 3 bis 5 an Paare verteilen und im Plenum besprechen, wenn die Zeit knapp wird. GKE muss nicht durch Cluster-Erstellung erweitert werden.

Tag 3: Abschluss A und mindestens zwei fehlerhafte Releases haben Vorrang. Rechteprüfung kann als gemeinsame Demo erfolgen. Lab 6 ist ein paralleles Angebot, kein Zusatzblock für alle.

Schnelle Gruppen erklären sich gegenseitig den Unterschied zwischen Container-Restart und neuem Pod, prüfen Service-Bereitschaft mit EndpointSlices oder beschreiben einen konkreten Alarm. Keine Erweiterung auf Helm, Service Mesh oder GitOps im Kernprogramm.

## Prüfwerkzeuge

`scripts/validate.sh` prüft ShellCheck, Python-Syntax, lokale Dateiverweise und die Kubernetes-Schemas aller Manifeste. Starter und Fehlerfälle sind syntaktisch gültig, enthalten aber absichtlich funktionale Fehler. Ein grüner Schema-Check beweist daher keinen funktionierenden Workload.

`scripts/dry-run.sh` erstellt ein eigenes minikube-Profil mit separater kubeconfig. Der Integrationslauf prüft gute Zustände, beabsichtigte Fehler, Reparaturen, Rollbacks, Namespace-RBAC und das lokale Node-Experiment. `EXIT`, `INT` und `TERM` lösen das Entfernen des eigenen Profils aus. Bei einem Fehler bleiben Diagnosedateien in `.cache/dry-run.*`. Container-Images und Download-Caches bleiben erhalten, damit weitere Läufe schneller sind.

`scripts/pruefen.py` ist für Teilnehmende. Es repariert keine Ressourcen. Für HTTP öffnet es einen kurzlebigen Tunnel auf Loopback. Ein Checkpoint kann noch fehlschlagen, während ein Rollout läuft; zuerst `rollout status` abwarten.

Die Docker-Basisimages sind nach dem geprüften Stand per Digest fixiert. Vor einem späteren Kurstermin Abhängigkeiten und Basisimages aktualisieren und den Probelauf erneut ausführen.
