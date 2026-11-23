# Lab 2: hallo-app lokal deployen

**Ziel:** Ihr baut ein Image, deployt zwei Kopien und beobachtet Selbstheilung. Dauer: 60 Minuten an Tag 1. Die Abschnitte 4 und 5 sind für Tag 2 und ergänzen Konfiguration, Probes und Updates.

Alle Befehle aus dem Repository-Hauptordner. Voraussetzung: [Lab 0](../lab00-check/README.md). Kontext `minikube`, Namespace `workshop`.

## Worum es geht

In Lab 1 habt ihr einen Cluster gelesen. Jetzt bringt ihr eine eigene Anwendung hinein. Der Weg ist immer derselbe, lokal wie später auf GKE:

```text
Quellcode -> docker build -> Image -> Cluster kann es laden -> Deployment -> Pods <- Service <- ihr
```

- Ein **Image** ist das verpackte Programm mit allem, was es zum Laufen braucht.
- Ein **Deployment** beschreibt, wie viele Kopien (Pods) von welchem Image laufen sollen. Kubernetes hält diesen Sollzustand aufrecht.
- Ein **Service** gibt den Pods eine feste Adresse. Pods kommen und gehen, der Service bleibt.

## Die Anwendung

Eine kleine Spring-Boot-Anwendung (Java 21), die nur Text zurückgibt. So bleibt Kubernetes im Mittelpunkt.

| Pfad | Zweck |
| --- | --- |
| `/` | Begrüßung, Pod-Name und Version als Text |
| `/actuator/health` | Gesundheitsstatus |
| `/actuator/health/liveness` | Läuft die Anwendung? |
| `/actuator/health/readiness` | Ist sie bereit für Anfragen? |
| `/actuator/info` | Version |
| `/fehler` | Absichtlich HTTP 500 und Logzeile mit `FEHLER` |

Drei Umgebungsvariablen steuern die Antwort: `GREETING` die Begrüßung, `APP_VERSION` die Version, `HOSTNAME` den angezeigten Pod-Namen.

## 1. Image bauen und in den Cluster laden

### 1.1 Bauen

```bash
# Image aus dem Dockerfile in lab02-hallo-app bauen. Maven kompiliert und testet
# im Build, danach landet nur die JAR im Laufzeit-Image. Version 1.0 als Tag.
docker build --build-arg APP_VERSION=1.0 -t hallo-app:1.0 lab02-hallo-app
```

`docker build` liest das [Dockerfile](Dockerfile) im Ordner `lab02-hallo-app`. Der Build hat zwei Stufen:

1. Ein Maven-Container mit JDK lädt die Abhängigkeiten, kompiliert und führt die Tests aus. Schlägt ein Test fehl, entsteht kein Image.
2. Nur die fertige JAR-Datei wandert in ein kleines Laufzeit-Image mit Java-Runtime. Es läuft unter einer Benutzer-ID ohne Root-Rechte.

Deshalb braucht ihr weder Java noch Maven lokal. `-t hallo-app:1.0` gibt dem Image Namen und **Tag** (die Versionsbezeichnung). `--build-arg APP_VERSION=1.0` schreibt die Version ins Image. Der erste Build dauert einige Minuten, weil Maven alle Abhängigkeiten lädt. Danach geht es schneller.

### 1.2 Optional: ohne Kubernetes testen

```bash
# Image ohne Kubernetes als einzelnen Container starten. Port 8080 eures
# Rechners geht in den Container. --rm entfernt ihn nach Strg+C.
docker run --rm -p 127.0.0.1:8080:8080 hallo-app:1.0
```

Startet das Image als einzelnen Container. `-p` leitet Port 8080 eures Rechners in den Container weiter. Im zweiten Terminal `curl http://127.0.0.1:8080/`. Erwartet: `Hallo von Pod ..., Version 1.0`, der Name ist hier die Container-ID. Beendet den Container mit Strg+C, sonst ist Port 8080 später belegt. `--rm` entfernt den Container danach.

