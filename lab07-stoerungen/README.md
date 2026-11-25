# Lab 7: Störungssuche mit Logs

**Ziel:** Ihr findet Störungen, die `kubectl get pods` nicht oder nur halb zeigt. Ihr lest dazu Logs, Events und auf GKE Logs Explorer und Monitoring. Auf GKE legt ihr einen Alarm an, der eine Störung selbst meldet. Dauer: 60 Minuten, mit Alarm 80 Minuten, zu zweit. **Voraussetzung:** Kontext, Namespace und `IMAGE` aus [Lab 4](../lab04-gke/README.md). Eine laufende Anwendung aus Lab 4 oder Lab 5 ersetzt dieses Lab.

Alle Befehle aus dem Repository-Hauptordner. Lest `stoerung.sh` erst nach dem Lab, es verrät die Ursachen.

## Das Minimum

- Pods können grün aussehen, während Nutzer Fehler bekommen. Umgekehrt kann ein Pod rot sein, ohne dass Nutzer etwas merken.
- Es gibt drei Sichten: Was erlebt der Nutzer? Was tut der Server? Was tut Kubernetes?
- Fehlende Logzeilen sind auch ein Befund.
- Erst Symptom, dann Fundort, dann Ursache. Erst danach reparieren.

## Das Bild dazu

```text
 verkehr  --GET http://hallo-->  Service hallo  -->  Pods hallo (2x)
    |                                 |                   |
 Logs: was der Nutzer erlebt     Endpunkte          Logs: was der Server tut
                                                          |
                      Events: was Kubernetes tut (Neustarts, Probes, Fehler beim Start)
```

`verkehr` ist ein kleiner Client im eigenen Namespace. Er ruft jede Sekunde die Anwendung auf und schreibt das Ergebnis als Logzeile:

```text
18:27:35 GET / -> 200 Hallo aus dem Betrieb von Pod hallo-7cff9c99cf-bkrds, Version 2.0
18:31:26 GET / -> curl-Fehler 7
```

Die Uhrzeit im Container ist UTC.

## Kern

### 1. Ausgangslage herstellen

```bash
bash lab07-stoerungen/stoerung.sh start
bash lab07-stoerungen/stoerung.sh pruefen
```

Erwartet: `Ergebnis: 0 Pruefung(en) fehlgeschlagen`. Öffnet ein zweites Terminal und lasst den Verkehr mitlaufen:

```bash
kubectl logs deployment/verkehr -f
```

`start` löscht ein vorhandenes Deployment `hallo` aus Lab 4 oder Lab 5 und legt alles neu an. Es setzt auch jede Störung zurück.

### 2. Wo ihr nachschaut

| Sicht | Befehl | Auf GKE zusätzlich |
| --- | --- | --- |
| Nutzer | `kubectl logs deployment/verkehr --tail=20` | Logs Explorer, Container `verkehr` |
| Server | `kubectl logs -l app=hallo --prefix --tail=50` | Logs Explorer, Container `hallo` |
| Server vor dem Neustart | `kubectl logs POD --previous` | Logs Explorer, Zeitfenster vor dem Neustart |
| Kubernetes | `kubectl get events --field-selector type=Warning --sort-by=.lastTimestamp` | Logs Explorer, Kubernetes-Events |
| Zustand | `kubectl get pods`, `kubectl describe pod POD` | Workloads |
| Netz | `kubectl get service hallo -o wide`, `kubectl get endpointslices -l kubernetes.io/service-name=hallo` | Gateways, Services & Ingress |
| Neustarts über Zeit | `kubectl get pods` (Spalte RESTARTS) | Monitoring, `kubernetes.io/container/restart_count` |

curl-Fehler im Verkehr: `6` Name nicht auflösbar, `7` Verbindung abgelehnt, `28` Zeitüberschreitung.

**Gut zu wissen:** `Startup probe failed: ... connection refused` in den ersten Sekunden nach einem Start ist normal. Spring Boot fährt noch hoch. Das ist Rauschen, kein Befund.

Hängt an eurem Service eine Route aus Lab 4 Extra 4, meldet GKE nach `start` Warnungen wie `EnterDegradedMode` oder `SyncNetworkEndpointGroupFailed` für den Service. `start` legt den Service neu an. Auch das ist Rauschen.

### 3. Störungen suchen

Pro Runde:

```bash
bash lab07-stoerungen/stoerung.sh zufall      # baut eine unbekannte Störung ein
```

