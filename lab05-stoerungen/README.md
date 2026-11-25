# Lab 5: Störungssuche mit Logs

**Ziel:** Ihr findet Störungen, die `kubectl get pods` nicht oder nur halb zeigt. Ihr lest dazu Logs, Events, den Logs Explorer und Monitoring. Zum Schluss legt ihr einen Alarm an, der eine Störung selbst meldet. Dauer: 60 Minuten, mit Alarm 80 Minuten. **Voraussetzung:** Cluster, Namespace `workshop` und `IMAGE` aus [Lab 4](../lab04-gke/README.md).

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

`verkehr` ist ein kleiner Client im selben Namespace. Er ruft jede Sekunde die Anwendung auf und schreibt das Ergebnis als Logzeile:

```text
18:27:35 GET / -> 200 Hallo aus dem Betrieb von Pod hallo-7cff9c99cf-bkrds, Version 2.0
18:31:26 GET / -> curl-Fehler 7
```

Die Uhrzeit im Container ist UTC.

## Kern

### 1. Ausgangslage herstellen

Neues Terminal? Erst die Umgebung aus Lab 4 setzen (`PROJECT_ID`, `REGION`, `ZONE`, `IMAGE`).

```bash
bash lab05-stoerungen/stoerung.sh start
kubectl get pods                          # erwartet: hallo 2x und verkehr, alle 1/1, 0 Neustarts
```

Zweites Terminal, läuft die ganze Zeit mit:

```bash
kubectl logs deployment/verkehr -f
```

Im Browser, läuft ebenfalls mit: `http://EXTERNAL-IP/ui.html`. Die Adresse zeigt `kubectl get service hallo-extern`, beim ersten Start nach ein bis zwei Minuten. Die Seite fragt jede Sekunde an und zeigt, welcher Pod antwortet.

`start` legt alles neu an und setzt jede Störung zurück.

### 2. Wo ihr nachschaut

| Sicht | Befehl | In der Konsole |
| --- | --- | --- |
| Nutzer | `kubectl logs deployment/verkehr --tail=20` | Logs Explorer, Container `verkehr` |
| Server | `kubectl logs -l app=hallo --prefix --tail=50` | Logs Explorer, Container `hallo` |
| Server vor dem Neustart | `kubectl logs POD --previous` | Logs Explorer, Zeitfenster vor dem Neustart |
| Kubernetes | `kubectl get events --field-selector type=Warning --sort-by=.lastTimestamp` | Logs Explorer, Kubernetes-Events |
| Zustand | `kubectl get pods`, `kubectl describe pod POD` | Workloads |
| Netz | `kubectl get service hallo -o wide`, `kubectl get endpointslices -l kubernetes.io/service-name=hallo` | Services & Ingress |
| Neustarts über Zeit | `kubectl get pods` (Spalte RESTARTS) | Monitoring, `kubernetes.io/container/restart_count` |

curl-Fehler im Verkehr: `6` Name nicht auflösbar, `7` Verbindung abgelehnt, `28` Zeitüberschreitung.

**Gut zu wissen:** `Startup probe failed: ... connection refused` in den ersten Sekunden nach einem Start ist normal. Spring Boot fährt noch hoch.

### 3. Störungen suchen

Es gibt fünf Störungen, 5.1 bis 5.5. Pro Runde:

```bash
bash lab05-stoerungen/stoerung.sh zufall      # eine unbekannte Störung
bash lab05-stoerungen/stoerung.sh 1           # oder gezielt 5.1 bis 5.5
```

1. Beobachtet zuerst den Verkehr. Was merkt der Nutzer?
2. Sucht den Fundort mit der Tabelle oben. Welcher Befehl, welche Zeile zeigt es?
3. Benennt die Ursache.
4. Repariert mit `kubectl`. Nicht mit `start`: Das wäre Zurücksetzen, keine Reparatur. Die Dateien in [basis/](basis/) sind der gesunde Stand.
5. Prüft: `kubectl get pods` ohne neue Neustarts, und die letzten Zeilen von `verkehr` zeigen nur `-> 200` mit derselben Begrüßung.
6. `bash lab05-stoerungen/stoerung.sh start` für die nächste Runde.

Notiert pro Runde:

| Runde | Symptom beim Nutzer | Fundort (Befehl und Zeile) | Ursache | Reparatur |
| --- | --- | --- | --- | --- |
| 1 | | | | |

### 4. Dieselbe Spur in der Konsole

Sucht für mindestens eine Störung denselben Befund im Logs Explorer:

```text
resource.type="k8s_container"
resource.labels.namespace_name="workshop"
resource.labels.container_name=("hallo" OR "verkehr")
```