So prüft ihr, ob ein Problem am Image oder an Kubernetes liegt.

### 1.3 Image an minikube übergeben

```bash
# Image aus eurem Docker in den getrennten Image-Speicher von minikube kopieren
minikube image load hallo-app:1.0

# Alle Images im Cluster auflisten. Gesucht: docker.io/library/hallo-app:1.0
minikube image ls
```

Euer Docker und der minikube-Cluster haben **getrennte Image-Speicher**. Der Cluster sieht euer frisch gebautes Image nicht von selbst. `image load` kopiert es hinein. `image ls` zeigt alle Images im Cluster. Sucht `docker.io/library/hallo-app:1.0`.

Auf GKE übernimmt diese Rolle später eine Registry: Ihr ladet das Image hoch, und der Cluster holt es dort ab.

**Checkpoint:** `hallo-app:1.0` erscheint in `minikube image ls`.

## 2. Deployment und Service

### 2.1 Manifeste lesen

Öffnet [k8s/deployment.yaml](k8s/deployment.yaml) und [k8s/service.yaml](k8s/service.yaml). Ein **Manifest** beschreibt den gewünschten Zustand. Ihr sagt Kubernetes, was laufen soll, nicht wie es zu starten ist.

Im Deployment:

| Feld | Bedeutung |
| --- | --- |
| `replicas: 2` | Zwei Pods sollen laufen |
| `selector.matchLabels: app: hallo` | Diese Pods gehören zum Deployment |
| `template` | Die Vorlage für jeden neuen Pod |
| `template.metadata.labels: app: hallo` | Jeder Pod erhält dieses Label. Es muss zum Selektor passen |
| `image: hallo-app:1.0` | Welches Image läuft |
| `imagePullPolicy: IfNotPresent` | Das lokal geladene Image verwenden, nicht aus dem Internet holen |
| `env HOSTNAME` mit `fieldRef: metadata.name` | Kubernetes trägt den Pod-Namen in die Variable ein. So nennt die Antwort den Pod |
| `containerPort: 8080` | Die Anwendung hört auf Port 8080 |

Im Service:

| Feld | Bedeutung |
| --- | --- |
| `selector: app: hallo` | Der Service leitet an alle Pods mit diesem Label weiter |
| `port: 80` | Der Port des Service |
| `targetPort: 8080` | Der Port im Pod, an den weitergeleitet wird |

Merkt euch: **Labels verbinden alles.** Der Service kennt keine Pod-Namen, er sucht nach dem Label.

### 2.2 Ausrollen

```bash
# Mit welchem Cluster spricht kubectl? Erwartet: minikube
kubectl config current-context
```

Zur Sicherheit vor jeder Änderung: Erwartet `minikube`.

```bash
# Alle Manifeste im Ordner an den Cluster schicken: Deployment und Service
# anlegen oder an die Dateien anpassen. Beliebig oft wiederholbar.
kubectl apply -f lab02-hallo-app/k8s/
```

`apply` schickt alle Manifeste im Ordner an den Cluster. Existiert ein Objekt noch nicht, wird es angelegt. Existiert es schon, wird es an die Datei angepasst. Ihr könnt den Befehl also beliebig oft wiederholen. Erwartet: `deployment.apps/hallo created` und `service/hallo created`.

```bash
# Warten, bis alle Pods des Deployments bereit sind, hoechstens 180 Sekunden
kubectl rollout status deployment/hallo --timeout=180s
```

Wartet, bis alle Pods des Deployments laufen, höchstens 180 Sekunden. Erwartet: `successfully rolled out`. Bricht der Befehl ab, wendet die Reihenfolge aus Lab 1 an: `get pods`, `describe pod`, `logs`.

```bash
# Deployment, Pods und Service auf einen Blick, mit Node und IP
kubectl get deployment,pods,service -o wide
```

