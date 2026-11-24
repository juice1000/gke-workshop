# Demonstrationen

Kurze Skripte für den Trainer, die das zeigen, was auf den Folien im Streifen **„Lokal ausprobieren“** steht. Eine Demonstration gehört zu genau einer Folie. Auf der Folie steht unter dem Streifen-Etikett ihre Kennung, zum Beispiel `Demo 2.1d`.

Demonstrationen sind keine Labs:

| | Lab | Demonstration |
| --- | --- | --- |
| Wer tippt? | Alle Teilnehmenden | Der Trainer am Beamer, wer will, macht mit |
| Dauer | 20 bis 90 Minuten | 1 bis 4 Minuten |
| Ziel | Selbst üben, Checkpoint | Einen Satz von der Folie im echten Cluster zeigen |
| Wo | `labNN-.../` | `demos/tagN/KENNUNG-name/`, je Demo ein Ordner mit `demo.sh` und `README.md` |

Jeder Demo-Ordner hat ein eigenes README: den Satz dazu, jeden Schritt mit dem, was ihr auf dem Bildschirm zeigt, häufige Fragen und was zu tun ist, wenn es hakt.

## So läuft eine Demonstration

```text
Folie mit Streifen "Lokal ausprobieren"   Demo 2.3b
            |
            v
bash demos/tag2/2.3b-readiness-faellt-aus/demo.sh
            |
            v
  > kurzer Satz, was gleich passiert       <- ihr erklärt
  $ kubectl ...                            <- Befehl wie auf der Folie
    [Enter] ausführen, [s] überspringen    <- ihr bestimmt das Tempo
            |
            v
  Fehler einbauen -> Status beobachten -> Beleg zeigen
            |
            v
  Aufräumen: Ausgangszustand wiederherstellen (auch bei Strg+C)
```

Jedes Skript:

- zeigt die Befehle so, wie sie auf der Folie stehen,
- führt sie intern immer mit `--context minikube --namespace workshop` aus und bricht bei einem GKE-Kontext ab,
- baut Fehler nur in den eigenen Namespace ein und räumt am Ende auf, auch bei Strg+C.

## Vorbereitung

Einmal vor 2.1, vor den Demonstrationen an Tag 3 und nach jeder abgebrochenen Demonstration:

```bash
bash demos/tag2/00-vorbereiten/demo.sh
```

Das stellt den Stand nach der Challenge in 2.2 her: `hallo-app:1.0` und `2.0` im Cluster, Secret, und `lab02-hallo-app/betrieb/` angewendet. Die Demonstrationen 2.1a bis 2.1f laufen auch schon mit dem Stand nach Lab 2. Das Skript entfernt auch Reste aus Tag 3 (PDB, Role, RoleBinding) und hebt eine Node-Sperre auf.

## Aufruf

```bash
bash demos/tag2/2.1d-service-ohne-endpunkte/demo.sh            # Schritt für Schritt (Standard)
bash demos/tag2/2.1d-service-ohne-endpunkte/demo.sh --auto     # ohne Pausen, zum Testen
bash demos/tag2/2.1d-service-ohne-endpunkte/demo.sh --trocken  # nur Befehle zeigen, nichts ausführen
```

Anderer Kontext oder Namespace: `DEMO_KONTEXT=... DEMO_NAMESPACE=...`. Eigene kubeconfig: `DEMO_KUBECONFIG=...`. Anderer Port in 2.3c: `DEMO_PORT=18080`.

## Übersicht Tag 2

„Ändert“ heißt: Die Demonstration baut etwas um oder einen Fehler ein und stellt danach den Ausgangszustand wieder her.

