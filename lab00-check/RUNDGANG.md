# Rundgang: Das minikube-Dashboard

Das Dashboard ist eine Weboberfläche für euren Cluster. Es zeigt dieselben Objekte wie kubectl, nur als Bild: Pods, Deployments, Services, Events, Logs. Wir nutzen es an Tag 1 und 2 zum **Anschauen**. Geändert wird mit Dateien und `kubectl apply`.

Die Oberfläche ist auf Englisch. Die Begriffe sind dieselben wie in kubectl, deshalb lassen wir sie so.

## Starten

```bash
minikube dashboard
```

- Öffnet das Dashboard im Browser. Das Terminal bleibt dabei belegt, beendet wird mit Strg+C. Für alles andere ein zweites Terminal öffnen.
- Öffnet sich kein Browser: `minikube dashboard --url` und die ausgegebene Adresse von Hand im Browser öffnen.
- Die Adresse beginnt mit `http://127.0.0.1:` und einem zufälligen Port. Sie gilt nur auf eurem Rechner und nur, solange der Befehl läuft.

## Der Aufbau

| Bereich | Wo | Wofür |
| --- | --- | --- |
| Namespace-Auswahl | oben links | Welcher Namespace angezeigt wird. Beim Start steht dort `default`. Für unsere Labs `workshop` wählen, zum Stöbern `All namespaces` |
| Suche | oben Mitte | Sucht Objekte nach Namen |
| Plus-Symbol | oben rechts | Objekte anlegen (Create from input, file oder form). Nutzen wir nicht |
| Navigation | links | Alle Objektarten, in Gruppen sortiert |
| Aktionen | rechts in der blauen Leiste | Erscheinen auf Detailseiten, je nach Objekt (Logs, Exec, Scale, Edit, Delete) |

Die Navigation links hat vier Gruppen. Ein kleines **N** neben einem Eintrag heißt: Diese Objekte gehören zu einem Namespace, die Liste hängt also von der Auswahl oben links ab.

| Gruppe | Wichtig für uns |
| --- | --- |
| Workloads | Deployments, Pods, Replica Sets. Hier verbringt ihr die meiste Zeit |
| Service | Services. Ingresses kommen nur in den Vertiefungen vor |
| Config and Storage | Config Maps und Secrets (Tag 2) |
| Cluster | Events, Namespaces, Nodes. Rollen und Service Accounts kommen an Tag 3 |

## Rundgang in sieben Stationen

### 1. Namespace wählen

- Oben links `workshop` wählen. Vor Lab 2 steht dort "There is nothing to display here". Das ist richtig, der Namespace ist noch leer.
- Dann `All namespaces` wählen. Jetzt seht ihr, was minikube selbst mitbringt: die Control Plane in `kube-system` und das Dashboard in `kubernetes-dashboard`.
- Merksatz: Das Dashboard zeigt nur, was im gewählten Namespace liegt. Genau wie kubectl ohne `-n`.

### 2. Was minikube mitbringt

Bei `All namespaces` seht ihr rund zehn Pods, obwohl ihr noch nichts deployt habt. Das ist Kubernetes selbst. Ihr fasst es nie an, aber ihr solltet die Namen einmal gesehen haben. Tauchen sie später auf, wisst ihr: gehört zum Cluster, nicht zu mir.

| Pod | Namespace | Aufgabe |
| --- | --- | --- |
| `kube-apiserver-minikube` | `kube-system` | Die Eingangstür. Jeder kubectl-Befehl und jeder Klick im Dashboard landet hier |
| `etcd-minikube` | `kube-system` | Die Datenbank des Clusters. Speichert alle Objekte und ihren Sollzustand |
| `kube-scheduler-minikube` | `kube-system` | Entscheidet, auf welchem Node ein neuer Pod läuft |
| `kube-controller-manager-minikube` | `kube-system` | Vergleicht ständig Soll und Ist. Ersetzt zum Beispiel einen gelöschten Pod (Lab 2) |
| `coredns-...` | `kube-system` | Interner DNS. Übersetzt Service-Namen in Adressen, ab Lab 2 etwa den Namen eures Service `hallo`. CoreDNS ist der Pod, den ihr in Lab 1 untersucht |
| `kube-proxy-...` | `kube-system` | Setzt auf jedem Node die Netzwerkregeln, damit ein Service seine Pods erreicht |
| `kindnet-...` | `kube-system` | Das Pod-Netzwerk von minikube. Gibt jedem Pod eine eigene IP |
| `storage-provisioner` | `kube-system` | Nur in minikube: legt lokale Speicher-Volumes an. Nutzen wir nicht |
| `kubernetes-dashboard-...`, `dashboard-metrics-scraper-...` | `kubernetes-dashboard` | Das Dashboard selbst. Entsteht beim ersten `minikube dashboard` |