Zeigt alle drei Objektarten auf einmal. Erwartet: Deployment `hallo` mit `READY 2/2`, zwei Pods `hallo-...` mit `READY 1/1` und `Running`, ein Service `hallo` mit `PORT(S) 80/TCP` und Typ `ClusterIP`. Die Pod-Namen bestehen aus Deployment-Name, einer Kennung der Vorlage und einer zufälligen Endung.

`ClusterIP` heißt: Der Service ist nur innerhalb des Clusters erreichbar. Von außen kommt ihr im nächsten Schritt über einen Tunnel dran.

An Tag 1 bedeutet `1/1` nur, dass der Container läuft. Ob die Anwendung wirklich Anfragen beantworten kann, prüft Kubernetes erst mit der Readiness-Probe aus Tag 2.

### 2.3 Checkpoint

```bash
# Checkpoint: Replikas, Service, Selektor, Ports und HTTP-Antwort pruefen
python3 scripts/pruefen.py lab02
```

Das Skript prüft Replikas, Service, Selektor, Ports und die HTTP-Antwort. Jede Zeile meldet `OK` oder `FEHLT` mit einem Hinweis.

### 2.4 Die Anwendung aufrufen

```bash
# Tunnel von Port 8080 eures Rechners zu Port 80 des Service.
# Laeuft im Vordergrund, beenden mit Strg+C.
kubectl port-forward service/hallo 8080:80
```

Baut einen Tunnel von Port 8080 eures Rechners zu Port 80 des Service. Der Befehl läuft im Vordergrund, solange der Tunnel offen ist. Öffnet `http://127.0.0.1:8080` im Browser oder führt im zweiten Terminal `curl http://127.0.0.1:8080/` aus. Erwartet: `Hallo von Pod hallo-..., Version 1.0`.

`port-forward service/...` wählt beim Start **einen** Pod aus und bleibt bei ihm. Wiederholte Anfragen zeigen deshalb immer denselben Pod-Namen, obwohl der Service im Cluster auf beide verteilt. Stirbt dieser Pod, bricht der Tunnel ab. Startet ihn dann neu. Ist Port 8080 belegt, nehmt einen anderen, zum Beispiel `18080:80`.

## 3. Selbstheilung und Skalierung

Öffnet ein weiteres Terminal und lasst dort laufen:

```bash
# Pods beobachten: jede Aenderung erscheint als neue Zeile. Beenden mit Strg+C
kubectl get pods -w
```

`-w` zeigt jede Änderung an Pods als neue Zeile. So seht ihr live, was die folgenden Befehle auslösen.

### 3.1 Einen Pod löschen

```bash
# Aktuelle Pods mit Status anzeigen
kubectl get pods

# Einen Pod loeschen. Das Deployment legt sofort einen neuen an
kubectl delete pod POD_NAME

# Neuer Pod mit neuem Namen, Node und IP
kubectl get pods -o wide
```

Ersetzt `POD_NAME` durch einen Namen aus der Liste. Im Beobachtungs-Terminal seht ihr den alten Pod in `Terminating` gehen und fast gleichzeitig einen neuen mit anderem Namen entstehen.

Warum? Das Deployment verlangt zwei Pods. Ein Controller im Cluster vergleicht ständig Soll und Ist. Fehlt ein Pod, legt er einen neuen an. Ihr habt keinen Pod neu gestartet, ihr habt nur den Ist-Zustand verändert. Das ist der Kern von Kubernetes: **Ihr beschreibt den Sollzustand, der Cluster stellt ihn her.**

Lief euer Port-Forward über den gelöschten Pod, ist er jetzt abgebrochen. Startet ihn neu.

### 3.2 Skalieren

```bash
# Sollzustand im Cluster auf vier Pods setzen. Die Datei bleibt unveraendert
kubectl scale deployment hallo --replicas=4

# Warten, bis alle Pods des Deployments bereit sind, hoechstens 180 Sekunden
kubectl rollout status deployment/hallo --timeout=180s

# Aktuelle Pods mit Status anzeigen
kubectl get pods
```

