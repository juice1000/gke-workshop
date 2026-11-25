# Lab 3: Fünf defekte Deployments

**Ziel:** Ihr findet Ursachen anhand von Belegen, bevor ihr etwas ändert. Dauer: 35 Minuten, jeder für sich. **Voraussetzung:** Image `hallo-app:1.0` in minikube, Kontext `minikube`, Namespace `workshop`. Die Anwendung aus Lab 2 ist aufgeräumt.

Alle Befehle aus dem Repository-Hauptordner.

## Das Minimum

- Erst lesen, dann ändern: Status, `describe`, Logs, Events. Ändert nichts, bevor ihr einen Beleg habt.
- Der Status in `kubectl get pods` zeigt die Richtung. Das Bild unten sagt, wo ihr weitersucht.
- Stürzt ein Container ab, steht die Ursache im Log des **vorherigen** Containers: `kubectl logs --previous`.
- Nicht jeder Befehl liefert in jedem Fall etwas. Ein Container, der nie gestartet ist, hat keine Logs.
- Der Fix gehört in die Datei. Danach `apply` und mit `rollout status` prüfen.

## Das Bild dazu

```text
kubectl get pods
  Pending                    -> describe: Requests, FailedScheduling
  ErrImagePull/BackOff       -> describe: Name, Tag, Registry-Zugriff
  CreateContainerConfigError -> describe: ConfigMap/Secret fehlt
  CrashLoopBackOff           -> logs --previous
  Running, 0/1               -> describe: Readiness-Events
```

## Kern

Arbeitet die Fälle 1 bis 5 nacheinander ab. Ersetzt in allen Befehlen `N` durch die Nummer des Falls. Jeder Fall hat genau einen Fehler und eigene Namen und Labels (`fallN`), damit sich die Fälle nicht stören.

### 1. Fall anwenden

Was passiert: Ihr rollt genau eine defekte Datei aus.

```bash
kubectl config current-context             # erwartet: minikube
kubectl apply -f lab03-defekt/fallN.yaml   # nur diese eine Datei
```

Erwartet: `deployment.apps/fallN created`. Wartet etwa 30 Sekunden, manche Fehler zeigen sich erst nach einigen Versuchen.

### 2. Status lesen

Was passiert: Ihr seht, in welchem Zustand der Pod hängt. Das Bild oben sagt, wo ihr weitersucht.

```bash
kubectl get pods -l app=fallN              # STATUS, READY und RESTARTS
```

Erwartet: ein Pod mit einem der Zustände aus dem Bild, nicht `Running` mit `1/1`.

### 3. Details und Events

Was passiert: `describe` zeigt Konfiguration, Zustand und am Ende die Events dieses Pods. Events sind die Meldungen des Clusters: Scheduler, kubelet, Image-Download.

```bash
kubectl describe pod -l app=fallN                            # unten: Abschnitt Events
kubectl get events --sort-by=.metadata.creationTimestamp     # alle Events im Namespace, neueste unten
```

Erwartet: eine Zeile vom Typ `Warning`, die den Fehler benennt.

### 4. Logs

Was passiert: Logs zeigen, was die Anwendung selbst ausgibt. Nach einem Absturz liegt die Ursache im Log des vorherigen Containers.

```bash
kubectl logs deployment/fallN                # aktueller Container
kubectl logs deployment/fallN --previous     # Container vor dem letzten Neustart
```

Erwartet: je nach Fall Spring-Boot-Ausgaben, eine Fehlermeldung oder gar nichts.

**Gut zu wissen:** Nicht jeder Befehl liefert in jedem Fall etwas. Ein Container, der nie angelegt wurde, hat keine Logs. `--previous` liefert nur nach einem echten Neustart etwas.

### 5. Ursache benennen, reparieren, prüfen

Was passiert: Ihr schreibt die Ursache auf, bevor ihr etwas ändert. Dann repariert ihr die Datei und prüft den Erfolg.

1. Notiert Symptom und einen Beleg aus Events oder Logs.
2. Formuliert die Ursache in einem Satz.
3. Repariert `lab03-defekt/fallN.yaml` und wendet die Datei erneut an.