Die ersten vier bilden die **Control Plane**, das Steuerzentrum des Clusters. Ihre Namen enden auf den Node-Namen `minikube`. Die Namespaces `default`, `kube-public` und `kube-node-lease` gibt es in jedem Cluster. Für uns bleiben sie leer oder intern.

Auf GKE seht ihr die Control Plane nicht als Pods. Google betreibt sie für euch. Das ist einer der Unterschiede, um die es an Tag 2 geht.

### 3. Workloads: die Übersicht

- Oben stehen Kreise mit dem Zustand je Objektart (Running, Pending, Failed).
- Darunter je eine Liste: Daemon Sets, Deployments, Pods, Replica Sets.
- Der farbige Punkt vor jedem Namen zeigt den Zustand auf einen Blick.

### 4. Pods: die wichtigste Liste

Links **Pods** wählen. Die Spalten:

| Spalte | Was sie euch sagt |
| --- | --- |
| Name | Pod-Name. Bei einem Deployment: Deployment-Name, Hash des ReplicaSets, zufällige Endung |
| Labels | Die Etiketten, über die Service und Deployment den Pod finden |
| Node | Auf welchem Rechner der Pod läuft. In minikube immer `minikube` |
| Status | Running, Pending, CrashLoopBackOff und so weiter |
| Restarts | Wie oft der Container neu gestartet wurde. **Die wichtigste Zahl bei der Fehlersuche**: Running mit vielen Restarts ist nicht gesund |
| CPU Usage, Memory Usage | Zeigen "-", solange kein metrics-server läuft. Für unseren Kurs nicht nötig |

### 5. Ein Pod im Detail

Auf einen Pod klicken, zum Beispiel `coredns-...` in `kube-system`. Die Abschnitte von oben nach unten:

- **Metadata:** Name, Namespace, Alter, Labels
- **Resource information:** Node, Status, IP-Adresse des Pods, Restarts, Service Account
- **Conditions:** Ist der Pod geplant (PodScheduled), gestartet, bereit (Ready)?
- **Controlled by:** Wer den Pod verwaltet, hier ein ReplicaSet. Ein Klick darauf führt weiter zum Deployment. So seht ihr die Kette Deployment, ReplicaSet, Pod
- **Events:** Was Kubernetes mit dem Pod gemacht hat. Entspricht dem Abschnitt Events in `kubectl describe pod`
- **Containers:** Image, eingebundene Dateien (Mounts) und Probes. Probes sind Thema an Tag 2

Events richtig lesen: Beim Start von minikube zeigt der CoreDNS-Pod oft zwei Warnungen, `FailedScheduling` (der Node war noch nicht bereit) und `Unhealthy` (Readiness probe failed, der Container lief noch nicht). Danach kommen `Scheduled`, `Pulled`, `Created`, `Started`. Das ist ein normaler Start. Entscheidend sind die Spalten **Count** und **Last Seen**: Eine Warnung, die einmal beim Start kam, ist harmlos. Eine, die ständig hochzählt, ist ein Problem.

### 6. Logs

Rechts oben in der blauen Leiste das erste Symbol (drei Linien) öffnet die Logs. Dasselbe erreicht ihr in jeder Liste über die drei Punkte am Zeilenende: Logs, Exec, Edit, Delete.

- Oben wählt ihr den Container, falls der Pod mehrere hat.
- Das Menü mit den drei Punkten in der Log-Ansicht bietet: Show timestamps, Auto-refresh (alle 5 Sekunden), **Show previous logs**, Invert colors, Reduce font size.
- **Show previous logs** zeigt die Ausgabe des vorherigen Containers nach einem Neustart. Das ist `kubectl logs --previous` und genau das, was ihr bei CrashLoopBackOff braucht.
- Mit dem Download-Symbol speichert ihr die Logs als Datei.

### 7. Deployments und Nodes

**Deployment im Detail** (links Deployments, dann z. B. `coredns`):