`scale` ändert die gewünschte Anzahl direkt im Cluster. Erwartet: vier Pods `Running`. Der Service nimmt die neuen Pods automatisch auf, weil sie dasselbe Label tragen.

```bash
# Zurueck auf zwei Pods. Kubernetes beendet die ueberzaehligen
kubectl scale deployment hallo --replicas=2

# Warten, bis alle Pods des Deployments bereit sind, hoechstens 180 Sekunden
kubectl rollout status deployment/hallo --timeout=180s
```

Zurück auf zwei. Kubernetes beendet zwei der vier Pods.

Achtung: `scale` ändert nur den Cluster, nicht eure Datei. Ein erneutes `kubectl apply -f lab02-hallo-app/k8s/` setzt die Anzahl wieder auf den Wert aus der Datei. Die Datei ist die Wahrheit, der Cluster folgt ihr.

### 3.3 In einen Pod hineinschauen

```bash
# Befehl in einem laufenden Container ausfuehren: Variable HOSTNAME ausgeben.
# Einfache Anfuehrungszeichen, damit eure Shell $HOSTNAME nicht vorher ersetzt.
kubectl exec deployment/hallo -- sh -c 'echo "$HOSTNAME"'
```

`exec` führt einen Befehl in einem laufenden Container aus. `deployment/hallo` wählt einen seiner Pods. Alles nach `--` läuft im Container. Erwartet: ein Pod-Name. Das zeigt, dass `HOSTNAME` aus dem Manifest im Container angekommen ist. `exec` ist bei der Fehlersuche nützlich, ändert aber nichts dauerhaft: Ein neuer Pod beginnt wieder mit dem Stand des Images.

### 3.4 Logs aller Pods

```bash
# Logs aller Pods mit app=hallo, Pod-Name vor jeder Zeile, letzte 20 Zeilen je Pod
kubectl logs -l app=hallo --prefix --tail=20
```

`-l app=hallo` holt die Logs aller Pods mit diesem Label, also beider Kopien. `--prefix` schreibt vor jede Zeile, aus welchem Pod sie stammt. Erwartet: die Spring-Boot-Startmeldungen, etwa `Started HalloApplication`.

### 3.5 Im Dashboard vergleichen

Öffnet `minikube dashboard` und wählt den Namespace `workshop`. Unter Workloads findet ihr Deployment und Pods, unter Service den Service. Es sind dieselben Objekte wie in der CLI. Die Oberfläche liest nur, was auch `kubectl get` zeigt.

Unter Workloads steht außerdem ein **ReplicaSet**, das in keiner eurer Dateien vorkommt. Das Deployment legt es an und lässt es die Pods verwalten. Auf der Detailseite eines Pods zeigt "Controlled by" diese Kette: Deployment, ReplicaSet, Pod. Mehr dazu im [Rundgang](../lab00-check/RUNDGANG.md).

**Abgabe Tag 1:** Zwei laufende Pods, HTTP-Antwort und ein Satz zum Sollzustand.

## 4. Tag 2: ConfigMap und Secret

Bisher steckt die gesamte Konfiguration im Image. Für eine andere Begrüßung müsstet ihr neu bauen. Eine **ConfigMap** hält Konfiguration außerhalb des Images. Ein **Secret** tut dasselbe für vertrauliche Werte. Das Deployment holt die Werte als Umgebungsvariablen in den Container.

### 4.1 Version 2.0 bauen und ausrollen

```bash
# Gleicher Code, neue Versionsbezeichnung 2.0. Neuer Tag heisst neues Image
docker build --build-arg APP_VERSION=2.0 -t hallo-app:2.0 lab02-hallo-app

# Version 2.0 in den Cluster kopieren
minikube image load hallo-app:2.0
```

Gleicher Quellcode, neue Versionsbezeichnung. Neuer Tag heißt für Kubernetes: neues Image.