| Demo | Folie | Was ihr seht | Ändert |
| --- | --- | --- | --- |
| [00](tag2/00-vorbereiten/README.md) | vor 2.1 | Ausgangslage herstellen | ja |
| [2.1a](tag2/2.1a-kubectl-alltag/README.md) | 2.1 „1.5 kompakt: kubectl im Alltag“ | get, describe, logs | nein |
| [2.1b](tag2/2.1b-cluster-node-namespace/README.md) | 2.1 „Eure Fragen: Cluster, Node, Namespace“ | Spalten NAMESPACE und NODE | nein |
| [2.1c](tag2/2.1c-objekte-und-labels/README.md) | 2.1 „Eure Fragen: Image, Pod, Deployment, Service“ | ganze Kette, Labels, Selektor | nein |
| [2.1d](tag2/2.1d-service-ohne-endpunkte/README.md) | Check-in 2.1, 1/3 „Service ohne Endpunkte“ | falscher Selektor, leere EndpointSlice | ja |
| [2.1e](tag2/2.1e-connection-refused/README.md) | Check-in 2.1, 2/3 „Connection refused am Morgen“ | Meldung ohne API-Server, minikube status | nein |
| [2.1f](tag2/2.1f-replicasets/README.md) | Check-in 2.1, 3/3 „Zwei ReplicaSets“ | neues ReplicaSet durch rollout restart | ja |
| [2.2a](tag2/2.2a-configmap-neustart/README.md) | Check-in 2.2, 1/2 „ConfigMap geändert, alte Begrüßung“ | alter Wert bis zum Neustart | ja |
| [2.2b](tag2/2.2b-falscher-namespace/README.md) | Check-in 2.2, 2/2 „CreateContainerConfigError“ | ConfigMap im falschen Namespace | ja |
| [2.2c](tag2/2.2c-secret-base64/README.md) | Anhang „ConfigMap oder Secret?“ (Extra) | base64 dekodieren, auth can-i | nein |
| [2.3a](tag2/2.3a-probes-ansehen/README.md) | 2.3 „Zwei Probes, zwei Fragen“ | READY, RESTARTS, Probe-Zeiten | nein |
| [2.3b](tag2/2.3b-readiness-faellt-aus/README.md) | Check-in 2.3 P, 1/3 „Die Anwendung hängt“ | READY 0/1 ohne Neustart, Ready false | ja |
| [2.3c](tag2/2.3c-health-endpunkte/README.md) | Check-in 2.3 P, 2/3 „Liveness hängt an der Datenbank“ | was die Probes abfragen | nein |
| [2.3d](tag2/2.3d-langsamer-start/README.md) | Check-in 2.3 P, 3/3 „Langsamer Start“ | ohne Startup-Probe: Neustarts, CrashLoopBackOff | ja |
| [2.3e](tag2/2.3e-requests-limits/README.md) | 2.3 „Requests und Limits“ | Requests im Pod und auf dem Node | nein |
| [2.3f](tag2/2.3f-pending/README.md) | Check-in 2.3 R, 1/2 „Pending trotz freier CPU“ | hoher CPU-Request, FailedScheduling | ja |
| [2.3g](tag2/2.3g-oomkilled/README.md) | Check-in 2.3 R, 2/2 „OOMKilled“ | Last State OOMKilled, Exit 137 | ja |
| [2.3h](tag2/2.3h-metriken/README.md) | Anhang „Autoscaler bei Lastspitze“ (Extra) | kubectl top, ein HPA | ja |
| [2.4a](tag2/2.4a-rolling-update/README.md) | 2.4 „Rolling Update: Austausch im Betrieb“ | Pods werden einzeln getauscht | ja |
| [2.4b](tag2/2.4b-falscher-tag/README.md) | Check-in 2.4, 1/2 „Rollout mit falschem Tag“ | ImagePullBackOff, alte Pods bedienen weiter | ja |
| [2.4c](tag2/2.4c-update-strategie/README.md) | Anhang „maxSurge und maxUnavailable“ (Extra) | Update mit 4 Kopien | ja |
| [2.4d](tag2/2.4d-undo-und-git/README.md) | Check-in 2.4, 2/2 „Undo und Git“ | Cluster und Repository laufen auseinander | ja |
| [2.6a](tag2/2.6a-control-plane/README.md) | Check-in 2.6, 1/2 „Wer verantwortet was auf GKE?“ | Control Plane als Pods in minikube | nein |
| [2.6b](tag2/2.6b-requests-ansehen/README.md) | Check-in 2.6, 2/2 „Autopilot ohne Requests“ | Requests eines Pods | nein |
| [2.6c](tag2/2.6c-api-versionen/README.md) | Anhang „Nach dem Upgrade“ (Extra) | Version und API-Version | nein |

## Übersicht Tag 3

Tag 3 läuft auf GKE. Die Demonstrationen zeigen dieselben Mechanismen lokal, bevor jemand im Cloud-Namespace etwas ändert. Vorbereitung wie an Tag 2 mit `demos/tag2/00-vorbereiten/demo.sh`. 3.1a und 3.3a brauchen nur den laufenden Cluster.