```bash
kubectl apply -f lab03-defekt/fallN.yaml
kubectl rollout status deployment/fallN --timeout=180s   # erwartet: successfully rolled out
kubectl get pods -l app=fallN                            # erwartet: Running, 1/1
```

Für Fall 2 gehört zur Reparatur das Anlegen der fehlenden ConfigMap:

```bash
kubectl create configmap fall2-config --from-literal=GREETING=Hallo   # Name und Schluessel aus den Events
```

> **Hintergrund:** Kubernetes versucht es immer weiter, repariert aber keine falsche Konfiguration. Deshalb bleibt ein Fall so lange kaputt, bis die Datei stimmt.

### 6. Aufräumen je Fall

```bash
kubectl delete -f lab03-defekt/fallN.yaml
```

Nach Fall 2 zusätzlich `kubectl delete configmap fall2-config`.

## Checkpoint

Für jeden Fall: `kubectl rollout status deployment/fallN` meldet `successfully rolled out`, und `kubectl get pods -l app=fallN` zeigt `Running` mit `1/1`. Lab 3 hat kein Prüfskript, der Beleg seid ihr selbst.

**Abgabe:** Pro Fall eine Zeile: Symptom, Ursache, Diagnosebefehl und Änderung. Beispiel: „Fall N: kein Start, fehlendes Objekt in den Events, Namen korrigiert“.

<details>
<summary>Hinweise</summary>

1. Vergleicht den Image-Tag Zeichen für Zeichen mit `minikube image ls`.
2. Vergleicht `configMapKeyRef.name` mit `kubectl get configmaps`.
3. Lest den Startbefehl und die Ausgabe des vorherigen Containers.
4. Schaut auf `Requests`, Node-Kapazität und `FailedScheduling`.
5. Vergleicht Readiness-Pfad und die tatsächlichen HTTP-Endpunkte.

</details>

<details>
<summary>Lösungen und erwartete Symptome</summary>

| Fall | Symptom | Ursache und Reparatur |
| --- | --- | --- |
| 1 | `ErrImagePull`, später `ImagePullBackOff` | Buchstabe `O` statt Ziffer `0` im Tag. `hallo-app:1.0` verwenden. |
| 2 | `CreateContainerConfigError` | `fall2-config` fehlt. ConfigMap mit Schlüssel `GREETING` anlegen. |
| 3 | Wiederholter Exit 1, später `CrashLoopBackOff` | Der überschriebene Startbefehl beendet sich absichtlich. `command` entfernen. |
| 4 | `Pending`, `FailedScheduling` | 100 CPU angefordert. Request auf `250m` senken. |
| 5 | `Running`, `READY 0/1`, Probe meldet 404 | Readiness prüft `/bereit-aber-falsch`. Auf `/actuator/health/readiness` ändern. |

Fertige Lösungen: [Fall 1](loesungen/fall1.yaml), [Fall 2](loesungen/fall2.yaml), [Fall 3](loesungen/fall3.yaml), [Fall 4](loesungen/fall4.yaml), [Fall 5](loesungen/fall5.yaml).

Bei Bedarf `kubectl apply -f lab03-defekt/loesungen/fallN.yaml`. Mit derselben Lösungsdatei könnt ihr danach alle Ressourcen dieses Falls entfernen. Netzwerk- und Registryfehler können den genauen Eventtext von Fall 1 verändern. Wendet nie den ganzen Ordner rekursiv an, sonst würden auch Lösungen ausgerollt.

</details>

## Extra zum Ausprobieren

Für alle, die mit den fünf Fällen fertig sind. Jedes Extra steht für sich und räumt am Ende selbst auf.

### Extra 1: Ein eigenes Diagnose-Skript

Bei jeder Störung tippt ihr dieselben Befehle. Im Betrieb packt man so etwas in ein Skript. [extra/diagnose.sh](extra/diagnose.sh) nimmt ein Label wie `fall1` und führt alle Schritte aus den Kern-Abschnitten 2 bis 4 nacheinander aus.

```bash
bash lab03-defekt/extra/diagnose.sh fall1
```