```bash
# Secret direkt per Befehl anlegen, ohne Datei. So steht kein Passwort im Repository
kubectl create secret generic hallo-secret --from-literal=DB_PASSWORT=uebung123
```

Legt ein Secret direkt per Befehl an, ohne Datei. So landet das Passwort nicht im Repository. Bei einem wiederholten Durchlauf meldet der Befehl `AlreadyExists`. Das vorhandene Übungs-Secret reicht dann. `DB_PASSWORT` zeigt nur, wie ein Secret eingebunden wird. Es gibt keine Datenbank, und die Anwendung gibt den Wert nicht aus.

```bash
# ConfigMap, Service und erweitertes Deployment anwenden. Das Deployment
# ersetzt die Pods von Tag 1 schrittweise (Rolling Update).
kubectl apply -f lab02-hallo-app/betrieb/

# Warten, bis alle Pods des Deployments bereit sind, hoechstens 180 Sekunden
kubectl rollout status deployment/hallo --timeout=180s

# Checkpoint: ConfigMap, Secret, Probes, Ressourcen und Version 2.0
python3 scripts/pruefen.py betrieb
```

Der Ordner `betrieb/` enthält eine ConfigMap, einen Service und ein erweitertes Deployment mit Version 2.0, Probes und Ressourcen. `apply` ersetzt das bisherige Deployment `hallo` durch diese Fassung. Kubernetes tauscht die Pods schrittweise aus, das ist ein **Rolling Update**. Beobachtet es im Terminal mit `kubectl get pods -w`. Der Checkpoint prüft Konfiguration, Secret, Probes und die HTTP-Antwort mit Version 2.0.

### 4.2 Begrüßung ändern

Ändert `GREETING` in [betrieb/configmap.yaml](betrieb/configmap.yaml) und wendet nur diese Datei an:

```bash
# Nur die geaenderte ConfigMap anwenden. Laufende Pods merken davon nichts
kubectl apply -f lab02-hallo-app/betrieb/configmap.yaml
```

Startet den Port-Forward neu und ruft die Seite auf. Die alte Begrüßung bleibt. Warum? Umgebungsvariablen werden nur beim Start eines Containers gesetzt. Die laufenden Pods kennen den neuen Wert nicht.

```bash
# Alle Pods nacheinander neu starten. Neue Pods lesen die ConfigMap beim Start
kubectl rollout restart deployment/hallo

# Warten, bis alle Pods des Deployments bereit sind, hoechstens 180 Sekunden
kubectl rollout status deployment/hallo --timeout=180s
```

`rollout restart` ersetzt alle Pods nacheinander durch neue, ohne das Manifest zu ändern. Die neuen Pods lesen die ConfigMap beim Start. Jetzt erscheint die neue Begrüßung.

Ein Secret ist nicht sicher, nur weil sein Wert in Base64 dargestellt wird. Base64 ist keine Verschlüsselung. Wer Secrets lesen darf und wie echte Geheimnisse verwaltet werden, ist ein eigenes Betriebsthema.

## 5. Tag 2: Probes, Ressourcen und Rollback

### 5.1 Probes und Ressourcen lesen

Öffnet [betrieb/deployment.yaml](betrieb/deployment.yaml). Eine **Probe** ist eine regelmäßige Prüfung durch Kubernetes, hier ein HTTP-Aufruf eines Health-Pfads.

| Probe | Frage | Folge bei Fehlschlag |
| --- | --- | --- |
| `startupProbe` | Ist der Start abgeschlossen? | Nach zu vielen Fehlschlägen Neustart. Hier bekommt die JVM bis zu etwa 150 Sekunden. Bis zum Erfolg laufen die anderen beiden Probes nicht |
| `readinessProbe` | Kann der Pod jetzt Anfragen annehmen? | Der Service schickt keinen Verkehr mehr an diesen Pod. Kein Neustart |
| `livenessProbe` | Lebt die Anwendung noch? | Kubernetes startet den Container neu |

