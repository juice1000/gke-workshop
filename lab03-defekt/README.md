# Lab 3: Fünf defekte Deployments

**Ziel:** Ihr findet Ursachen anhand von Belegen, bevor ihr etwas ändert. Dauer: 35 Minuten, zu zweit. **Voraussetzung:** Image `hallo-app:1.0` in minikube, Kontext `minikube`, Namespace `workshop`. Die Anwendung aus Lab 2 ist aufgeräumt.

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

Für Fall 2 gehört zur Reparatur das Anlegen der fehlenden ConfigMap. **Aufgabe:** Legt sie per Befehl an, ohne Datei. Den Namen und den erwarteten Schlüssel nennen euch die Events, als Wert genügt ein beliebiger Text. Tipp: `kubectl create --help`.

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

Kommt ihr bei einem Fall nicht weiter, holt euch einen Hinweis oben oder fragt den Trainer. Die Auflösung besprechen wir gemeinsam nach dem Lab. Wendet immer nur eine Datei an, nicht den ganzen Ordner.

## Extra zum Ausprobieren

Für alle, die mit den fünf Fällen fertig sind. Jedes Extra steht für sich und räumt am Ende selbst auf.

### Extra 1: Ein eigenes Diagnose-Skript

Bei jeder Störung tippt ihr dieselben Befehle. Im Betrieb packt man so etwas in ein Skript. [extra/diagnose.sh](extra/diagnose.sh) ist ein Gerüst dafür: Es nimmt ein Label wie `fall1` und führt nacheinander die Schritte aus den Kern-Abschnitten 2 bis 4 aus. Abschnitt 1 ist fertig, Abschnitte 2 bis 5 ergänzt ihr an den `TODO`-Stellen.

- Jeder `kubectl`-Aufruf nutzt das Array `"${K[@]}"`. Es setzt Kontext und Namespace ausdrücklich, so trifft das Skript nie versehentlich einen anderen Cluster
- Filtert immer mit dem Label `app=$APP`, nie mit einem Pod-Namen. Pod-Namen ändern sich bei jedem Neustart
- Abschnitt 4 darf scheitern, wenn es keinen Neustart gab. Das Skript soll dann weiterlaufen. Tipp: `|| true` oder eine eigene Meldung mit `||`

```bash
bash lab03-defekt/extra/diagnose.sh fall1
```

Ohne Pods meldet Abschnitt 1 `No resources found`. Das ist richtig. Wichtig ist, dass das Skript bis Abschnitt 5 durchläuft.

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
