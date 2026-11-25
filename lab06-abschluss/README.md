# Lab 6: Abschlussübung

**Ziel:** Ihr schreibt ein vollständiges Deployment, liefert Störungen über eine Pipeline aus und holt das Passwort aus Google Secret Manager. Dauer: etwa 2 Stunden. Alle Befehle aus dem Repository-Hauptordner.

**Voraussetzung:** Cluster, Namespace `workshop`, `PROJECT_ID` und `IMAGE` aus [Lab 4](../lab04-gke/README.md). Die Anwendung aus Lab 4 oder Lab 5 darf weiterlaufen, `apply` ersetzt sie.

**Ihr arbeitet direkt in den Dateien dieses Ordners.** `git diff lab06-abschluss/` zeigt, was ihr geändert habt, `git restore lab06-abschluss/` setzt alles zurück.

**Festgefahren?** Die fertige Lösung ausrollen und mit dem nächsten Schritt weitermachen:

```bash
bash scripts/pipeline.sh lab06-abschluss/loesung/
```

| Ordner | Inhalt |
| --- | --- |
| [starter/](starter/) | Etappe A: Deployment mit TODOs, ConfigMap und Service fertig |
| [loesung/](loesung/) | fertiger Starter, der bekannte gute Stand |
| [stoerungen/](stoerungen/) | Etappen B und D: je ein Release mit genau einem Fehler |
| [repariert/](repariert/) | korrigierte Fassungen von 6.1 bis 6.3 |
| [tresor/](tresor/) | Etappe D: guter Stand mit Passwort aus Secret Manager |
| [rechte.yaml](rechte.yaml) | Etappe C: eine enge Rolle |

## Etappe A: Selbst deployen (25 Minuten)

1. Secret anlegen. Nach Lab 5 gibt es das schon, `already exists` ist dann in Ordnung:

```bash
kubectl create secret generic hallo-secret --from-literal=DB_PASSWORT=uebung123
```

2. Ergänzt [starter/deployment.yaml](starter/deployment.yaml): die beiden Umgebungsvariablen, Ressourcen und drei Probes gemäß den TODO-Kommentaren. `WORKSHOP_IMAGE` bleibt stehen, `sed` setzt euer Image ein. Muster findet ihr in [Lab 2](../lab02-hallo-app/betrieb/deployment.yaml).
3. Ausrollen und prüfen:

```bash
sed "s#WORKSHOP_IMAGE#$IMAGE#" lab06-abschluss/starter/*.yaml | kubectl apply -f -
kubectl rollout status deployment/hallo --timeout=600s
python3 scripts/pruefen.py abschluss
```

Erwartet: `Ergebnis: 0 Pruefung(en) fehlgeschlagen`.

4. Denselben Stand einmal über die Pipeline ausrollen:

```bash
bash scripts/pipeline.sh lab06-abschluss/starter/
echo "Exit-Code: $?"
```

Erwartet: fünf Stufen, am Ende `Pipeline GRUEN` und `Exit-Code: 0`. Die Pipeline führt dieselben Befehle aus wie ihr eben von Hand. Neu ist das Gate: `rollout status` mit Zeitgrenze entscheidet über grün oder rot. Lest [scripts/pipeline.sh](../scripts/pipeline.sh), es sind etwa 70 Zeilen. Jede Stufe entspricht einem Build-Schritt in einem CI-Werkzeug wie TeamCity oder GitHub Actions.

## Etappe B: Störungen 6.1 bis 6.3 über die Pipeline (45 Minuten)

Jede Datei in `stoerungen/` ist ein komplettes Deployment mit genau einem Fehler. Zweites Terminal, läuft die ganze Etappe mit:

```bash
kubectl get pods -w                       # neuer Pod kommt, scheitert, verschwindet beim Rollback
```

Für 6.1:

1. Bekannten guten Stand herstellen. Erwartet: grün.

```bash
bash scripts/pipeline.sh lab06-abschluss/starter/
```

2. Störung ausliefern. Erwartet: rot, Exit-Code 1, Release zurückgerollt.

```bash
bash scripts/pipeline.sh lab06-abschluss/stoerungen/6.1-konfiguration.yaml
echo "Exit-Code: $?"
```

