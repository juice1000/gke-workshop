# Lab 6: Abschlussübung

**Ziel:** Ihr schreibt ein vollständiges Deployment und untersucht drei fehlgeschlagene Releases. Dauer: 90 Minuten, zu zweit. Alle Befehle aus dem Repository-Hauptordner.

Voraussetzung: Zielkontext und eigener Namespace aus Lab 4, erreichbares Image der Version 2.0. Die Anwendung aus Lab 4 oder Lab 5 läuft weiter, `apply` ersetzt sie. Alternativ funktioniert diese Übung lokal, siehe unten.

## Etappe A: Selbst deployen (25 Minuten)

1. Prüft `kubectl config get-contexts`. Aktueller Kontext, `WORKSHOP_CONTEXT` und Namespace müssen zusammenpassen.
2. Setzt `IMAGE` wie in Lab 4 auf euer bereits hochgeladenes Image. Erstellt eine Arbeitskopie:

```bash
python3 scripts/render.py lab06-abschluss --image "$IMAGE" --output out/lab06
kubectl create secret generic hallo-secret --from-literal=DB_PASSWORT=uebung123
```

3. Ergänzt `out/lab06/starter/deployment.yaml`. Ersetzt `TODO_IMAGE` durch den Wert von `IMAGE`. Schreibt die beiden Umgebungsvariablen, Ressourcen und drei Probes gemäß den TODO-Kommentaren. ConfigMap und Service sind fertig. Muster findet ihr in [Lab 2](../lab02-hallo-app/betrieb/deployment.yaml).
4. Wendet nur `starter/` an:

```bash
kubectl apply -f out/lab06/starter/
kubectl rollout status deployment/hallo --timeout=600s
python3 scripts/pruefen.py abschluss
kubectl port-forward service/hallo 8080:80
```

Im zweiten Terminal `curl http://127.0.0.1:8080/`. Erwartet: `Hallo zum Abschluss von Pod ..., Version 2.0`.

5. Rollt denselben Stand einmal über die Pipeline aus. Sie verwendet `WORKSHOP_CONTEXT` und `WORKSHOP_NAMESPACE` aus Lab 4:

```bash
bash scripts/pipeline.sh out/lab06/starter/
echo "Exit-Code: $?"
```

Erwartet: fünf Stufen, am Ende `Pipeline GRUEN: ... laeuft in ...` und `Exit-Code: 0`. Die Pipeline führt dieselben Befehle aus wie ihr eben von Hand. Neu ist das Gate: `rollout status` mit Zeitgrenze entscheidet über grün oder rot. Lest den Kopf von [scripts/pipeline.sh](../scripts/pipeline.sh): Jede Stufe entspricht einem Build-Schritt in TeamCity.

**Abgabe A:** Zwei bereite Pods, Antwort, grüner Checkpoint und grüner Pipeline-Lauf. `DB_PASSWORT` wird nur als Umgebungsvariable eingebunden. Verwendet keine echten Zugangsdaten.

## Etappe B: Störungen 6.1 bis 6.3 über die Pipeline (45 Minuten)

Die Dateien enthalten komplette Deployments. Sie verwenden denselben Anwendungscode der Version 2.0, ändern aber die Betriebsbeschreibung. Ihr liefert sie über die Pipeline aus, immer nur ein Release. Nicht den gesamten Ordner `out/lab06` übergeben.

Öffnet vorher ein zweites Terminal und lasst es die ganze Etappe mitlaufen. Dort seht ihr live, was die Pipeline im Cluster auslöst:

```bash
kubectl get pods -w                       # neuer Pod kommt, scheitert, verschwindet beim Rollback
```

Läuft `verkehr` aus Lab 5 noch, öffnet ein drittes Terminal mit `kubectl logs deployment/verkehr -f`. Achtet darauf, ob Nutzer während eines roten Release Fehler sehen.

Ihr arbeitet die drei Störungen 6.1 bis 6.3 nacheinander ab. Für 6.1:

1. Bekannten guten Stand herstellen. Erwartet: grün.

```bash
bash scripts/pipeline.sh out/lab06/starter/
```

