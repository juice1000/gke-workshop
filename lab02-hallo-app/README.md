# Lab 2: hallo-app lokal deployen

**Ziel:** Ihr baut ein Image, deployt zwei Kopien und beobachtet Selbstheilung. Dauer: 60 Minuten an Tag 1. Die Abschnitte für Tag 2 ergänzen Konfiguration, Probes und Updates.

Alle Befehle aus dem Repository-Hauptordner. Voraussetzung: [Lab 0](../lab00-check/README.md). Kontext `minikube`, Namespace `workshop`.

## 1. Anwendung und Image verstehen

| Pfad | Zweck |
| --- | --- |
| `/` | Begrüßung, Pod-Name und Version als Text |
| `/actuator/health` | Gesundheitsstatus |
| `/actuator/health/liveness` | Läuft die Anwendung? |
| `/actuator/health/readiness` | Ist sie bereit für Anfragen? |
| `/actuator/info` | Version |
| `/fehler` | Absichtlich HTTP 500 und Logzeile mit `FEHLER` |

`GREETING` ändert die Begrüßung, `APP_VERSION` die angezeigte Version. Der Docker-Build setzt die Version per `ARG`. Das Manifest setzt `HOSTNAME` über `fieldRef: metadata.name` ausdrücklich auf den Pod-Namen. Die Anwendung nutzt Spring Boot 3.5.16 und Java 21. Maven, JDK und Tests sind im mehrstufigen Docker-Build enthalten. Im fertigen Image laufen eine JRE und eine Shell unter einer nicht privilegierten UID.

```bash
docker build --build-arg APP_VERSION=1.0 -t hallo-app:1.0 lab02-hallo-app
minikube image load hallo-app:1.0
minikube image ls
```

**Checkpoint:** `hallo-app:1.0` ist im Image-Speicher von minikube vorhanden. Euer Docker und minikube haben getrennte Image-Speicher.

Optional vor Kubernetes testen:

```bash
docker run --rm -p 127.0.0.1:8080:8080 hallo-app:1.0
```

In einem zweiten Terminal `curl http://127.0.0.1:8080/`, danach den Container mit Strg+C beenden. Port 8080 muss für das spätere Port-Forwarding wieder frei sein.

## 2. Deployment und Service

Lest [k8s/deployment.yaml](k8s/deployment.yaml) und [k8s/service.yaml](k8s/service.yaml). Findet Replikazahl, Image, Labels, Selektor und Portzuordnung.

```bash
kubectl config current-context
kubectl apply -f lab02-hallo-app/k8s/
kubectl rollout status deployment/hallo --timeout=180s
kubectl get deployment,pods,service -o wide
python3 scripts/pruefen.py lab02
```

Erwartet: zwei Pods mit `READY 1/1` und ein Service `hallo` mit Port 80. An Tag 1 bedeutet `1/1` zunächst, dass der Container läuft. Die ausdrückliche Readiness-Prüfung ergänzt ihr an Tag 2.

```bash
kubectl port-forward service/hallo 8080:80
```

Öffnet `http://127.0.0.1:8080` oder führt in einem zweiten Terminal `curl http://127.0.0.1:8080/` aus. Erwartet: `Hallo von Pod hallo-..., Version 1.0`.

`port-forward service/...` verbindet euch mit einem ausgewählten Pod. Wiederholte Anfragen an denselben Tunnel zeigen keine Lastverteilung. Stirbt dieser Pod, müsst ihr den Tunnel neu starten.

## 3. Selbstheilung und Skalierung

Beobachtet im zweiten Terminal `kubectl get pods -w`. Wählt einen Pod-Namen aus `kubectl get pods` und ersetzt `POD_NAME`:

```bash
kubectl delete pod POD_NAME
kubectl get pods -o wide
kubectl scale deployment hallo --replicas=4
kubectl rollout status deployment/hallo --timeout=180s
kubectl get pods
kubectl scale deployment hallo --replicas=2
kubectl rollout status deployment/hallo --timeout=180s
kubectl exec deployment/hallo -- sh -c 'echo "$HOSTNAME"'
kubectl logs -l app=hallo --prefix --tail=20
```