Kubernetes-Events derselben Pods:

```text
log_id("events")
resource.labels.namespace_name="workshop"
```

Schaut auf das Histogramm über den Treffern. Wann beginnt die Störung, wann endet sie? Gebt der Übertragung eine Minute.

**Gut zu wissen:** GKE vergibt den Schweregrad nach dem Ausgabekanal: stderr wird `ERROR`, stdout wird `INFO`. Die Anwendung schreibt ihre `ERROR`-Zeilen auf stderr (`lab02-hallo-app/src/main/resources/logback-spring.xml`). Deshalb findet `severity>=ERROR` die Zeilen `FEHLER`. Eine Anwendung, die alles auf stdout schreibt, landet komplett bei `INFO`. Dann hilft nur die Textsuche, etwa `textPayload:"FEHLER"`.

### 5. Alarm: Die Störung meldet sich selbst (20 Minuten)

Ihr legt eine Alarmrichtlinie an, die bei Neustarts von `hallo` auslöst. Dann baut ihr Störung 5.1 ein und wartet, bis der Alarm kommt.

Zuerst ein Kanal für die Benachrichtigung: Monitoring, Alerting, `Edit notification channels`, bei `Email` auf `Add new`, eure Adresse, Name `Meine E-Mail`.

**Weg A, Konsole** (Bezeichnungen der englischen Konsole):

1. Monitoring, Alerting, `Create policy`.
2. Metrik `Kubernetes Container`, `Container`, `Restart count` (`kubernetes.io/container/restart_count`).
3. Filter: `namespace_name` gleich `workshop`, `container_name` gleich `hallo`.
4. Daten umformen: `Rolling window` 1 Minute, `Rolling window function` `delta`. Über alle Zeitreihen: `sum`.
5. Auslöser: `Threshold`, `Above threshold`, Wert `0`.
6. Benachrichtigung: euren Kanal `Meine E-Mail`. Name: `workshop: hallo startet neu`. Unter `Documentation` schreibt ihr die erste Handlung für den Bereitschaftsdienst.
7. Speichern.

**Weg B, dieselbe Richtlinie als Datei** ([alarm.json](alarm.json)) über die Monitoring-API:

```bash
TOKEN=$(gcloud auth print-access-token)
KANAL=$(curl -s -G -H "Authorization: Bearer $TOKEN" \
  "https://monitoring.googleapis.com/v3/projects/$PROJECT_ID/notificationChannels" \
  --data-urlencode 'filter=display_name="Meine E-Mail"' | sed -n 's/^ *"name": "\(.*\)",*$/\1/p' | head -1)
echo "$KANAL"      # erwartet: projects/.../notificationChannels/NUMMER
sed "s#KANAL#$KANAL#" lab05-stoerungen/alarm.json | curl -s -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -d @- \
  "https://monitoring.googleapis.com/v3/projects/$PROJECT_ID/alertPolicies" | grep -m1 '"name"'
```

Vergleicht die Datei mit den Feldern aus Weg A: Jede Einstellung der Konsole steht dort als Feld.

Auslösen:

```bash
bash lab05-stoerungen/stoerung.sh start
bash lab05-stoerungen/stoerung.sh 1
```

Nach etwa vier Minuten steht unter Monitoring, Alerting ein offener Vorfall, und eine E-Mail kommt an (auch im Spam-Ordner nachsehen). Welche Zeitreihe hat ausgelöst, mit welchem Wert? Repariert und beobachtet, wann der Vorfall schließt.

- Warum kommt der Alarm erst nach Minuten, die Neustarts aber nach Sekunden?
- Welche der fünf Störungen meldet dieser Alarm, welche nicht? Was für einen Alarm bräuchte Störung 5.2?

Aufräumen: Richtlinie und Kanal in der Konsole löschen.

## Checkpoint

Nach der letzten Reparatur:

```bash
kubectl get pods                               # alle 1/1, keine neuen Neustarts
kubectl logs deployment/verkehr --tail=6       # nur "-> 200", überall dieselbe Begrüßung
```

## Extra zum Ausprobieren

### Extra 1: Eine Abfrage pro Störung

Schreibt für jede gefundene Störung eine Logs-Explorer-Abfrage, die sie früh zeigt. Welche taugt als Alarm, welche würde zu oft auslösen?

### Extra 2: Selbst eine Störung bauen

Baut eine eigene Störung mit `kubectl patch`, `kubectl set env` oder `kubectl delete`. Notiert vorher, was ihr ändert. Sucht sie danach mit der Tabelle aus Abschnitt 2, als wüsstet ihr nichts: Welche Spur hätte euch zuerst hingeführt? Danach `start`.

