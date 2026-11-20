# 04 Lernumgebung und offene Punkte

## Lernumgebung

### Lokal (Tag 1, Teile von Tag 2)

- Docker und minikube (Docker-Treiber) auf den Rechnern der Teilnehmenden.
- Die Lab-Umsetzung verwendet Bash, kubectl, curl, Git und Python ab 3.9. Unter Windows ist WSL2 mit Docker-Integration vorgesehen. Diese Voraussetzungen müssen Teil der Vorabprüfung mit der IT sein. Java und Maven laufen im Docker-Build.
- Offen: Dürfen die Teilnehmenden Docker und minikube installieren? Gibt es einen Proxy, der Image-Pulls und Downloads blockiert? Läuft alles auf Firmenlaptops mit Einschränkungen?
- Klärung läuft mit Sascha Smolin (Ops).
- Wichtig: Der Setup-Check (Lab 0) am Anfang von Tag 1 fängt Probleme ab, ersetzt aber keine Vorabprüfung.

### Cloud (ab Tag 2 Nachmittag, Tag 3)

- Der IT-Dienstleister des Kunden stellt keine Sandbox rechtzeitig bereit.
- GitHub-Accounts sind laut Kunde machbar, Michael Tischler wünscht, dass alle vorab einen Account haben.
- Möglichkeit: eigenes Google-Cloud-Projekt von Look Beyond. Nicht geklärt ist, ob die Rechner der Teilnehmenden aus dem Firmennetz dorthin kommen (Netzwerkzugriff, Proxy, Sicherheitsrichtlinien) und wie Zugriffe und Kosten pro Person abgegrenzt werden (Namespace pro Person, IAM).
- Fallback, wenn keine Cloud erreichbar ist: GKE-Teile als geführte Demo durch den Trainer, Teilnehmende arbeiten weiter lokal. Dieser Fallback ist in den Lecturer-Notizen vorbereitet, aber noch nicht im Detail ausgearbeitet.

### GKE-Modus

Der Kunde plant mit Standard (ZIMDB Plus) und prüft Autopilot. Die Labs sind so geschrieben, dass sie in beiden Modi laufen sollen. GKE-Standard und Autopilot brauchen jeweils einen echten Probelauf. Der aktuelle lokale Nachweis und die ausstehenden Cloud-Prüfungen stehen in [07-teststatus.md](07-teststatus.md).

## Offene Punkte

| Punkt | Wer | Status |
|---|---|---|
| Teilnehmerliste mit Rollen und Kenntnisstand | Kunde (Tischler, Blessing) | zugesagt, offen |
| Termine und Format (Präsenz oder remote) | Kunde | offen |
| Bestätigung der Schulung, Teilnehmerzahl | Kunde | offen, Interessentenabfrage läuft |
| Docker und minikube auf Teilnehmer-Rechnern, Proxy | Smolin | offen |
| Cloud-Sandbox oder eigenes Projekt, Netzwerkzugriff | Julien und Kunde | offen |
| GitHub-Accounts der Teilnehmenden | Kunde | als machbar bezeichnet |
| Vertragsweg (GFU oder direkt), Sprache der Unterlagen | Julien | offen |
| Zweiter Abstimmungstermin | Kunde schlägt vor | Einladung zugesagt |
| Agenda für Tag 1 bis 3 an Smolin | Julien | in Arbeit |

## Risiken

| Risiko | Gegenmaßnahme |
|---|---|
| Kein Cloud-Zugang | Demo-Fallback; lokale Labs sind eigenständig |
| Lokale Installation scheitert | Setup-Check, Vorabprüfung mit Smolin, ggf. vorbereitete Anleitung |
| Sehr gemischtes Niveau | Pufferzeiten, Zusatzaufgaben für Fortgeschrittene, Streichlisten |
| Zu viel Stoff | Kernprogramm klein halten, Optionales klar abgrenzen |
| Befehle und Labs ungetestet | Alles vor dem Workshop mit minikube und GKE durchspielen |
| Faktenstand | Nicht verifiziert (siehe unten) |

## Verifikation der Umsetzung

Die ursprüngliche Planung enthielt die folgenden Prüfpunkte. Aktuelle Ergebnisse und noch offene Nachweise stehen in [07-teststatus.md](07-teststatus.md):

- Probe-Intervalle und Schwellwerte: in den Manifesten ausdrücklich gesetzt, siehe [Lab 2](../lab02-hallo-app/README.md)
- Menünamen der Google-Cloud-Konsole und die Bezeichnung "Google Cloud Observability"
- Details zu Extended-Channel und Upgrade-Strategien von Node Pools
- JVM-Speicherfall: Release B nutzt nun einen fest vorbelegten Heap ohne Platz für JVM-Nebenspeicher, siehe [Lab 5](../lab05-abschluss/README.md)
- Sichtbarkeit von Container-Restarts in den Metriken
- Label des CoreDNS-Pods (`k8s-app=kube-dns`)
- Mindestanforderungen von minikube an die Hardware