Lest das Skript: Jeder Aufruf nutzt `"${K[@]}"`, ein Array mit ausdrücklichem Kontext und Namespace. So trifft es nie versehentlich einen anderen Cluster. Es filtert immer per Label, nie per Pod-Namen, weil Pod-Namen sich bei jedem Neustart ändern.

### Extra 2: OOMKilled

[extra/oom.yaml](extra/oom.yaml) startet die Anwendung mit einem knappen Speicherlimit.

```bash
kubectl apply -f lab03-defekt/extra/oom.yaml
kubectl get pods -l app=oom -w                         # RESTARTS steigt
kubectl describe pod -l app=oom | grep -A4 "Last State"
```

Was steht bei `Reason` und `Exit Code`? Warum zeigt `logs --previous` keine Fehlermeldung der Anwendung? Repariert die Datei so, dass der Pod stabil läuft.

Aufräumen: `kubectl delete -f lab03-defekt/extra/oom.yaml`.

### Extra 3: Fall 5 mit Service und EndpointSlices

Wendet Fall 5 noch einmal unrepariert an und legt einen Service davor:

```bash
kubectl apply -f lab03-defekt/fall5.yaml
kubectl expose deployment fall5 --port=80 --target-port=8080
kubectl get endpointslices -l kubernetes.io/service-name=fall5 -o yaml | grep -A3 conditions
```

Die Pod-Adresse steht in der EndpointSlice, aber mit `ready: false`. Repariert Fall 5 und schaut erneut. Eine Adresse in der Liste heißt also noch nicht, dass der Service Traffic dorthin schickt.

Aufräumen: `kubectl delete service fall5` und `kubectl delete -f lab03-defekt/fall5.yaml`.

## Für den Trainer

**So erklärt ihr es:**

- Wie beim Arzt: erst Symptome (Status), dann Untersuchung (`describe`, Events), dann Vorgeschichte (Logs, `--previous`), erst dann die Behandlung.
- Das Bild oben ist die ganze Theorie. Jeder Fall trifft genau eine Zeile davon.
- Events sagen, was der Cluster mit dem Pod gemacht hat. Logs sagen, was die Anwendung gemacht hat.

**Häufige Fragen:**

- *Was passiert, wenn der Sollzustand nie erreicht wird?* Kubernetes versucht es weiter, repariert aber nichts. Man sieht es am Status: `Pending`, `0/1`, `CrashLoopBackOff`, bei Updates `ProgressDeadlineExceeded`.
- *Warum liefert `logs` bei Fall 1 und 2 nichts?* Der Container wurde nie gestartet. Die Ursache steht in den Events.
- *Container-Neustart oder neuer Pod?* Bei einem Absturz startet das kubelet den Container im selben Pod neu, `RESTARTS` steigt. Einen neuen Pod mit neuem Namen legt erst der Controller an, wenn ein Pod fehlt.
- *Warum ist Fall 5 `Running`, aber nicht in Ordnung?* `Running` heißt, der Prozess läuft. `0/1` heißt, die Readiness schlägt fehl und der Pod bekommt keinen Traffic.

**Nur nennen, nicht erklären:** EndpointSlices, `kubectl debug`, wie der Scheduler Nodes bewertet. Dafür ist Extra 3 da.

**Wenn es hakt:**

- Fall 4 bleibt nach der Reparatur `Pending`: Der alte Pod hängt noch. `rollout status` abwarten oder den Fall löschen und neu anwenden.
- Jemand wendet `lab03-defekt/` als Ordner an: Alle Fälle laufen gleichzeitig. `kubectl delete -f lab03-defekt/` räumt die fünf Fälle wieder ab.
- Fall 2 bleibt kaputt: ConfigMap im falschen Namespace oder mit falschem Schlüssel. `kubectl get configmap fall2-config -o yaml`.

**Lösung Extra 2:** `Reason: OOMKilled`, `Exit Code: 137`. Die JVM soll sofort 200 MiB Heap belegen (`-Xms200m` in `JAVA_TOOL_OPTIONS`), das Limit erlaubt nur 128 MiB. Der Kernel beendet den Prozess von außen, die Anwendung kann nichts mehr schreiben. Reparatur: `JAVA_TOOL_OPTIONS` entfernen und Limit und Request auf 512 MiB setzen, wie in Lab 2.