**Requests** sagen dem Scheduler, wie viel CPU und Speicher ein Pod mindestens braucht. Danach wählt er einen Node mit genug freier Kapazität. Das **Speicherlimit** begrenzt den gesamten Container, inklusive Java-Heap und JVM-Nebenspeicher. Wer es überschreitet, wird beendet (`OOMKilled`). Ein CPU-Limit ist bewusst nicht gesetzt.

`maxUnavailable: 0` und `maxSurge: 1` steuern das Rolling Update: Es fällt nie ein bereiter Pod weg, bevor ein neuer bereit ist, und es entsteht höchstens ein zusätzlicher Pod.

### 5.2 Ein kaputtes Update ausrollen und zurücknehmen

```bash
# Absichtlich kaputtes Update: Container hallo bekommt einen Tag, den es nicht gibt
kubectl set image deployment/hallo hallo=hallo-app:nicht-vorhanden
```

Ändert das Image auf einen Tag, den es nicht gibt. `hallo=` ist der Name des Containers im Deployment.

```bash
# Soll nach 30 Sekunden scheitern: Der neue Pod findet sein Image nicht
kubectl rollout status deployment/hallo --timeout=30s
```

Soll nach 30 Sekunden fehlschlagen. Der neue Pod kann das Image nicht laden.

```bash
# Aktuelle Pods mit Status anzeigen
kubectl get pods

# Alle Events im Namespace nach Zeit. Nennt das fehlende Image
kubectl get events --sort-by=.metadata.creationTimestamp
```

Erwartet: zwei alte Pods weiter `Running` und `1/1`, ein neuer Pod in `ErrImagePull` oder `ImagePullBackOff`. Die Events nennen das fehlende Image. Die Anwendung bleibt erreichbar, weil `maxUnavailable: 0` die alten Pods schützt, solange kein neuer bereit ist.

```bash
# Gespeicherte Staende (Revisionen) des Deployments anzeigen
kubectl rollout history deployment/hallo

# Zur vorherigen Revision zurueck. Aendert nur den Cluster, nicht eure Dateien
kubectl rollout undo deployment/hallo

# Warten, bis alle Pods des Deployments bereit sind, hoechstens 180 Sekunden
kubectl rollout status deployment/hallo --timeout=180s

# Checkpoint: ConfigMap, Secret, Probes, Ressourcen und Version 2.0
python3 scripts/pruefen.py betrieb
```

`history` listet die gespeicherten Stände (Revisionen) des Deployments. `undo` kehrt zur vorherigen Revision zurück. Der kaputte Pod verschwindet, der Checkpoint ist wieder grün.

Kubernetes rollt ein fehlgeschlagenes Update nicht von selbst zurück. Es wartet. `rollout undo` ändert nur das Objekt im Cluster, eure Dateien bleiben unverändert. Der letzte gesunde Stand steht weiter in `betrieb/deployment.yaml`.

**Abgabe Tag 2:** Begrüßung aus ConfigMap, Version 2.0, drei Probe-Pfade und der Befehl zum Rollback.

## Aufräumen

Nach Tag 1 könnt ihr die Anwendung stehen lassen oder `kubectl delete -f lab02-hallo-app/k8s/` ausführen. Vor Lab 3 nach Tag 2:

```bash
# Mit welchem Cluster spricht kubectl? Erwartet: minikube
kubectl config current-context

# Alle Objekte aus den Dateien in betrieb/ loeschen
kubectl delete -f lab02-hallo-app/betrieb/

# Das Secret steht in keiner Datei und wird einzeln geloescht
kubectl delete secret hallo-secret
```

`delete -f` entfernt alle Objekte, die in den Dateien beschrieben sind. Das Secret steht in keiner Datei und wird deshalb einzeln gelöscht. Der lokale Cluster bleibt für Lab 3 und Lab 6 bestehen.