1. Beobachtet zuerst den Verkehr. Was merkt der Nutzer?
2. Sucht den Fundort mit der Tabelle oben. Welcher Befehl, welche Zeile zeigt es?
3. Benennt die Ursache.
4. Repariert mit `kubectl`. Nicht mit `start`: Das wäre Zurücksetzen, keine Reparatur. Die Dateien in `out/lab07/` sind der gesunde Stand.
5. Prüft:

```bash
bash lab07-stoerungen/stoerung.sh pruefen
bash lab07-stoerungen/stoerung.sh aufloesen   # welche Störung war es?
bash lab07-stoerungen/stoerung.sh start       # gesund für die nächste Runde
```

Notiert pro Runde:

| Runde | Symptom beim Nutzer | Fundort (Befehl und Zeile) | Ursache | Reparatur |
| --- | --- | --- | --- | --- |
| 1 | | | | |

Es gibt fünf Störungen. Kommt ihr dreimal auf dieselbe, baut gezielt eine andere ein: `bash lab07-stoerungen/stoerung.sh 1` bis `5`.

### 4. Auf GKE: dieselbe Spur in der Konsole

Sucht für mindestens eine Störung denselben Befund im Logs Explorer. Setzt euren Namespace ein:

```text
resource.type="k8s_container"
resource.labels.project_id="lookbeyond-gke-workshop"
resource.labels.cluster_name="workshop"
resource.labels.namespace_name="workshop-person01"
resource.labels.container_name=("hallo" OR "verkehr")
```

Kubernetes-Events derselben Pods:

```text
log_id("events")
resource.labels.namespace_name="workshop-person01"
```

Schaut auf das Histogramm über den Treffern. Wann beginnt die Störung, wann endet sie? Gebt der Übertragung eine Minute.

**Gut zu wissen:** Die Zeilen `ERROR ... FEHLER` der Anwendung kommen im Logs Explorer mit Schweregrad `INFO` an. Spring Boot schreibt alles auf die Standardausgabe, und GKE stuft das als `INFO` ein. Ein Filter auf `severity>=ERROR` findet sie nicht, sucht nach dem Text: `textPayload:"FEHLER"`.

### 5. Alarm: Die Störung meldet sich selbst (GKE, 20 Minuten)

Bisher habt ihr Störungen gesucht. Im Betrieb meldet sich eine Störung über einen Alarm. Ihr legt eine Alarmrichtlinie an, die bei Neustarts von `hallo` in eurem Namespace auslöst. Dann baut ihr Störung 1 ein und wartet, bis der Alarm kommt.

Regeln: Alarmrichtlinien gelten im ganzen Projekt, alle sehen alle. Beginnt den Namen mit eurem Namespace und ändert nur eure eigene. Ihr wählt keinen Benachrichtigungskanal, der Alarm erscheint als Vorfall (Incident) in der Konsole.

**Weg A, Konsole** (Bezeichnungen der englischen Konsole):

1. Monitoring, Alerting, `Create policy`.
2. Metrik `Kubernetes Container`, `Container`, `Restart count` (`kubernetes.io/container/restart_count`).
3. Filter: `namespace_name` gleich eurem Namespace, `container_name` gleich `hallo`.
4. Daten umformen: `Rolling window` 1 Minute, `Rolling window function` `delta`. Über alle Zeitreihen: `sum`.
5. Auslöser: `Threshold`, `Above threshold`, Wert `0`.
6. Benachrichtigung: keinen Kanal wählen. Name: `workshop-person01: hallo startet neu` mit eurer Nummer. Unter `Documentation` schreibt ihr die erste Handlung für den Bereitschaftsdienst, etwa aus eurem Alarmvorschlag in [Lab 6](../lab06-betrieb/README.md).
7. Speichern.

**Weg B, dieselbe Richtlinie als Datei** ([alarm.json](alarm.json)) über die Monitoring-API:

```bash
sed "s/workshop-person01/$WORKSHOP_NAMESPACE/g" lab07-stoerungen/alarm.json > out/alarm.json
curl -s -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" -d @out/alarm.json \
  "https://monitoring.googleapis.com/v3/projects/lookbeyond-gke-workshop/alertPolicies" | grep -m1 '"name"'
```

Notiert den ausgegebenen `name` (`projects/.../alertPolicies/NUMMER`), ihr braucht ihn zum Löschen. Vergleicht die Datei mit den Feldern aus Weg A: Jede Einstellung der Konsole steht dort als Feld.

