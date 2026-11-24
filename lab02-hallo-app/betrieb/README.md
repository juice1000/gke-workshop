# Lab 2, Tag 2: Konfiguration, Probes und Updates

**Ziel:** Ihr gebt der Anwendung Konfiguration von außen, seht Probes arbeiten und nehmt ein kaputtes Update zurück. Dauer: etwa 60 Minuten. **Voraussetzung:** Lab 2 von Tag 1 läuft (Deployment und Service `hallo`), Kontext `minikube`, Namespace `workshop`.

Alle Befehle aus dem Repository-Hauptordner.

## Das Minimum

- Eine **ConfigMap** liefert Werte als Umgebungsvariable. Der Container liest sie nur beim Start. Nach einer Änderung braucht es `kubectl rollout restart`.
- Ein **Secret** ist nur Base64, keine Verschlüsselung. Echte Werte gehören nie in Git.
- Fällt die **Readiness** aus, bleibt der Pod `Running`, zeigt `0/1` und bekommt keinen Traffic. Fällt die **Liveness** dauerhaft aus, startet Kubernetes den Container neu.
- Ein **Rolling Update** behält die alten Pods, bis neue bereit sind. Zurück rollt Kubernetes nicht von selbst: `rollout status` zeigt das Problem, ihr nehmt es zurück.
- Der dauerhafte Fix gehört in die Datei, nicht nur in den Cluster.

## Das Bild dazu

```text
ConfigMap GREETING --beim Containerstart--> Umgebungsvariable
      ^ geaendert                                  |
      |                         alter Wert bis rollout restart

Liveness  faellt dauerhaft aus  -> Container wird neu gestartet
Readiness faellt aus            -> Pod bleibt Running, READY 0/1,
                                   bekommt keinen Traffic
```

## Kern

Lasst in einem zweiten Terminal die ganze Zeit `kubectl get pods -w` laufen. Dort seht ihr jeden Schritt live.

### 1. Version 2.0 bauen und laden

Was passiert: Ihr baut denselben Code mit neuer Versionsbezeichnung. Ein neuer Tag ist für Kubernetes ein neues Image.

```bash
docker build --build-arg APP_VERSION=2.0 -t hallo-app:2.0 lab02-hallo-app   # neues Image, Tag 2.0
minikube image load hallo-app:2.0                                            # in den Cluster kopieren
```

Erwartet: `minikube image ls` zeigt `docker.io/library/hallo-app:2.0`.

### 2. Secret anlegen

Was passiert: Ihr legt das Secret per Befehl an, ohne Datei. So landet kein Passwort im Repository.

**Aufgabe:** Legt ein Secret `hallo-secret` mit dem Schlüssel `DB_PASSWORT` und dem Wert `uebung123` an. Startet bei `kubectl create --help` und folgt den Unterbefehlen. Prüft das Ergebnis mit `kubectl get secrets`.

Erwartet: `secret/hallo-secret created`. Bei einem zweiten Durchlauf `AlreadyExists`, das vorhandene Secret reicht dann.

`DB_PASSWORT` zeigt nur, wie ein Secret eingebunden wird. Es gibt keine Datenbank, und die Anwendung gibt den Wert nicht aus.

### 3. Ausrollen und das Rolling Update beobachten

Was passiert: Das Deployment holt `GREETING` aus der ConfigMap und `DB_PASSWORT` aus dem Secret. `apply` ersetzt das Deployment von Tag 1. Kubernetes tauscht die Pods einzeln aus.

**Aufgabe:** In [deployment.yaml](deployment.yaml) fehlen zwei Umgebungsvariablen. Ergänzt sie an den `TODO`-Stellen:

- `GREETING` aus der ConfigMap `hallo-config`, Schlüssel `GREETING`
- `DB_PASSWORT` aus dem Secret `hallo-secret`, Schlüssel `DB_PASSWORT`

Als Muster dient `HOSTNAME` direkt darüber, ebenfalls über `valueFrom`. Welche Felder es dort gibt, zeigt `kubectl explain`. Der Befehl steht als Kommentar in der Datei.

```bash
kubectl config current-context                              # erwartet: minikube
kubectl apply -f lab02-hallo-app/betrieb/                   # ConfigMap, Service, Deployment
kubectl rollout status deployment/hallo --timeout=180s      # wartet, bis alle neuen Pods bereit sind
```

Erwartet: `successfully rolled out`. Meldet `apply` einen Fehler, prüft Einrückung, Namen und Schlüssel. Im Beobachtungs-Terminal entsteht erst ein neuer Pod, wird `1/1`, dann verschwindet ein alter. Danach dasselbe noch einmal.

**Gut zu wissen:** YAML erlaubt nur Leerzeichen, keine Tabs. Die Einrückung ist die Struktur.

