# 02 Bedarf und Lernziele

## Ausgangslage

Der Kunde hat Kubernetes "für sich entdeckt" und bewegt sich immer stärker in diese Richtung. Ob Kubernetes für jede Anwendung die richtige Wahl ist, wurde nicht für jede geprüft. Serverless statt Kubernetes umzustellen halten die Ansprechpersonen für schwierig, an einzelnen Stellen aber denkbar. Die Schulung soll Kubernetes auf GKE verständlich machen, nicht die Plattformentscheidung neu verhandeln.

## Hauptbedarf (Aussagen aus dem Vorgespräch)

1. **Grundverständnis**: Was gehört zu einem Kubernetes-Cluster und was nicht? Die Webkonsole wirkt wegen Logging, Security usw. erschlagend. Es braucht eine klare Abgrenzung.
2. **Verantwortung**: Was übernimmt der Cluster (bzw. GKE) für mich, worauf muss ich selbst achten?
3. **Fehlersuche**: Wenn ein Pod hundertmal neu startet, wo schaue ich hin? Welche Themen stecken dahinter?
4. **Zusammenhang CLI und Konsole**: gcloud und kubectl neben der Webkonsole zeigen. Wenn ich per kubectl etwas ausrolle, sehe ich es in der Konsole unter Workloads, Services und Logs. Weg vom Kopieren unverstandener Befehle.
5. **Ops-Sicht** (Sascha Smolin): in der Google-Cloud-Konsole wissen, wo bei Troubleshooting nachzuschauen ist, damit administrative Aufgaben besser verfolgt werden können.
6. **Orientierung im Produktangebot**: Google Cloud hat viele Produkte, einige sind Legacy. Klären, was tagesaktuell ist und was für ein minimales Setup relevant ist.

## Nebenwünsche

- Terraform kurz einordnen (Zusammenhang, nicht Fokus), da der Infrastrukturanbieter es pflegt.
- Wo passend, KI-gestützt arbeiten (Copilot ist verbreitet); individuell abfragen, wie die Teilnehmenden vorgehen.
- Möglichst Trennung zwischen Inhalten für alle und Ops-Spezialthemen, etwa ein Tag gemeinsam, Ops-Themen separat oder als Vertiefung.

## Zielgruppe

Entwicklerinnen und Entwickler (Schwerpunkt), einzelne Ops-Kolleginnen und -Kollegen. Heterogenes Niveau, Juniors ausdrücklich im Blick. Kubernetes-Vorwissen ist vermutlich gering bis nicht vorhanden. Docker und YAML sind vorhanden (Container, TeamCity-Konfiguration).

## Lernziele nach Tag 3

Nach der Aussage von Michael Tischler, in Kursform übersetzt. Die Teilnehmenden können:

- die Kernbausteine (Pod, Deployment, Service, ConfigMap, Secret, Namespace) erklären und in YAML schreiben und lesen
- mit kubectl sicher arbeiten und beim Troubleshooting systematisch vorgehen (get, describe, logs, events)
- erklären, was GKE übernimmt (Control Plane, Upgrades, Integration) und was in ihrer Verantwortung bleibt
- eine Anwendung auf GKE deployen und dieselben Objekte in der Webkonsole wiederfinden
- Logs und Metriken in Cloud Logging und Cloud Monitoring finden
- den Unterschied zwischen IAM (Google Cloud) und RBAC (Kubernetes) benennen
- einordnen, wo ihre bestehende Pipeline (TeamCity, Artifactory, Registry) an Kubernetes andockt

## Nicht-Ziele

- Keine GitHub-Einführung. Tooling wird vorab abgestimmt, damit die Zeit für Kubernetes bleibt.
- Kein Terraform-Hands-on.
- Keine Tiefe zu Service Mesh, GitOps, Storage und Autoscaling im Kernprogramm (nur als optionale Vertiefung).