3. Ursache finden. Die Pipeline hat vor dem Rollback Belege gesichert, der Pfad steht in der letzten Zeile:

```bash
ls out/pipeline/                       # ein Ordner pro rotem Lauf, nach Zeit benannt
less out/pipeline/ZEIT/describe.txt    # ZEIT durch den neuesten Ordner ersetzen
```

`pods.txt`, `describe.txt`, `events.txt` und `logs.txt` zeigen den Zustand im Moment des Fehlers. Sucht zusätzlich im Logs Explorer.

4. Korrigiert `lab06-abschluss/stoerungen/6.1-konfiguration.yaml` und startet die Pipeline erneut. Erwartet: grün.

Wiederholt das für `6.2-speicher.yaml` und `6.3-bereitschaft.yaml`. Schritt 1 ist dabei wichtig: Er setzt Cluster und `apply` auf einen bekannten Stand zurück.

Die Stufe Rollback macht, was ihr in Lab 2 von Hand gemacht habt: `kubectl rollout undo`. Warum antworten die alten Pods weiter, während das Release scheitert? Sucht die beiden Einstellungen unter `strategy.rollingUpdate`.

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

Korrigierte Fassungen: [6.1](repariert/6.1-konfiguration.yaml), [6.2](repariert/6.2-speicher.yaml), [6.3](repariert/6.3-bereitschaft.yaml).

Warum vor jeder Störung der Starter? `rollout undo` ändert den Cluster, aber nicht die Notiz von `kubectl apply` über die zuletzt angewendete Datei. Ein Feld, das nur im zurückgerollten Stand steht, entfernt das nächste `apply` dann nicht. Der Starter dazwischen setzt diese Notiz zurück.

</details>

### Extra: Die Pipeline baut selbst

Mit `--build` baut die Pipeline zuerst ein neues Image. Der Tag enthält den Git-Commit, so wie ein Build-Server jede Version eindeutig benennt.

```bash
bash scripts/pipeline.sh lab06-abschluss/starter/ --build
kubectl get deploy hallo -o wide        # Spalte IMAGES
git log -1 --oneline                    # derselbe Commit im Tag
```

Uncommittete Änderungen stecken zwar im Image, aber nicht im Tag. Ein echter Build-Server baut deshalb nur aus Commits.

## Etappe C: Rechte prüfen (10 Minuten)

In eurem Projekt seid ihr Owner. Deshalb antwortet `kubectl auth can-i` für euch fast immer mit `yes`. Wie es für jemanden mit wenigen Rechten aussieht, zeigt ein erfundener Benutzer `tester`:

```bash
kubectl apply -f lab06-abschluss/rechte.yaml
kubectl auth can-i create deployments.apps --as=tester
kubectl auth can-i get secrets --as=tester
kubectl auth can-i create deployments.apps -n kube-system --as=tester
kubectl auth can-i list nodes --as=tester
kubectl auth can-i --list --as=tester
```

Erwartet: `yes` für Deployments und Secrets im Namespace `workshop`, `no` für `kube-system` und für Nodes. Lest dazu [rechte.yaml](rechte.yaml): Die Role sagt was, das RoleBinding sagt wer.

Auf GKE gibt es zwei Schichten: IAM im Google-Projekt (wer darf an den Cluster) und RBAC im Cluster (was darf man dort). `can-i` zeigt das Ergebnis, nicht die Quelle. Eure eigenen Rechte kommen aus IAM: Konsole, IAM & Admin, IAM.

## Etappe D: Das Passwort kommt aus Google Secret Manager (30 Minuten)

Bisher kam `DB_PASSWORT` aus `kubectl create secret`. Jetzt liegt es in Secret Manager, dem Tresor von Google Cloud. Der Pod holt es beim Start als Datei. Er meldet sich dabei mit seinem eigenen Kubernetes-Dienstkonto `hallo` an (Workload Identity). Kein Schlüssel im Cluster.

```text
Secret Manager: hallo-db
   ^ Leserecht nur für ns/workshop/sa/hallo
Pod hallo, serviceAccountName: hallo
   CSI-Treiber liest beim Start --> Datei /var/secrets/DB_PASSWORT
   Startzeile im Log: "Konfiguration: ... DB_PASSWORT aus Datei /var/secrets"
```