### Extra 3: Wer hat das geändert?

Jede Änderung über die Kubernetes-API landet im Audit-Log, mit Zeit, Methode und Konto. Baut eine Störung ein und sucht sie im Logs Explorer:

```text
log_id("cloudaudit.googleapis.com/activity")
resource.type="k8s_cluster"
protoPayload.resourceName:"namespaces/workshop/"
NOT protoPayload.methodName:"status"
```

Ihr seht etwa `io.k8s.apps.v1.deployments.patch` mit eurem Konto. Im Betrieb ist das oft die schnellste Frage: Was hat sich kurz vor der Störung geändert?

### Extra 4: Einen Node leeren

Es ist euer Cluster, ihr dürft auch Nodes warten:

```bash
kubectl get pods -o wide                   # welcher Pod läuft auf welchem Node
kubectl drain NODE_NAME --ignore-daemonsets --delete-emptydir-data
kubectl get pods -o wide                   # neue Pod-Namen auf dem anderen Node
kubectl uncordon NODE_NAME
```

Was zeigt der Verkehr während des Drain? Was bräuchte es, damit Nutzer nichts merken? Hinweis: `PodDisruptionBudget` in [Lab 7](../lab07-betrieb/README.md).

## Aufräumen

Nicht vor Lab 6: Lab 6 übernimmt Service und Secret. Lab 6 räumt am Ende alles ab.

<details>
<summary>Lösungen</summary>

| Störung | Nutzer (`verkehr`) | Server (`hallo`) | Kubernetes | Ursache | Reparatur |
| --- | --- | --- | --- | --- | --- |
| 5.1 Neustarts im Betrieb | weiter `200`, zeitweise antwortet nur ein Pod | `Started HalloApplication` wiederholt; `--previous` zeigt den Shutdown | `Liveness probe failed: HTTP probe failed with statuscode: 404`, RESTARTS steigt | Liveness prüft `/actuator/health/live` | Pfad per `kubectl edit` auf `/actuator/health/liveness` oder `kubectl rollout undo deployment/hallo` |
| 5.2 Stiller Service | nur `curl-Fehler 7` | keine neuen Zeilen | keine Warnung; EndpointSlice zeigt Port `8081` | `targetPort: 8081` im Service | `kubectl apply -f lab05-stoerungen/basis/service.yaml` |
| 5.3 Fehlendes Secret | weiter `200`, aber nur von einem Pod | ein Pod ohne Logs | `Error: secret "hallo-secret" not found`, `CreateContainerConfigError` | Secret gelöscht, ein Pod neu gestartet | Secret neu anlegen, der Pod startet von selbst |
| 5.4 Fehlerflut | zwei von drei Anfragen `GET /fehler -> 500` | `ERROR ... FEHLER` in Serie | nichts | Client `verkehr` ruft `/fehler` auf (`PFADE`) | `kubectl set env deployment/verkehr PFADE-` |
| 5.5 Gemischte Antworten | zwei verschiedene Begrüßungen im Wechsel | nichts Auffälliges | nichts | ConfigMap geändert, nur ein Pod neu gestartet | richtigen Wert festlegen, `kubectl apply -f lab05-stoerungen/basis/configmap.yaml`, `kubectl rollout restart deployment/hallo` |

Alarm: `restart_count` wird alle 60 Sekunden gemessen und erscheint bis zu 3 Minuten später, dazu kommt das Zeitfenster. Der Alarm meldet nur Störung 5.1 sicher. Störung 5.3 startet einen Pod nicht, statt ihn neu zu starten. 5.2, 5.4 und 5.5 haben keine Neustarts. Für 5.2 bräuchte es einen Alarm auf Nutzersicht, etwa eine logbasierte Metrik auf `curl-Fehler` in `verkehr` oder einen Uptime-Check auf `hallo-extern`. Ein Alarm prüft nur, was ihr ihm gesagt habt.

Störung 5.4 zeigt: Der Server loggt den Fehler, aber nicht, wer ihn auslöst. Die Spur zum Verursacher liegt beim Client. Störung 5.5 hat keine Fehlermeldung, nur einen Widerspruch in den Antworten.

</details>

**Wenn es hakt:**

- `start` hängt bei `rollout status`: `IMAGE` prüfen, wie in Lab 4.
- Der Verkehr zeigt nach einer Reparatur weiter Fehler: Bei Störung 5.4 startet `verkehr` neu, die ersten Zeilen kommen nach einigen Sekunden.