### 4. Begrüßung ändern

Was passiert: Ihr ändert die ConfigMap. Die laufenden Pods merken davon nichts, bis sie neu starten.

Ändert `GREETING` in [configmap.yaml](configmap.yaml), dann:

```bash
kubectl apply -f lab02-hallo-app/betrieb/configmap.yaml   # nur die ConfigMap aendern
kubectl port-forward service/hallo 8080:80                # Tunnel, im zweiten Terminal: curl http://127.0.0.1:8080/
```

Erwartet: noch die **alte** Begrüßung. Beendet den Tunnel mit Strg+C.

```bash
kubectl rollout restart deployment/hallo                  # alle Pods nacheinander neu starten
kubectl rollout status deployment/hallo --timeout=180s
kubectl port-forward service/hallo 8080:80                # erneut aufrufen
```

Erwartet: die **neue** Begrüßung.

### 5. Ein Secret ist nicht geheim

Was passiert: Ihr lest den Wert aus dem Secret zurück. Jeder mit Leserecht auf Secrets kann das.

**Aufgabe:** Gebt den Wert von `DB_PASSWORT` aus `hallo-secret` erst so aus, wie er im Secret steht, und dann im Klartext. Nur mit `kubectl` und einem Standardwerkzeug der Shell. Tipp: `kubectl get secret --help`, Stichwort `jsonpath`, und `base64 --help`.

Erwartet: erst ein unlesbarer Text, dann `uebung123`. Was folgt daraus für die Frage, wer Secrets lesen darf?

### 6. Readiness brechen und beobachten

Was passiert: Ihr baut einen Fehler in die Readiness-Probe ein und rollt ihn aus. Der neue Pod läuft, wird aber nie bereit. Die alten Pods arbeiten weiter.

Ändert in [deployment.yaml](deployment.yaml) bei `readinessProbe` den Pfad `/actuator/health/readiness` in `/actuator/health/kaputt`. Dann:

```bash
kubectl apply -f lab02-hallo-app/betrieb/deployment.yaml   # kaputte Fassung ausrollen
kubectl rollout status deployment/hallo --timeout=60s      # bricht nach 60 Sekunden ab
kubectl get pods                                           # wer ist bereit?
kubectl describe pod -l app=hallo | grep -i readiness      # die Probe-Meldung
```

Erwartet: zwei alte Pods `1/1`, ein neuer Pod `Running` mit `0/1`. In `describe` steht `Readiness probe failed: HTTP probe failed with statuscode: 404`. Ein Aufruf über `port-forward` funktioniert weiter, er landet bei den alten Pods.

Repariert jetzt die Datei: Pfad zurück auf `/actuator/health/readiness`.

```bash
kubectl apply -f lab02-hallo-app/betrieb/deployment.yaml   # reparierte Fassung
kubectl rollout status deployment/hallo --timeout=180s     # jetzt erfolgreich
```

Erwartet: `successfully rolled out`, wieder zwei Pods `1/1`.

**Gut zu wissen:** Langsame Starter wie eine JVM bekommen zusätzlich eine `startupProbe`. Bis sie Erfolg meldet, laufen Readiness und Liveness nicht.

### 7. Kaputtes Update und Rollback

Was passiert: Ihr setzt ein Image, das es nicht gibt. Das Update bleibt hängen, die Anwendung läuft weiter. Ihr nehmt es zurück.

```bash
kubectl set image deployment/hallo hallo=hallo-app:nicht-vorhanden   # Container hallo bekommt falschen Tag
kubectl rollout status deployment/hallo --timeout=30s                # scheitert nach 30 Sekunden
kubectl get pods                                                     # neuer Pod: ErrImagePull
```

Erwartet: zwei alte Pods `1/1`, ein neuer Pod in `ErrImagePull` oder `ImagePullBackOff`.

**Aufgabe:** Alle Befehle rund um Rollouts zeigt `kubectl rollout --help`. Findet dort heraus,

1. wie ihr die gespeicherten Stände (Revisionen) des Deployments `hallo` anzeigt,
2. wie ihr zur vorherigen Revision zurückkehrt.

Führt beides aus und wartet dann:

```bash
kubectl rollout status deployment/hallo --timeout=180s
```

Erwartet: `successfully rolled out`, der kaputte Pod ist weg.

**Gut zu wissen:** `kubectl set image` ist für Tests. Im Betrieb ändert ihr das Image in der Datei oder die Pipeline tut es, sonst weichen Git und Cluster voneinander ab.

## Checkpoint

```bash
python3 scripts/pruefen.py betrieb
```

