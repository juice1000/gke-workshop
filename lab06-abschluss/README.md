# Lab 6: Abschlussübung

**Ziel:** Ihr schreibt ein vollständiges Deployment und untersucht die Störungen 6.1 bis 6.3. Pflicht sind 6.1 und 6.2. Dauer: 110 Minuten, jeder für sich. Alle Befehle aus dem Repository-Hauptordner.

Voraussetzung: Zielkontext und eigener Namespace aus Lab 4, erreichbares Image der Version 2.0. Die Anwendung aus Lab 4 oder Lab 5 läuft weiter, `apply` ersetzt sie.

**Festgefahren?** Wer länger als 10 Minuten nicht weiterkommt, setzt den Namespace auf einen bekannten guten Stand und macht mit dem nächsten Schritt weiter. Das Skript sichert eure Arbeitskopie `out/lab06/` vorher unter neuem Namen, rollt die fertige Lösung über die Pipeline aus und prüft sie:

```bash
bash scripts/basis.sh lab06              # gesunder Stand, danach z. B. weiter mit Etappe B
bash scripts/basis.sh lab06 --pruefen    # nur prüfen, nichts ändern
```

Jeder Pipeline-Lauf steht mit Zeit und Ergebnis in `out/pipeline/verlauf.txt`. Den braucht ihr für die Abgabe.

## Etappe A: Selbst deployen (25 Minuten)

1. Prüft `kubectl config get-contexts`. Aktueller Kontext, `WORKSHOP_CONTEXT` und Namespace müssen zusammenpassen.
2. Setzt `IMAGE` wie in Lab 4 auf euer bereits hochgeladenes Image. Erstellt eine Arbeitskopie:

```bash
python3 scripts/render.py lab06-abschluss --image "$IMAGE" --output out/lab06
kubectl create secret generic hallo-secret --from-literal=DB_PASSWORT=uebung123
```

Nach Lab 5 gibt es das Secret schon. Die Meldung `already exists` ist dann in Ordnung.

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

**Abgabe A, in den Chat:** Zwei bereite Pods, Antwort, grüner Checkpoint und grüner Pipeline-Lauf. `DB_PASSWORT` wird nur als Umgebungsvariable eingebunden. Verwendet keine echten Zugangsdaten.

## Etappe B: Störungen 6.1 bis 6.3 über die Pipeline (45 Minuten)

Die Dateien enthalten komplette Deployments. Sie verwenden denselben Anwendungscode der Version 2.0, ändern aber die Betriebsbeschreibung. Ihr liefert sie über die Pipeline aus, immer nur ein Release. Nicht den gesamten Ordner `out/lab06` übergeben.

Öffnet vorher ein zweites Terminal und lasst es die ganze Etappe mitlaufen. Dort seht ihr live, was die Pipeline im Cluster auslöst:

```bash
kubectl get pods -w                       # neuer Pod kommt, scheitert, verschwindet beim Rollback
```

Läuft `verkehr` aus Lab 5 noch, öffnet ein drittes Terminal mit `kubectl logs deployment/verkehr -f`. Achtet darauf, ob Nutzer während eines roten Release Fehler sehen.

Ihr arbeitet die Störungen nacheinander ab. Pflicht sind 6.1 und 6.2, 6.3 wenn Zeit bleibt. Für 6.1:

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

**Abgabe B, in den Chat:** Pro Störung Symptom, Ursache, Belegdatei, Reparatur und die Exit-Codes des roten und des grünen Laufs.

<details>
<summary>Hinweise</summary>

- 6.1: Welche Schlüssel enthält `hallo-config`, welcher wird referenziert?
- 6.2: Vergleicht JVM-Heap und Containerlimit. Heap ist nur ein Teil des Prozessspeichers. Lest `State` und `Last State` des neuen Containers.
- 6.3: Vergleicht HTTP-Pfad und Readiness-Event. `Running` allein genügt nicht.

</details>

Kommt ihr nicht weiter, fragt den Trainer. Die Auflösung besprechen wir gemeinsam nach dem Lab.

## Extra zum Ausprobieren: Die Pipeline baut selbst

Mit `--build` baut die Pipeline zuerst ein neues Image. Der Tag enthält den Git-Commit, so wie ein Build-Server jede Version eindeutig benennt.

```bash
bash scripts/pipeline.sh out/lab06/starter/ --build
kubectl get deploy hallo -o wide        # Spalte IMAGES
git log -1 --oneline                    # derselbe Commit im Tag
```

Die Pipeline ändert eure Datei nicht. Sie schreibt eine Kopie mit dem neuen Image nach `out/pipeline/build-ZEIT/`. Die Antwort der Anwendung zeigt jetzt `Version 2.0-COMMIT`. Uncommittete Änderungen stecken zwar im Image, aber nicht im Tag. Ein echter Build-Server baut deshalb nur aus Commits.

## Etappe D: Das Passwort kommt aus Google Secret Manager (20 Minuten, nur GKE)

