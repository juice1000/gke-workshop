# Cloud-Umgebung vorbereiten

Diese Schritte gehören zur Vorbereitung durch den Trainer. Teilnehmende erstellen keine Cluster, Node-Pools oder IAM-Bindings. Das Repository provisioniert keine kostenpflichtige Infrastruktur automatisch. Eine Befehlsfolge zum Abarbeiten steht im [Runbook](RUNBOOK.md).

## Vorbereitete Trainerumgebung

Projekt `lookbeyond-gke-workshop`, Standard-Cluster `workshop` in `europe-west3-b`, Artifact-Registry-Repository `workshop` in `europe-west3`. Einstieg auf dem vorbereiteten Rechner: `source scripts/workshop-env.sh`, danach `workshop_gke` oder `workshop_local`.

Der Cluster nutzt den Node-Pool `kurs` mit `e2-standard-4`, 50 GB Balanced-Persistent-Disk. Bis zum Cloud-Teil läuft ein Node, während des Kurses drei. Die Rechnung dazu steht im [Runbook](RUNBOOK.md#kurs-node-pool-umgesetzt-am-21112026). Die Anwendung liegt im Namespace `workshop-trainer`. Die Namespaces `workshop-person01` und `workshop-person02` enthalten Entwicklerrollen mit isolierten Kubernetes-Testidentitäten. Teilnehmerkonten werden am Abend von Tag 1 mit [teilnehmer-anlegen.sh](teilnehmer-anlegen.sh) aus der Kontoliste gebunden.

Der Node verwendet ein eigenes IAM-Servicekonto mit der GKE-Node-Rolle und Leserecht am Workshop-Repository. Workload Identity Federation ist aktiviert. API-Zugriffe erfolgen über den DNS-Endpunkt; IP-basierter API-Zugriff ist deaktiviert. Die Anwendung bleibt als `ClusterIP` erreichbar und wird zum Testen per Port-Forward geöffnet.

## Vor dem Kurs

1. Ein eigenes Übungsprojekt mit geklärter Abrechnung und einem GKE-Cluster bereitstellen. Standard ist der geplante Kursmodus. Autopilot ist als weitere Variante vorgesehen und braucht einen eigenen Probelauf.
2. Kubernetes-Version und eine dazu passende kubectl-Version festlegen. Der lokale Probelauf verwendet Kubernetes 1.35.0; die GKE-Version richtet sich nach dem vorbereiteten Cluster und Release Channel.
3. Netzwerkzugang aus dem Kundennetz zum API-Endpunkt testen. Bei privaten Clustern den tatsächlichen VPN-/Proxy-Zugang mit dem Kunden durchspielen. Cloud Shell ist ein möglicher CLI-Fallback, ersetzt aber nicht ohne Weiteres den lokalen Docker-Build.
4. Kubernetes Engine und Artifact Registry verfügbar machen, ein Docker-Repository anlegen. Anwendungslogs und Systemmetriken aktivieren. In der Konsole einen aktuellen Testeintrag und Container-Metriken nachweisen.
5. Je Person einen Namespace und eine abgegrenzte Rolle vorbereiten. Zwei echte Testkonten verwenden, nicht nur das eigene Admin-Konto.
6. Für jeden Rollout Kapazität für drei Pods je Person einplanen: zwei gesunde Pods plus ein neuer Pod. Die Basis fordert zusammen bis zu 750m CPU und 1536 MiB Speicher je gleichzeitigem Rollout. Release B reserviert 512 MiB für den fehlerhaften Pod und braucht nach der Reparatur bis zu 1 GiB Limit für diesen Pod.
7. Ein vorgebautes Image für die tatsächliche Node-Architektur bereithalten. Artifact-Registry-Push und Image-Pull unabhängig voneinander testen.

## Zugriffsmodell

| Identität | Aufgabe | Benötigter Zugriff |
| --- | --- | --- |
| Teilnehmerkonto | Clusterverbindung aufbauen | z. B. IAM `roles/container.clusterViewer` für die Cluster-Metadaten, zusätzlich Namespace-RBAC |
| Teilnehmerkonto | Eigenes Image hochladen | `roles/artifactregistry.writer` am Übungsrepository |
| GKE-Node-Servicekonto | Private Images laden | `roles/artifactregistry.reader` am Repository, passende Node-OAuth-Scopes bei Standard |
| Teilnehmerkonto oder Trainerdemo | Logs Explorer | `roles/logging.viewer` im Übungsprojekt |
| Teilnehmerkonto oder Trainerdemo | Monitoring ansehen | `roles/monitoring.viewer` im Übungsprojekt |
| Anwendungs-Pod | Antworten und Health liefern | Kein Zugriff auf Cloud-APIs nötig |

Die genauen Freigaben richten sich nach den Organisationsrichtlinien. Logging- und Monitoring-Viewer sind keine Namespace-Rollen. Falls projektweite Sicht nicht vorgesehen ist, zeigt der Trainer diese Bereiche als Demo. Auch die Workload-Ansicht der Konsole kann zusätzliche Leserechte erwarten. Prüft den Rundgang mit einem Teilnehmerkonto und dokumentiert jede Abweichung.

Gebt keine projektweiten Rollen wie Owner, Editor oder Kubernetes Engine Developer nur zur Vereinfachung der Übung. IAM und RBAC können auf GKE beide Kubernetes-Aktionen erlauben. Eine enge RoleBinding nimmt anderweitig durch IAM gewährte Rechte nicht zurück.

## Namespace und RBAC-Vorlagen

[namespace.yaml](namespace.yaml) und [rbac.yaml](rbac.yaml) sind Kopiervorlagen für einen Teilnehmer. Kopiert sie nach `out/trainer/person01/`, ersetzt `workshop-person01` in allen Dateien und `TEILNEHMER_KONTO_ERSETZEN` durch die angemeldete Google-Konto-Adresse. Vor dem Anwenden die Arbeitskopien lesen.

Mit dem ausdrücklich festgelegten Trainer-Kontext:

```bash
kubectl --context "$TRAINER_CONTEXT" apply -f out/trainer/person01/namespace.yaml
kubectl --context "$TRAINER_CONTEXT" apply -f out/trainer/person01/rbac.yaml
```

Die Role erlaubt die Workload-Übungen im jeweiligen Namespace, Logs, `exec`, `port-forward` und das Lesen von EndpointSlices. Sie erlaubt keine Node-Änderungen und keine RoleBindings. Secrets sind absichtlich im eigenen Übungsnamespace lesbar und schreibbar. Dort liegen ausschließlich Übungswerte.

Mit dem echten Teilnehmerkonto prüfen:

```bash
kubectl auth can-i create deployments.apps -n workshop-person01
kubectl auth can-i get secrets -n workshop-person01
kubectl auth can-i create deployments.apps -n kube-system
kubectl auth can-i create deployments.apps -n workshop-person02
kubectl auth can-i patch nodes
```

Erwartet: `yes`, `yes`, `no`, `no`, `no`. Prüft zusätzlich mit `kubectl auth can-i --list -n workshop-person01`, ob weitere Freigaben vorhanden sind. Die lokale Integration prüft die RBAC-Vorlage per Impersonation, sie prüft keine Google-IAM-Policy.

## GKE-Probelauf

- Lab 4 vollständig als Teilnehmer durchspielen. Registry und Cluster können unterschiedliche Standorte haben.
- Beide Konten gleichzeitig einsetzen und die Trennung der Namespaces nachweisen. Ein eigener Image-Name pro Namespace verhindert Tag-Kollisionen.
- Die gerenderten Lösungen aus Lab 5 (Branch `main`) anwenden und alle drei Fehlerbilder auslösen. Bei B muss `OOMKilled` aus dem Containerzustand belegbar sein. Die Autopilot-Admission darf die beabsichtigte Knappheit nicht aufheben; falls Regeln das Manifest ablehnen oder anpassen, die Übung vorab passend ändern.
- Nach jedem fehlgeschlagenen Rollout zwei alte bereite Pods und eine funktionierende HTTP-Antwort nachweisen. Danach Rollback und Reparatur prüfen.
- `/fehler` aufrufen. Die Logzeile über Cluster und Namespace filtern. Im Monitoring CPU, Speicher und `kubernetes.io/container/restart_count` mit passenden Filtern finden. Logs und Metriken brauchen eventuell Zeit bis zur Anzeige.

Es gibt in den Labs keinen öffentlichen LoadBalancer. Das vereinfacht Netzwerk und Kosten. Einen zusätzlichen öffentlichen Zugriff nur als separat abgestimmte Erweiterung vorbereiten.

## Cloud-Fallback

Lab 4 als Trainerdemo zeigen. Lab 5 A/B lokal in minikube mit `IMAGE=hallo-app:2.0` ausführen. Lab 6 Teil 2/3 ebenfalls lokal. Die Aufgaben zur Cloud-Konsole und zu IAM gemeinsam an der Demo erklären. Die lokalen Anweisungen stehen in den jeweiligen READMEs.

## Nach dem Kurs

Teilnehmende löschen ihre Workloads, ConfigMaps und Übungs-Secrets gemäß den Labs. Danach als Trainer mit festem Kontext je vorbereitetem Übungsnamespace die verbleibenden Ressourcen ansehen und den Namespace entfernen:

```bash
kubectl --context "$TRAINER_CONTEXT" -n workshop-person01 get deployment,pods,service,configmap,secret
kubectl --context "$TRAINER_CONTEXT" delete namespace workshop-person01
```

Dieser Löschschritt entfernt den gesamten gewählten Namespace. Anschließend temporäre Projekt-/Repository-IAM-Bindings entfernen. Registry-Images und den eigens bereitgestellten Übungscluster nach dem vereinbarten Aufbewahrungszeitraum im richtigen Projekt entfernen. Namespace-Löschung beendet keine Clusterkosten und löscht keine Registry-Images. Falls außerhalb des Kernlabs öffentliche Services angelegt wurden, deren Load-Balancer-Ressourcen ebenfalls prüfen.

## Primärquellen

- [GKE-Zugriff mit kubectl und Auth-Plugin](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl)
- [GKE-RBAC und Zusammenspiel mit IAM](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control)
- [Artifact-Registry-Zugriffssteuerung](https://docs.cloud.google.com/artifact-registry/docs/access-control)
- [Ressourcenanforderungen in Autopilot](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/autopilot-resource-requests)
- [GKE-Anwendungslogs](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/about-logs)
- [Monitoring von Neustarts](https://docs.cloud.google.com/kubernetes-engine/docs/troubleshooting/introduction-monitoring)
