# 01 Kontext

## Kunde

S-Management Services GmbH, ein Unternehmen der Sparkassen-Finanzgruppe. Die Schulung ist für das gesamte Ressort gedacht, nicht nur für ein Projekt.

## Ansprechpersonen

| Person | Rolle | Relevanz |
|---|---|---|
| Sascha Blessing | Chapter Lead | vermittelt, organisiert, technisch weit weg |
| Michael Tischler | technisch verantwortlich für ein Projekt | wichtigster fachlicher Ansprechpartner, Entwicklersicht |
| Sascha Smolin | Systemadministration / Ops | Lernumgebung (Installationen, Netzwerk), eigene Ops-Sicht |

Alle duzen sich.

## Beauftragung

- Basis ist der GFU-Kurs S5549 (GKE Einführung). Ein eigenes Curriculum ist erlaubt.
- Es ist die erste Schulung dieser Art mit GFU für das Ressort. Ein Nachbarressort hatte bereits eine Schulung.
- Zum Zeitpunkt des Vorgesprächs war die Schulung noch nicht bestätigt (Discovery-Phase). Der Kunde sammelt Interessenten und schärft danach das Konzept nach.
- Teilnahme ist freiwillig, keine Pflichtveranstaltung.
- Umfang: 3 Tage (ursprünglich als 2 Tage angenommen, in der Vorbereitung auf 3 korrigiert).

## Technologie-Stand beim Kunden

| Bereich | Stand |
|---|---|
| Cloud | Google Cloud, faktisch verpflichtend, weil der Infrastrukturanbieter eine andere Tochter der Sparkassen-Finanzgruppe ist |
| Projekte | sehr unterschiedlich: noch On-Premise, im Umzug, bereits komplett in der Cloud |
| Backend | Spring Boot |
| Frontend | React; zusätzlich eine Python-Anwendung mit React-Frontend |
| Container | alles containerisiert |
| Build | TeamCity (selbst gehostet), Umstellung auf Config as Code (YAML) läuft, nicht überall |
| Code-Hosting | Gitti (selbst gehostet, laut Aussage im Prinzip wie GitHub) |
| Artefakte | Artifactory (selbst gehostet), danach Google Artifact Registry |
| Qualität | Sonar (untergeordnet) |
| Laufzeit | Kubernetes in einer Virtual Private Cloud |
| Infrastruktur als Code | Terraform wird vom Infrastrukturanbieter gepflegt; Teams ändern nur innerhalb ihrer Services per YAML |
| KI | GitHub Copilot ist im Einsatz |

Pipeline laut Kunde: Build in TeamCity, Artefakt nach Artifactory, von dort in die Google Registry, ab dort Deployment.

## Wissensstand der Teilnehmenden

- Spanne von Junior bis Senior, "mit und ohne Führung".
- Fokus der Schulung sind die Schwächeren, nicht die wenigen Expertinnen und Experten.
- Es gibt wenig echtes DevOps. Zwischen Entwicklung und Ops fehlt Expertise, genau dorthin soll sich das Team entwickeln.
- GitHub kennen nicht alle gleich gut. Sascha Smolin nutzt es selten.
- Teilnehmerliste mit Rollen und Kenntnisstand wurde vom Kunden zugesagt, liegt noch nicht vor.

## Rahmen für die Durchführung

- Annahme: 09:00 bis 16:30 Uhr mit 60 Minuten Mittag (noch zu bestätigen).
- Sprache: Deutsch.
- Format und Ort (Präsenz oder remote) sind noch offen.