Auslösen:

```bash
bash lab07-stoerungen/stoerung.sh start
bash lab07-stoerungen/stoerung.sh 1
```

Nach etwa vier Minuten steht unter Monitoring, Alerting ein offener Vorfall. Öffnet ihn: Welche Zeitreihe hat ausgelöst, mit welchem Wert? Folgt dann eurer eigenen `Documentation`. Führt sie euch zur Ursache? Repariert und beobachtet, wann der Vorfall schließt.

Fragen dazu:

- Warum kommt der Alarm erst nach Minuten, die Neustarts aber nach Sekunden?
- Welche der fünf Störungen meldet dieser Alarm, welche nicht? Was für einen Alarm bräuchte Störung 2?

Aufräumen: Richtlinie in der Konsole löschen, oder mit dem notierten Namen:

```bash
curl -s -X DELETE -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://monitoring.googleapis.com/v3/NAME_AUS_WEG_B"
```

## Checkpoint

```bash
bash lab07-stoerungen/stoerung.sh pruefen
```

Erwartet nach der letzten Reparatur: `Ergebnis: 0 Pruefung(en) fehlgeschlagen`.

**Abgabe:** Die Tabelle für mindestens drei verschiedene Störungen, davon eine mit Fundort im Logs Explorer. Auf GKE dazu: Öffnungs- und Schließzeit eures Vorfalls und die Antworten auf die beiden Fragen aus Abschnitt 5.

## Extra zum Ausprobieren

### Extra 1: Eine Abfrage pro Störung

Schreibt für jede gefundene Störung eine Logs-Explorer-Abfrage, die sie früh zeigt. Welche taugt als Alarm, welche würde zu oft auslösen? Vergleicht mit dem Alarmvorschlag aus [Lab 6](../lab06-betrieb/README.md).

### Extra 2: Selbst eine Störung bauen

Baut im eigenen Namespace eine eigene Störung mit `kubectl patch`, `kubectl set env` oder `kubectl delete`. Euer Partner sucht sie an eurem Bildschirm. Regeln: nur im eigenen Namespace, keine Änderung an Nodes, danach `start`.

### Extra 3: Wer hat das geändert? (GKE)

Jede Änderung über die Kubernetes-API landet im Audit-Log, mit Zeit, Methode und Konto. Baut eine Störung ein und sucht sie im Logs Explorer:

```text
log_id("cloudaudit.googleapis.com/activity")
resource.type="k8s_cluster"
protoPayload.resourceName:"namespaces/workshop-person01/"
NOT protoPayload.methodName:"status"
```

`NOT ... status` blendet die Statusmeldungen der Controller aus.

Ihr seht etwa `io.k8s.apps.v1.deployments.patch` mit eurem eigenen Konto. Im Betrieb ist das oft die schnellste Frage: Was hat sich kurz vor der Störung geändert? Warum findet ihr Störung 4 hier, aber keinen Hinweis darauf, was der Client falsch macht?

## Aufräumen

```bash
kubectl config current-context
kubectl delete -f out/lab07/
kubectl delete secret hallo-secret
```

## Ohne Cloud

Alles außer Abschnitt 4 läuft auch lokal:

```bash
export WORKSHOP_CONTEXT=minikube
export WORKSHOP_NAMESPACE=workshop
export IMAGE=hallo-app:2.0
bash lab07-stoerungen/stoerung.sh start
```

Logs Explorer und Monitoring zeigt der Trainer.

## Für den Trainer

**So erklärt ihr es:**

- Lab 3 und Lab 5 hatten Fehler, die `get pods` zeigt. Hier zeigt `get pods` oft nichts. Die Logs des Clients sind die Sicht des Nutzers.
- Drei Sichten: Client, Server, Kubernetes. Jede Störung hinterlässt in mindestens einer eine Spur, keine in allen.
- Fehlende Logs sind ein Befund: Kommt beim Server nichts an, liegt das Problem davor.

**Lösungen:**