Bisher kam `DB_PASSWORT` aus `kubectl create secret`. Jetzt liegt es in Secret Manager, dem Tresor von Google Cloud. Der Pod holt es beim Start als Datei. Er meldet sich dabei mit seinem eigenen Kubernetes-Dienstkonto `hallo` an (Workload Identity, Block 3.3). Kein Schlüssel, kein `kubectl create secret`.

```text
Secret Manager: hallo-db-person01
   ^ Leserecht nur für ns/workshop-person01/sa/hallo (vom Trainer vergeben)
Pod hallo, serviceAccountName: hallo
   CSI-Treiber liest beim Start --> Datei /var/secrets/DB_PASSWORT
   Startzeile im Log: "Konfiguration: ... DB_PASSWORT aus Datei /var/secrets"
```

1. Gesunden Stand für Etappe D herstellen. Das Image `2.5` hat der Trainer gebaut, es schreibt die Startzeile:

```bash
export IMAGE=europe-west3-docker.pkg.dev/lookbeyond-gke-workshop/workshop/hallo-app:2.5
bash scripts/basis.sh lab06 D
```

Erwartet: `Pipeline GRUEN` und `Ausgangslage 06 steht.` Lest dann `out/lab06/basis/D/serviceaccount.yaml`, `secretproviderclass.yaml` und in `deployment.yaml` die Felder `serviceAccountName`, `nodeSelector` und `volumes`.

2. Belegt, woher das Passwort kommt, ohne den Wert zu zeigen:

```bash
kubectl logs deployment/hallo | grep Konfiguration
kubectl exec deployment/hallo -- ls -l /var/secrets
```

Im Logs Explorer findet ihr dieselbe Zeile mit `textPayload:"DB_PASSWORT aus Datei"` und eurem Namespace.

3. Störungen 6.4 bis 6.6, wie in Etappe B. Vor jeder Störung `bash scripts/basis.sh lab06 D` statt des Starters:

```bash
bash scripts/pipeline.sh out/lab06/stoerungen/6.4-tresor-name.yaml
bash scripts/pipeline.sh out/lab06/stoerungen/6.5-identitaet.yaml
bash scripts/pipeline.sh out/lab06/stoerungen/6.6-fremder-tresor.yaml
```

Der neue Pod bleibt in `ContainerCreating`. Die Anwendung startet nie, also gibt es keine Logzeile. Der Befund steht in den Events (`events.txt`, `kubectl describe pod`). Auch das ist ein Befund: keine Logzeile, Ursache in den Events.

**Abgabe D, in den Chat:** Die Startzeile aus `kubectl logs` und aus dem Logs Explorer. Pro Störung Event-Zeile, Ursache und Reparatur.

## Extra zum Ausprobieren: Den Lauf in GitHub Actions lesen

In Demo 3.4d hat ein Merge auf `main` dieselbe Pipeline in GitHub Actions gestartet. Öffnet den Lauf unter `https://github.com/juice1000/gke-workshop/actions/workflows/deploy-demo.yml`. Fragt GitHub nach einer Anmeldung, zeigt der Trainer den Lauf.

- Welcher Schritt im Lauf entspricht welcher Stufe `[1/5]` bis `[5/5]`?
- Wo meldet sich der Runner bei Google Cloud an, und warum liegt dafür kein Schlüssel im Repository? Lest dazu [deploy-demo.yml](../.github/workflows/deploy-demo.yml).
- Welcher Image-Tag lief, und zu welchem Commit gehört er?

## Etappe C: Rechte prüfen (10 Minuten)

```bash
kubectl auth can-i create deployments.apps
kubectl auth can-i create deployments.apps -n kube-system
kubectl auth can-i get secrets
kubectl auth can-i list nodes
```

**Abgabe C, in den Chat:** Vier Antworten und eure Erklärung. Erwartet in der vorbereiteten Teilnehmerrolle: im eigenen Namespace Deployments und Secrets erlaubt, keine Deployment-Änderung in `kube-system`. Das Auflisten von Nodes hängt von zusätzlichen Rechten ab.

`can-i` zeigt das wirksame Ergebnis. Es beweist auf GKE allein nicht, ob eine Freigabe von IAM oder RBAC kommt. Zusätzliche IAM-Rechte können Zugriff erlauben, den eine enge RBAC-Rolle nicht gewährt. Vergleicht die Antworten mit der Konfiguration des Trainers.

## Aufräumen (10 Minuten)

```bash
kubectl config current-context
kubectl delete -f out/lab06/starter/
kubectl delete deployment verkehr --ignore-not-found
kubectl delete httproute hallo --ignore-not-found
kubectl delete serviceaccount hallo --ignore-not-found
kubectl delete secretproviderclass hallo-db hallo-db-v2 --ignore-not-found
kubectl delete secret hallo-secret
kubectl get deployment,pods,service,configmap,secret
```

In einem frischen Namespace kann ein systemseitig vorhandenes Objekt übrig bleiben. `kubectl get all` würde ConfigMaps und Secrets nicht vollständig abdecken.