- **Pods status:** Soll und Ist, etwa 1 / 1
- **Rolling update strategy:** Wie bei einem Update getauscht wird (Tag 2)
- **New Replica Set** und **Old Replica Sets:** Die aktuelle und die früheren Versionen. Darüber laufen Rollbacks (Tag 2)
- Aktionen oben rechts: Scale, Restart, Edit, Delete. Heute nur anschauen, nicht klicken

**Nodes** (links in der Gruppe Cluster):

- **Ready:** Ist der Rechner einsatzbereit?
- **CPU requests** und **CPU capacity**, ebenso für Memory: Wie viel die Pods angefordert haben und wie viel der Node hat. Der Scheduler plant nach diesen Anforderungen, nicht nach der aktuellen Auslastung. Das wird an Tag 2 wichtig

## Dashboard und kubectl: dieselben Daten

| Im Dashboard | Mit kubectl |
| --- | --- |
| Namespace oben links wählen | `-n workshop` oder Namespace im Kontext |
| Pods-Liste | `kubectl get pods` |
| Pod-Detailseite | `kubectl describe pod NAME` |
| Events auf der Detailseite | Abschnitt Events in `describe`, oder `kubectl get events` |
| Logs | `kubectl logs NAME` |
| Show previous logs | `kubectl logs NAME --previous` |
| Exec | `kubectl exec -it NAME -- sh` |
| Scale am Deployment | `kubectl scale deployment NAME --replicas=N` |
| Restart am Deployment | `kubectl rollout restart deployment NAME` |
| Edit | `kubectl edit` |

## Was ihr hier besser nicht macht

- **Edit, Scale und das Plus-Symbol ändern den Cluster direkt.** Die Änderung steht danach nicht in eurer Datei und nicht im Git. Das nächste `kubectl apply` setzt den Stand aus der Datei wieder durch.
- **Delete** wirkt sofort und fragt nur einmal nach. Einen Pod zu löschen ist in Lab 2 gewollt, ein Deployment oder einen Namespace zu löschen nicht.
- Faustregel für den Kurs: Im Dashboard schauen, mit kubectl und Dateien ändern.

## Mitmachen

Im Namespace `kube-system` den Pod `coredns-...` öffnen.

**Abgabe:** Das Image des Pods, sein Node, der Name des ReplicaSets unter "Controlled by" und der Reason des ersten Events in der Liste.

## Was im Namespace workshop entsteht

Im Namespace `workshop` kommt mit jedem Lab etwas dazu. Wählt ihn oben links, dann seht ihr nur eure eigenen Objekte.

| Wann | Neu im Dashboard |
| --- | --- |
| Lab 0 | Nichts. Der Namespace ist leer |
| Lab 1 | Nichts. Die Rallye liest nur |
| Lab 2, Tag 1 | Deployment `hallo`, ein ReplicaSet, zwei Pods `hallo-...`, Service `hallo`. Das ReplicaSet steht in keiner Datei. Das Deployment legt es an, um seine Pods zu verwalten |
| Lab 2, Tag 2 | Config Map `hallo-config`, Secret `hallo-secret`. Nach dem Update ein zweites ReplicaSet: das neue läuft, das alte bleibt für den Rollback stehen |
| Lab 3 | Fünf Deployments `fall1` bis `fall5` mit absichtlichen Fehlern, dazu Config Map `fall2-config` |
| Lab 6 | Wieder `hallo` mit Config Map und Secret, dann drei fehlerhafte Releases nacheinander |
| Lab 7 | Pod Disruption Budget `hallo-pdb`. Bei Nodes: ein gesperrter Node (cordon) |

Die Labs enden mit einem Abschnitt Aufräumen. Danach ist der Namespace wieder übersichtlich.

## Wo das Dashboard wiederkommt

| Wann | Was ihr euch anseht |
| --- | --- |
| Lab 2 (Tag 1) | Pods-Liste im Namespace `workshop`, während ein Pod gelöscht und das Deployment skaliert wird: Selbstheilung live |
| 2.3 Probes und Ressourcen | Conditions und Probes auf der Pod-Detailseite, Requests und Kapazität bei den Nodes |
| 2.4 Updates und Rollbacks | New und Old Replica Sets auf der Deployment-Seite während eines Rollouts |
| Lab 3 Troubleshooting | Events und Show previous logs bei den defekten Deployments |
| Tag 2 nachmittags | Auf GKE übernimmt die Google-Cloud-Konsole diese Rolle. Vieles findet ihr dort unter ähnlichen Namen wieder |
