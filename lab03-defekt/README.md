# Lab 3: Fünf defekte Deployments

**Ziel:** Ihr baut euch ein Diagnose-Werkzeug und findet damit Ursachen anhand von Belegen. Dauer: 50 Minuten, zu zweit. Voraussetzung: Image `hallo-app:1.0` in minikube, Kontext `minikube`, Namespace `workshop`. Die Anwendung aus Lab 2 vorher aufräumen.

## Teil 1: Ein eigenes Diagnose-Skript (15 Minuten)

Bei jeder Störung tippt ihr dieselben vier, fünf Befehle. Im Betrieb packt man so etwas in ein Skript. [diagnose.sh](diagnose.sh) ist ein Gerüst dafür: Es nimmt ein Label wie `fall1` und führt nacheinander alle Diagnoseschritte aus. Abschnitt 1 ist fertig. Abschnitte 2 bis 5 ergänzt ihr selbst an den `TODO`-Stellen.

Regeln für das Skript:

- Jeder `kubectl`-Aufruf nutzt das vorbereitete Array `"${K[@]}"`. Es setzt Kontext und Namespace ausdrücklich. So trifft das Skript nie versehentlich einen anderen Cluster
- Filtert immer mit dem Label `app=$APP`, nie mit einem festen Pod-Namen. Pod-Namen ändern sich bei jedem Neustart
- Abschnitt 4 darf scheitern, wenn es keinen Neustart gab. Das Skript soll dann weiterlaufen. Tipp: `|| true` oder eine eigene Meldung mit `||`

Die Befehle kennt ihr aus Lab 1, auch aus dem Teil "Selbst herausfinden". Testet das Skript, bevor ihr den ersten Fall anwendet:

```bash
bash lab03-defekt/diagnose.sh fall1
```

Ohne Pods meldet Abschnitt 1 `No resources found`. Das ist richtig. Wichtig ist, dass das Skript bis Abschnitt 5 durchläuft.

## Teil 2: Fünf Fälle (35 Minuten)

Wendet genau eine Datei an und untersucht sie mit eurem Skript. Ersetzt `N` durch 1 bis 5:

```bash
kubectl config current-context
kubectl apply -f lab03-defekt/fallN.yaml
bash lab03-defekt/diagnose.sh fallN
```

Wartet nach dem Anwenden etwa 30 Sekunden, bevor ihr das Skript startet. Manche Fehler zeigen sich erst nach einigen Versuchen. Reicht die Ausgabe nicht, ergänzt das Skript oder arbeitet von Hand mit den Befehlen aus Lab 1 weiter.

Nicht jeder Befehl liefert in jedem Fall Logs. Ein Container, der noch nicht angelegt wurde, kann noch keine Anwendungsausgabe haben. Auch `--previous` liefert nur nach einem tatsächlichen Neustart etwas.

1. Notiert Symptom und einen Beleg aus Logs oder Events.
2. Formuliert die Ursache vor der Änderung.
3. Repariert die Datei und wendet sie erneut an.
4. Prüft mit `kubectl rollout status deployment/fallN --timeout=180s` und `kubectl get pods -l app=fallN`.
5. Löscht den Fall vor dem nächsten mit `kubectl delete -f lab03-defekt/fallN.yaml`.

Jeder Fall hat einen Fehler. Namen und Labels sind absichtlich getrennt, damit sich die Fälle nicht gegenseitig beeinflussen. Wendet immer nur eine Datei an, nicht den ganzen Ordner.

Für Fall 2 gehört zur Reparatur das Anlegen der fehlenden ConfigMap. **Aufgabe:** Legt sie per Befehl an, ohne Datei. Den Namen und den erwarteten Schlüssel nennt euch die Diagnose, als Wert genügt ein beliebiger Text. Tipp: `kubectl create --help`. Räumt sie danach mit `kubectl delete configmap fall2-config` auf.

**Abgabe:** Euer fertiges `diagnose.sh` und pro Fall eine Zeile: Symptom, Ursache, Diagnosebefehl und Änderung. Beispiel: „Fall N: kein Start, fehlendes Objekt in den Events, Namen korrigiert“.

## Bonus: Warum hilft port-forward allein nicht beim Service-Debugging?

Nach Fall 5 könnt ihr einen Service anlegen:

```bash
kubectl expose deployment fall5 --port=80 --target-port=8080
kubectl get endpointslices -l kubernetes.io/service-name=fall5 -o yaml
```

Mit der defekten Readiness haben die Pod-Adressen `ready: false`. Nach der Reparatur wird daraus `true`. EndpointSlices können unbereite Adressen enthalten. Die bloße Existenz einer Adresse bedeutet nicht, dass der Service Traffic dorthin weiterleitet. Ein Port-Forward ist kein Beleg für die Bereitschaft der Service-Ziele.

Danach `kubectl delete service fall5` und das Deployment löschen.

<details>
<summary>Hinweise</summary>

1. Vergleicht den Image-Tag Zeichen für Zeichen mit `minikube image ls`.
2. Vergleicht `configMapKeyRef.name` mit `kubectl get configmaps`.
3. Lest den Startbefehl und die Ausgabe des vorherigen Containers.
4. Schaut auf `Requests`, Node-Kapazität und `FailedScheduling`.
5. Vergleicht Readiness-Pfad und die tatsächlichen HTTP-Endpunkte.

</details>

Kommt ihr bei einem Fall nicht weiter, holt euch einen Hinweis oben oder fragt den Trainer. Die Auflösung besprechen wir gemeinsam nach dem Lab.