| Störung | Nutzer (`verkehr`) | Server (`hallo`) | Kubernetes | Ursache | Reparatur |
| --- | --- | --- | --- | --- | --- |
| 1 Neustarts im Betrieb | weiter `200`, zeitweise antwortet nur ein Pod | `Started HalloApplication` wiederholt; `--previous` zeigt den Shutdown | `Liveness probe failed: HTTP probe failed with statuscode: 404`, RESTARTS steigt | Liveness prüft `/actuator/health/live` | `kubectl apply -f out/lab07/deployment.yaml` oder Pfad per `patch` auf `/actuator/health/liveness` |
| 2 Stiller Service | nur `curl-Fehler 7` | keine neuen Zeilen | keine Warnung; EndpointSlice zeigt Port `8081` | `targetPort: 8081` im Service | `kubectl apply -f out/lab07/service.yaml` |
| 3 Fehlendes Secret | weiter `200`, aber nur von einem Pod | ein Pod ohne Logs | `Error: secret "hallo-secret" not found`, `CreateContainerConfigError` | Secret gelöscht, ein Pod neu gestartet | Secret neu anlegen, der Pod startet von selbst |
| 4 Fehlerflut | zwei von drei Anfragen `GET /fehler -> 500` | `ERROR ... FEHLER` in Serie | nichts | Client `verkehr` ruft `/fehler` auf (`PFADE`) | `kubectl set env deployment/verkehr PFADE=/` |
| 5 Gemischte Antworten | zwei verschiedene Begrüßungen im Wechsel | nichts Auffälliges | nichts | ConfigMap geändert, nur ein Pod neu gestartet | richtigen Wert festlegen, `kubectl apply -f out/lab07/configmap.yaml`, `kubectl rollout restart deployment/hallo` |

Alarm (Abschnitt 5): Getestet am 25.11.2026 in `workshop-trainer`. Störung 1 um 05:23:02 UTC, Vorfall offen um 05:27:04, ohne Benachrichtigungskanal. Verzögerung: `restart_count` wird alle 60 Sekunden gemessen und erscheint bis zu 3 Minuten später, dazu das Ausrichtungsfenster. Der Alarm meldet nur Störung 1 sicher. Störung 3 startet einen Pod nicht, statt ihn neu zu starten. Störungen 2, 4 und 5 haben keine Neustarts. Für 2 bräuchte es einen Alarm auf Nutzersicht, etwa eine logbasierte Metrik auf `curl-Fehler` in `verkehr` oder einen Uptime-Check über das Gateway. Das ist dieselbe Lehre wie beim Pipeline-Gate: Ein Alarm prüft, was ihr ihm gesagt habt.

Teilnehmende haben dafür `roles/monitoring.alertPolicyEditor` am Projekt (`trainer/teilnehmer-anlegen.sh`). Die Rolle gilt projektweit, eine Person kann fremde Richtlinien ändern. Deshalb die Namensregel. Nach dem Kurs alle Richtlinien löschen, siehe [Aufräumen](../docs/11-nach-dem-kurs-aufraeumen.md).

Störung 4 zeigt: Der Server loggt den Fehler, aber nicht, wer ihn auslöst. Die Spur zum Verursacher liegt beim Client. Störung 5 hat keine Fehlermeldung, nur einen Widerspruch in den Antworten.

**Optional: eine Störung für alle (nicht vorab geprüft).** Während die Gruppe sucht, leert ihr einen der drei Nodes:

```bash
kubectl --context "$GKE_CONTEXT" get pods -A -o wide | grep NODE_NAME | head   # wer betroffen ist
kubectl --context "$GKE_CONTEXT" drain NODE_NAME --ignore-daemonsets --delete-emptydir-data
# Gruppe beobachtet: Shutdown-Zeilen, neue Pod-Namen im Verkehr, Events Killing und Scheduled
kubectl --context "$GKE_CONTEXT" uncordon NODE_NAME
```

Rechnerisch fordern 16 Personen mit je zwei `hallo`-Pods (250m CPU) und `verkehr` etwa 8,2 CPU an. Zwei Nodes haben zusammen 7,8 CPU. Nach dem Drain bleiben also einige Pods `Pending` mit `FailedScheduling`. Das ist der Lerneffekt, aber kündigt an, dass ihr den Node wieder freigebt. Nicht vergessen: `uncordon`.

**Wenn es hakt:**

- `start` hängt bei `rollout status`: Image-Pfad in `IMAGE` prüfen, wie in Lab 4.
- `pruefen` meldet Neustarts direkt nach einer Reparatur: Alte Pods mit Neustarts laufen noch. Rollout abwarten und erneut prüfen.
- Der Verkehr zeigt nach einer Reparatur weiter Fehler: Bei Störung 4 startet `verkehr` neu, die ersten Zeilen kommen nach einigen Sekunden.