Erwartet: `Ergebnis: 0 Pruefung(en) fehlgeschlagen`. Der Checkpoint prüft ConfigMap, Secret, Probes, Ressourcen und die HTTP-Antwort mit Version 2.0. Meldet er `FEHLT` beim Readiness-Pfad, habt ihr Schritt 6 noch nicht repariert.

**Abgabe Tag 2:** Begrüßung aus der ConfigMap, Version 2.0, was ihr in Schritt 6 bei `0/1` gesehen habt, und der Befehl zum Rollback.

## Extra zum Ausprobieren

Für alle, die mit dem Kern fertig sind. Jedes Extra steht für sich und räumt am Ende selbst auf. Der Checkpoint prüft keine Extras.

### Extra 1: Konfiguration als Datei und mit envFrom

[../extra/config-pod.yaml](../extra/config-pod.yaml) startet einen einzelnen Pod, der die ConfigMap auf zwei andere Arten bekommt: als Dateien unter `/config` und mit `envFrom` als Umgebungsvariablen.

```bash
kubectl apply -f lab02-hallo-app/extra/config-pod.yaml
kubectl wait --for=condition=Ready pod/hallo-config-extra --timeout=120s
kubectl exec hallo-config-extra -- cat /config/GREETING; echo     # als Datei
kubectl exec hallo-config-extra -- printenv GREETING              # als Variable
```

Ändert `GREETING` in der ConfigMap und wendet sie an. Prüft beide Befehle nach ein bis zwei Minuten erneut. Was ändert sich, was nicht?

Aufräumen: `kubectl delete -f lab02-hallo-app/extra/config-pod.yaml`.

### Extra 2: Vorher sehen, was sich ändert

Ändert in [deployment.yaml](deployment.yaml) `replicas` auf 3, aber wendet die Datei noch nicht an.

```bash
kubectl diff -f lab02-hallo-app/betrieb/deployment.yaml               # Unterschied Datei zu Cluster
kubectl apply --dry-run=server -f lab02-hallo-app/betrieb/deployment.yaml   # prueft, aendert nichts
```

`diff` endet mit Exit-Code 1, wenn es Unterschiede gibt. Das ist kein Fehler.

Aufräumen: `replicas` in der Datei zurück auf 2.

### Extra 3: Rolling Update rechnen

Das Deployment hat 2 Replikas, `maxSurge: 1`, `maxUnavailable: 0`. Wie viele Pods gibt es während eines Updates höchstens? Wie viele bereite mindestens? Was ändert sich mit `maxSurge: 0` und `maxUnavailable: 1`? Prüft eure Antwort mit `kubectl get pods -w` und einem `rollout restart`.

### Extra 4: Revisionen beschriften

```bash
kubectl annotate deployment/hallo kubernetes.io/change-cause="Begruessung geaendert"
```

Zeigt danach die Revisionen an, mit dem Befehl aus Schritt 7. Die neueste Revision trägt jetzt euren Text. Mit `--revision=NUMMER` seht ihr die Details einer einzelnen Revision.

Aufräumen: `kubectl annotate deployment/hallo kubernetes.io/change-cause-`.

### Extra 5: Wie viel Speicher nimmt sich die JVM?

Das Image setzt `-XX:MaxRAMPercentage=65.0`. Die JVM richtet ihren Heap also nach dem Speicherlimit des Containers.

```bash
kubectl exec deployment/hallo -- java -XX:+PrintFlagsFinal -version 2>/dev/null | grep -E ' MaxHeapSize | MaxRAMPercentage '
```

`MaxHeapSize` steht in Bytes. Rechnet nach: 65 Prozent von 512 MiB. Der Rest bleibt für Metaspace, Threads und JVM-Nebenspeicher.

### Extra 6: Pods automatisch skalieren

[../extra/hpa.yaml](../extra/hpa.yaml) legt einen HorizontalPodAutoscaler an. Er braucht Messwerte vom metrics-server.

```bash
minikube addons enable metrics-server                  # Messwerte fuer CPU und Speicher
kubectl apply -f lab02-hallo-app/extra/hpa.yaml
kubectl get hpa hallo -w                               # TARGETS zeigt nach ein bis zwei Minuten Prozentwerte
kubectl top pods -l app=hallo
```

Ohne Last bleibt es bei 2 Pods. Der HPA skaliert Pods, nie Nodes.

Aufräumen: `kubectl delete -f lab02-hallo-app/extra/hpa.yaml` und `kubectl scale deployment/hallo --replicas=2`.

## Aufräumen

Vor Lab 3:

```bash
kubectl config current-context                     # erwartet: minikube
kubectl delete -f lab02-hallo-app/betrieb/         # alles aus den Dateien in betrieb/
kubectl delete secret hallo-secret                 # steht in keiner Datei
```

Der lokale Cluster bleibt für Lab 3 und Lab 6 bestehen.