1. Tresor anlegen und genau einem Dienstkonto das Leserecht geben. Der Cluster braucht dafür Workload Identity und das Secret-Manager-Add-on, siehe [SELBST-WEITERMACHEN.md](../SELBST-WEITERMACHEN.md).

```bash
gcloud services enable secretmanager.googleapis.com
NR=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
printf 'aus-dem-tresor' | gcloud secrets create hallo-db --data-file=-
printf 'nicht-fuer-hallo' | gcloud secrets create hallo-db-fremd --data-file=-
gcloud secrets add-iam-policy-binding hallo-db --role=roles/secretmanager.secretAccessor \
  --member="principal://iam.googleapis.com/projects/$NR/locations/global/workloadIdentityPools/$PROJECT_ID.svc.id.goog/subject/ns/workshop/sa/hallo"
```

`hallo-db-fremd` bekommt absichtlich kein Leserecht. Das braucht Störung 6.6.

2. Guten Stand ausrollen. Die Pipeline setzt `PROJECT_ID` in die SecretProviderClass ein:

```bash
bash scripts/pipeline.sh lab06-abschluss/tresor/
```

Lest dann [tresor/serviceaccount.yaml](tresor/serviceaccount.yaml), [tresor/secretproviderclass.yaml](tresor/secretproviderclass.yaml) und in [tresor/deployment.yaml](tresor/deployment.yaml) die Felder `serviceAccountName`, `nodeSelector` und `volumes`.

3. Belegt, woher das Passwort kommt, ohne den Wert zu zeigen:

```bash
kubectl logs -l app=hallo --prefix | grep Konfiguration    # alle Pods, nicht nur einer
kubectl exec deployment/hallo -- ls -l /var/secrets
```

Im Logs Explorer findet ihr dieselbe Zeile mit `textPayload:"DB_PASSWORT aus Datei"`.

4. Störungen 6.4 bis 6.6, wie in Etappe B. Vor jeder Störung `bash scripts/pipeline.sh lab06-abschluss/tresor/`:

```bash
bash scripts/pipeline.sh lab06-abschluss/stoerungen/6.4-tresor-name.yaml
bash scripts/pipeline.sh lab06-abschluss/stoerungen/6.5-identitaet.yaml
bash scripts/pipeline.sh lab06-abschluss/stoerungen/6.6-fremder-tresor.yaml
```

Der neue Pod bleibt in `ContainerCreating`. Die Anwendung startet nie, also gibt es keine Logzeile. Der Befund steht in den Events (`events.txt`, `kubectl describe pod`).

<details>
<summary>Lösungen</summary>

| Störung | Event | Ursache | Reparatur |
| --- | --- | --- | --- |
| 6.4 Tresor-Name | `FailedMount`, `PermissionDenied ... (or it may not exist)` für `hallo-db-neu` | SecretProviderClass zeigt auf `hallo-db-neu`, das es nicht gibt | `hallo-db` eintragen |
| 6.5 Identität | `FailedMount`, `PermissionDenied` | Pod läuft als `default`, das Leserecht hat nur `hallo` | `serviceAccountName: hallo` |
| 6.6 Fremder Tresor | `FailedMount`, `PermissionDenied` | `hallo-db-fremd` existiert, aber `hallo` darf es nicht lesen | eigenes Secret `hallo-db` eintragen |

Alle drei melden `PermissionDenied`. Secret Manager verrät ohne Leserecht nicht, ob ein Secret existiert. Den Unterschied zeigt der Name des Secrets in der Meldung und das Dienstkonto des Pods. Alle drei Fehler stehen nicht im Manifest selbst, sondern in der Verbindung zwischen Manifest, Dienstkonto und IAM-Freigabe.

</details>

## Aufräumen

Alles aus Lab 4 bis 6 liegt im Namespace `workshop`. Ein Befehl löscht es, auch den Load Balancer aus Lab 5:

```bash
kubectl config current-context
kubectl delete namespace workshop
gcloud secrets delete hallo-db --quiet
gcloud secrets delete hallo-db-fremd --quiet
```

Cluster, Registry und Projekt löscht ihr, wenn ihr fertig seid: [SELBST-WEITERMACHEN.md](../SELBST-WEITERMACHEN.md), Abschnitt Aufräumen.