2. Störung ausliefern. Erwartet: rot, Exit-Code 1, Release zurückgerollt.

```bash
bash scripts/pipeline.sh out/lab06/stoerungen/6.1-konfiguration.yaml
echo "Exit-Code: $?"
```

3. Ursache finden. Die Pipeline hat vor dem Rollback Belege gesichert, der Pfad steht in der letzten Zeile:

```bash
ls out/pipeline/                       # ein Ordner pro rotem Lauf, nach Zeit benannt
less out/pipeline/ZEIT/describe.txt    # ZEIT durch den neuesten Ordner ersetzen
```

`pods.txt`, `describe.txt`, `events.txt` und `logs.txt` zeigen den Zustand im Moment des Fehlers. Auf GKE sucht ihr zusätzlich im Logs Explorer. Notiert Symptom, Ursache und die Belegdatei, die die Ursache zeigt.

4. Korrigiert eure Arbeitskopie `out/lab06/stoerungen/6.1-konfiguration.yaml` und startet die Pipeline erneut. Erwartet: grün.

Wiederholt die Schritte 1 bis 4 für `6.2-speicher.yaml` und `6.3-bereitschaft.yaml`. Schritt 1 ist dabei wichtig: Er setzt Cluster und `apply` auf einen bekannten Stand zurück.

Die Stufe Rollback macht genau das, was ihr in 2.4 von Hand gemacht habt: `kubectl rollout undo`. Die Warnung dabei bedeutet: Der Cluster läuft jetzt wieder mit dem alten Stand, eure Datei nennt aber noch den neuen.

Warum antworten die alten Pods weiter, während das Release scheitert? Sucht die beiden Einstellungen unter `strategy.rollingUpdate`. Das funktioniert, solange die alten Pods selbst gesund bleiben und genug Kapazität für den zusätzlichen Pod vorhanden ist.

**Abgabe B:** Pro Störung Symptom, Ursache, Belegdatei, Reparatur und die Exit-Codes des roten und des grünen Laufs.

<details>
<summary>Hinweise</summary>

- 6.1: Welche Schlüssel enthält `hallo-config`, welcher wird referenziert?
- 6.2: Vergleicht JVM-Heap und Containerlimit. Heap ist nur ein Teil des Prozessspeichers. Lest `State` und `Last State` des neuen Containers.
- 6.3: Vergleicht HTTP-Pfad und Readiness-Event. `Running` allein genügt nicht.

</details>

<details>
<summary>Lösungen</summary>

| Störung | Erwartetes Symptom | Ursache | Beleg | Reparatur |
| --- | --- | --- | --- | --- |
| 6.1 | `CreateContainerConfigError` | ConfigMap-Schlüssel `GRUSS` existiert nicht | `describe.txt`, Events: `couldn't find key GRUSS in ConfigMap` | `GREETING` referenzieren |
| 6.2 | Container wird mit `OOMKilled` beendet | 512 MiB fest vorbelegter Heap plus JVM-Nebenspeicher passen nicht ins 512-MiB-Limit | `describe.txt`, `Last State: Terminated`, `Reason: OOMKilled`, Exit Code 137 | Limit auf `1Gi` erhöhen oder Heap verkleinern |
| 6.3 | Neuer Pod läuft, bleibt aber `0/1` | Readiness prüft einen nicht vorhandenen Pfad | `describe.txt`, Events: `Readiness probe failed: HTTP probe failed with statuscode: 404` | `/actuator/health/readiness` eintragen |

Exit-Codes: rot `1`, grün `0`. Bei 6.1 und 6.3 ist der grüne Lauf nach der Reparatur sofort fertig: Der Rollback hat genau diesen Stand schon wiederhergestellt, `apply` ändert nichts mehr.

Warum vor jeder Störung der Starter? `rollout undo` ändert den Cluster, aber nicht die Notiz von `kubectl apply` über die zuletzt angewendete Datei. Ein Feld, das nur im zurückgerollten Stand steht, entfernt das nächste `apply` dann nicht. Beispiel: 6.2 mit `JAVA_TOOL_OPTIONS` und `1Gi` repariert, danach direkt 6.3 ausgeliefert und repariert. Dann bleiben die Heap-Optionen stehen, das Limit sinkt auf 512 MiB, und 6.3 wird mit dem Fehlerbild von 6.2 rot. Der Starter dazwischen setzt diese Notiz zurück.