| Demo | Folie | Was ihr seht | Ändert |
| --- | --- | --- | --- |
| [3.1a](tag3/3.1a-kontexte/README.md) | 3.1 Rückblick, Zugänge prüfen | Kontexte, aktueller Kontext und Namespace | nein |
| [3.2a](tag3/3.2a-logs-weg/README.md) | 3.2 Logging und Monitoring | `kubectl logs` nach dem Löschen: NotFound | ja |
| [3.3a](tag3/3.3a-role-rolebinding/README.md) | 3.3 Zugriffsrechte | Role, RoleBinding, `auth can-i --as` | ja |
| [3.4a](tag3/3.4a-rollout-exitcode/README.md) | 3.4 Anbindung an den Build-Prozess | Exit-Code 1 bei falschem Tag, 0 nach undo | ja |
| [3.4b](tag3/3.4b-imageid-pullpolicy/README.md) | 3.4 Anbindung an den Build-Prozess | Tag gegen imageID, imagePullPolicy | nein |
| [3.4c](tag3/3.4c-pipeline/README.md) | 3.4 Unsere Pipeline | `scripts/pipeline.sh` grün, dann rot mit Belegen und Rollback | ja |
| [3.6a](tag3/3.6a-cordon-pending/README.md) | 3.6 Lab 6: Vertiefung Betrieb | cordon, Ersatz-Pod Pending, uncordon | ja |
| [3.6b](tag3/3.6b-pdb-drain/README.md) | 3.6 Lab 6: Vertiefung Betrieb | PDB `minAvailable: 2` blockiert drain | ja |

3.2a ersetzt einen Pod von hallo. 3.3a legt Role und RoleBinding `demo-leser` für die Testperson `demo-person@example.com` an und löscht beide wieder. 3.6a und 3.6b sperren den einzigen Node und heben die Sperre am Ende auf, auch bei Strg+C.

Die Streifen „Auf GKE ausprobieren“ in 2.9 haben keine Demonstration. Sie laufen nach Lab 4 direkt im GKE-Kontext.

## Was die Demonstrationen nachbauen

```text
Fehlerbild                    Demo   wie
----------------------------  -----  ------------------------------------------
Service ohne Endpunkte        2.1d   Selektor per patch auf app=hallo-app
CreateContainerConfigError    2.2b   Lab 3 Fall 2, ConfigMap im falschen Namespace
READY 0/1                     2.3b   Readiness-Pfad per patch auf /gibtsnicht
Neustarts, CrashLoopBackOff   2.3d   Startup-Probe entfernt, Liveness alle 2 s
Pending                       2.3f   CPU-Request auf 60 Prozent des Nodes
OOMKilled                     2.3g   lab03-defekt/extra/oom.yaml
ImagePullBackOff              2.4b   set image auf einen Tag, den es nicht gibt
rollout status Exit-Code 1    3.4a   set image auf einen Tag, den es nicht gibt
Pipeline rot, Rollback       3.4c   Lab 5 Release C ueber scripts/pipeline.sh
Pending nach cordon           3.6a   Node gesperrt, ein Pod geloescht
drain blockiert               3.6b   PDB minAvailable 2 bei 2 Kopien
```

Lab 3 zeigt dieselben Fehlerbilder noch einmal, dann suchen die Teilnehmenden die Ursache selbst.

## Grenzen

- Eine Anwendung, die hängt, aber weiterläuft, lässt sich nicht sauber nachbauen. 2.3b zeigt stattdessen eine scheiternde Readiness.
- 2.3f rechnet den CPU-Request aus der Node-Kapazität. Docker Desktop meldet minikube oft alle CPUs des Rechners, trotz `--cpus=2`. Die Demonstration funktioniert mit beiden.
- 2.3h schaltet das minikube-Addon `metrics-server` ein und lässt es an. Die ersten Werte kommen nach ein bis zwei Minuten.
- 3.6a und 3.6b setzen einen Ein-Node-Cluster voraus. Bei mehreren Nodes weicht der Ersatz-Pod auf einen anderen Node aus.
- 3.6b leert mit `--pod-selector=app=hallo` nur die Pods von hallo. Ohne Selektor beträfe drain auch die Systempods in `kube-system`.
- Bricht eine Demonstration hart ab (Terminal geschlossen), stellt `demos/tag2/00-vorbereiten/demo.sh` den Ausgangszustand wieder her.