Warum entsteht ein neuer Pod, obwohl ihr nur gelöscht habt? Vergleicht CLI und Dashboard. Ein erneutes `apply` der Datei setzt die deklarierte Replikazahl wieder auf 2.

**Abgabe Tag 1:** Zwei laufende Pods, HTTP-Antwort und ein Satz zum Sollzustand.

## 4. Tag 2: ConfigMap und Secret

Baut Version 2.0 und ladet sie in minikube:

```bash
docker build --build-arg APP_VERSION=2.0 -t hallo-app:2.0 lab02-hallo-app
minikube image load hallo-app:2.0
kubectl create secret generic hallo-secret --from-literal=DB_PASSWORT=uebung123
kubectl apply -f lab02-hallo-app/betrieb/
kubectl rollout status deployment/hallo --timeout=180s
python3 scripts/pruefen.py betrieb
```

Bei einem wiederholten Durchlauf kann das Secret bereits existieren. Nutzt dann das vorhandene Übungs-Secret. `DB_PASSWORT` demonstriert nur die Einbindung eines Secrets. Es gibt keine Datenbank und die Anwendung gibt den Wert nicht aus.

Ändert `GREETING` in [betrieb/configmap.yaml](betrieb/configmap.yaml) und wendet nur diese Datei an. Was zeigt ein neu gestarteter HTTP-Tunnel? Warum bleibt die alte Begrüßung?

```bash
kubectl apply -f lab02-hallo-app/betrieb/configmap.yaml
kubectl rollout restart deployment/hallo
kubectl rollout status deployment/hallo --timeout=180s
```

Umgebungsvariablen werden beim Containerstart gesetzt. Nach dem Neustart erscheint der neue Wert. Ein Secret ist kein sicherer Ort für Daten, nur weil es in Base64 dargestellt wird. Zugang und Umgang mit echten Geheimnissen sind ein eigenes Betriebsthema.

## 5. Tag 2: Probes, Ressourcen und Rollback

Lest [betrieb/deployment.yaml](betrieb/deployment.yaml). Die Startup-Probe gibt der JVM bis zu ungefähr 150 Sekunden, bevor ihre Fehlschläge einen Neustart auslösen. Bis die Startup-Probe erfolgreich ist, laufen Liveness und Readiness noch nicht. Readiness steuert die Aufnahme in die bereiten Service-Ziele. Liveness kann einen Container neu starten.

Requests reservieren Kapazität für die Planung. Das Speicherlimit begrenzt den gesamten Container, inklusive Heap und JVM-Nebenspeicher. Ein CPU-Limit ist für diese Übung nicht gesetzt. `maxUnavailable: 0` und `maxSurge: 1` lassen während eines Updates zwei bereite Pods weiterlaufen und höchstens einen zusätzlichen Pod entstehen.

Rollt absichtlich einen fehlenden Tag aus:

```bash
kubectl set image deployment/hallo hallo=hallo-app:nicht-vorhanden
kubectl rollout status deployment/hallo --timeout=30s
kubectl get pods
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl rollout history deployment/hallo
kubectl rollout undo deployment/hallo
kubectl rollout status deployment/hallo --timeout=180s
python3 scripts/pruefen.py betrieb
```

Der erste `rollout status` soll fehlschlagen. Kontrolliert die alten und neuen Pods. Kubernetes rollt ein fehlgeschlagenes Deployment nicht automatisch zurück. Der letzte gesunde Stand steht weiterhin in der Datei unter `betrieb/`. `rollout undo` ändert das Clusterobjekt, eure Dateien bleiben unverändert.

**Abgabe Tag 2:** Begrüßung aus ConfigMap, Version 2.0, drei Probe-Pfade und der Befehl zum Rollback.

## Aufräumen

Nach Tag 1 könnt ihr die Anwendung stehen lassen oder `kubectl delete -f lab02-hallo-app/k8s/` ausführen. Vor Lab 3 nach Tag 2:

```bash
kubectl config current-context
kubectl delete -f lab02-hallo-app/betrieb/
kubectl delete secret hallo-secret
```

Der lokale Cluster bleibt für Lab 3 und Lab 6 bestehen.