Störung 6.2 nutzt `-Xms512m -Xmx512m -XX:+AlwaysPreTouch`. Das erzeugt die Speicherknappheit gezielt. Die hohe feste Heap-Vorgabe gehört nur zu diesem Fehlerfall. GKE-Admission und Clusterregeln können Manifeste ändern oder ablehnen; der Trainer prüft das Verhalten vorab im echten Cluster.

Die vollständige Ausgangslösung liegt in `out/lab06/loesung/`, korrigierte Fassungen in `out/lab06/repariert/`. Die Vorlagen im Repository: [Deployment](loesung/deployment.yaml), [6.1](repariert/6.1-konfiguration.yaml), [6.2](repariert/6.2-speicher.yaml), [6.3](repariert/6.3-bereitschaft.yaml). Vorlagen mit `WORKSHOP_IMAGE` erst rendern.

</details>

## Extra zum Ausprobieren: Die Pipeline baut selbst

Mit `--build` baut die Pipeline zuerst ein neues Image. Der Tag enthält den Git-Commit, so wie ein Build-Server jede Version eindeutig benennt.

```bash
bash scripts/pipeline.sh out/lab06/starter/ --build
kubectl get deploy hallo -o wide        # Spalte IMAGES
git log -1 --oneline                    # derselbe Commit im Tag
```

Die Pipeline ändert eure Datei nicht. Sie schreibt eine Kopie mit dem neuen Image nach `out/pipeline/build-ZEIT/`. Die Antwort der Anwendung zeigt jetzt `Version 2.0-COMMIT`. Uncommittete Änderungen stecken zwar im Image, aber nicht im Tag. Ein echter Build-Server baut deshalb nur aus Commits.

## Etappe C: Rechte prüfen (10 Minuten)

```bash
kubectl auth can-i create deployments.apps
kubectl auth can-i create deployments.apps -n kube-system
kubectl auth can-i get secrets
kubectl auth can-i list nodes
```

**Abgabe C:** Vier Antworten und eure Erklärung. Erwartet in der vorbereiteten Teilnehmerrolle: im eigenen Namespace Deployments und Secrets erlaubt, keine Deployment-Änderung in `kube-system`. Das Auflisten von Nodes hängt von zusätzlichen Rechten ab.

`can-i` zeigt das wirksame Ergebnis. Es beweist auf GKE allein nicht, ob eine Freigabe von IAM oder RBAC kommt. Zusätzliche IAM-Rechte können Zugriff erlauben, den eine enge RBAC-Rolle nicht gewährt. Vergleicht die Antworten mit der Konfiguration des Trainers.

## Aufräumen (10 Minuten)

```bash
kubectl config current-context
kubectl delete -f out/lab06/starter/
kubectl delete secret hallo-secret
kubectl get deployment,pods,service,configmap,secret
```

In einem frischen Namespace kann ein systemseitig vorhandenes Objekt übrig bleiben. `kubectl get all` würde ConfigMaps und Secrets nicht vollständig abdecken.

## Ohne Cloud

```bash
export WORKSHOP_CONTEXT=minikube
export WORKSHOP_NAMESPACE=workshop
export IMAGE=hallo-app:2.0
kubectl config use-context "$WORKSHOP_CONTEXT"
kubectl config set-context "$WORKSHOP_CONTEXT" --namespace="$WORKSHOP_NAMESPACE"
minikube image load hallo-app:2.0
```

Dann Etappen A und B unverändert mit einer neuen Arbeitskopie ausführen. Die Pipeline läuft genauso gegen minikube. Mit `--build` lädt sie das Image per `minikube image load` statt per `docker push` und baut für die Architektur eures Rechners. In minikube habt ihr normalerweise Admin-Rechte. Daher zeigt Etappe C dort andere Ergebnisse; die Cloud-Abgrenzung wird gemeinsam besprochen.
