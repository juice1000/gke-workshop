# Lab 1: kubectl-Rallye

**Ziel:** Ihr lest Clusterzustand, Logs und Events und findet Befehle selbst. Dauer: 35 Minuten. Voraussetzung: [Lab 0](../lab00-check/README.md). Diese Rallye ändert keine Kubernetes-Objekte.

## Worum es geht

Bevor ihr eigene Anwendungen deployt, lernt ihr, einen Cluster zu lesen. Genau diese Befehle braucht ihr später bei jeder Fehlersuche. Als Übungsobjekt dient ein Pod, der in jedem Cluster schon läuft: CoreDNS, der interne DNS-Dienst. Er übersetzt Service-Namen in Adressen. Ab Lab 2 findet so zum Beispiel ein Pod euren Service `hallo` über dessen Namen. Ihr seht hier also einen gesunden Pod. An Tag 2 vergleicht ihr kaputte Pods mit diesem Bild.

Alle Befehle lesen nur. Ihr könnt nichts kaputt machen. Nennt vor jedem Befehl, was er zeigen soll, und vergleicht danach mit der Ausgabe.

Jeder Schritt trägt eine Markierung, wie oft ihr den Befehl im Betrieb braucht: **täglich**, **bei Störungen** oder **gelegentlich**. Die Übersicht dazu steht unter [Was ihr im Alltag braucht](#was-ihr-im-alltag-braucht).

## Schritte

### 1. Wo bin ich? (täglich)

```bash
kubectl config current-context
```

kubectl kann mehrere Cluster kennen. Der **Kontext** legt fest, mit welchem Cluster und welchem Namespace der nächste Befehl spricht. Erwartet: `minikube`. Ab Tag 2 kommt ein GKE-Kontext dazu. Dann ist dieser Befehl der wichtigste Schutz davor, im falschen Cluster etwas zu ändern.

### 2. Welche Namespaces gibt es? (gelegentlich)

```bash
kubectl get namespaces
```

Ein **Namespace** trennt Objekte in Gruppen, ähnlich wie Ordner. Erwartet: `default`, `kube-node-lease`, `kube-public`, `kube-system` und euer `workshop` aus Lab 0. In `kube-system` laufen die Bausteine des Clusters selbst.

### 3. Was läuft im ganzen Cluster? (täglich)

```bash
kubectl get pods -A
```

`get pods` listet Pods auf. `-A` heißt: in allen Namespaces. Ohne `-A` seht ihr nur den Namespace aus eurem Kontext, also `workshop`, der noch leer ist. Lest zuerst die Spalte `STATUS`. `Running` ist der Normalfall. Die Spalte `READY` zeigt, wie viele Container im Pod bereit sind, zum Beispiel `1/1`.

### 4. Einen Pod gezielt finden (täglich)

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

`-n kube-system` wählt den Namespace. `-l k8s-app=kube-dns` filtert nach einem **Label**. Labels sind Schlüssel-Wert-Paare an Objekten. Kubernetes selbst findet Pods über Labels, zum Beispiel ein Service seine Pods. Erwartet: ein Pod `coredns-...` mit `Running`.

### 5. Details und Ereignisse eines Pods (bei Störungen)

```bash
kubectl describe pod -n kube-system -l k8s-app=kube-dns
```

`describe` fasst alles Wichtige zu einem Objekt lesbar zusammen: Node, IP, Image, Ports, Probes, Zustand der Container und ganz unten den Abschnitt `Events`. **Events** sind die Notizen des Clusters über das Objekt: geplant, Image geladen, gestartet, Probe fehlgeschlagen. Bei einem Pod, der nicht startet, schaut ihr hier zuerst. Bei einem lange laufenden Pod kann der Abschnitt leer sein, weil Events nach einiger Zeit verfallen.

### 6. Was schreibt die Anwendung? (täglich)

```bash
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=30
```

`logs` zeigt, was der Prozess im Container auf die Standardausgabe schreibt. `--tail=30` begrenzt auf die letzten 30 Zeilen. Wichtig ist der Unterschied zu Schritt 5: **Logs** kommen von der Anwendung, **Events** vom Cluster. Startet ein Container gar nicht erst, gibt es keine Logs, aber Events.

### 7. Die vollständige Beschreibung (gelegentlich)

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns -o yaml
```

`-o yaml` zeigt das Objekt so, wie der Cluster es gespeichert hat. Oben steht `spec`, der gewünschte Zustand. Unten steht `status`, der tatsächliche Zustand. Sucht `spec.containers[].image` (welches Image) und `spec.nodeName` (auf welchem Node). Die Ausgabe ist lang. Ihr braucht sie selten ganz, aber sie ist die Quelle für alles, was `get` und `describe` anzeigen.

### 8. Felder nachschlagen (gelegentlich)

```bash
kubectl explain pod.spec.containers.image
```

`explain` ist die eingebaute Dokumentation. Sie erklärt jedes Feld eines Manifests, ohne Internet. Probiert auch `kubectl explain pod.spec` für eine Übersicht aller Felder.

### 9. Was ist im Namespace passiert? (bei Störungen)

```bash
kubectl get events -n kube-system --sort-by=.metadata.creationTimestamp
```

Zeigt alle Events eines Namespaces, nach Zeit sortiert. In Schritt 5 saht ihr nur die Events eines Pods. Hier seht ihr alle, auch die von Objekten, die es nicht mehr gibt. Leere Events sind möglich, wenn der Cluster schon eine Weile ruhig läuft.

Falls der DNS-Selektor keine Pods findet, schaut mit `kubectl get pods -n kube-system --show-labels` nach den vorhandenen Labels. Namen und Images können je nach Cluster-Version abweichen.

## Was ihr im Alltag braucht

Nicht jeder Befehl ist gleich wichtig. Diese Einteilung hilft, beim Lernen Prioritäten zu setzen.

### Täglich: Diese Befehle sitzen nach dem Kurs

| Befehl | Wofür | Warum so oft |
| --- | --- | --- |
| `kubectl config current-context` | Prüfen, mit welchem Cluster ihr sprecht | Wer mit mehreren Clustern arbeitet (lokal, Test, Produktion), prüft das vor jeder Änderung. Ein Befehl im falschen Cluster ist der häufigste vermeidbare Fehler |
| `kubectl get pods` (mit `-n`, `-l`, `-A`, `-w`) | Status auf einen Blick | Der erste Blick nach jedem Deployment und bei jeder Meldung "geht nicht". Mit `-l` und `-n` findet ihr in großen Clustern schnell die richtigen Pods |
| `kubectl logs` (mit `--tail`, `-f`, `-l`) | Was die Anwendung sagt | Die meisten Fehler einer Anwendung stehen in ihren eigenen Logs. `-f` folgt neuen Zeilen live |

### Bei Störungen: Das Werkzeug, wenn ein Pod nicht läuft

| Befehl | Wofür | Warum gerade dann |
| --- | --- | --- |
| `kubectl describe pod` | Zustand und Events eines Pods | Erklärt, warum ein Pod nicht startet: Image fehlt, kein Platz auf einem Node, Probe schlägt fehl. Das sind die Fälle ohne Anwendungslogs |
| `kubectl get events --sort-by=.metadata.creationTimestamp` | Zeitlicher Ablauf im Namespace | Zeigt, was nacheinander passiert ist, auch bei Objekten, die es nicht mehr gibt. Events verfallen nach etwa einer Stunde, im Normalbetrieb sind sie selten interessant |

### Gelegentlich: Gut zu wissen, wo es steht

| Befehl | Wofür | Wann |
| --- | --- | --- |
| `kubectl get namespaces` | Überblick über Bereiche im Cluster | Beim ersten Kontakt mit einem Cluster. Danach kennt ihr euren Namespace |
| `kubectl get ... -o yaml` | Vollständiges Objekt mit `spec` und `status` | Wenn `get` und `describe` nicht reichen, etwa um ein Feld exakt zu prüfen oder den Cluster-Stand mit eurer Datei zu vergleichen |
| `kubectl explain` | Felder eines Manifests nachschlagen | Beim Schreiben oder Lesen von YAML. Spart die Suche in der Dokumentation |

## Die Reihenfolge bei Störungen

Aus den Schritten ergibt sich das Vorgehen für jede Fehlersuche im Kurs:

1. `kubectl get pods`: Welcher Status?
2. `kubectl describe pod NAME`: Was sagen die Events?
3. `kubectl logs NAME`: Was sagt die Anwendung?
4. `kubectl get events --sort-by=.metadata.creationTimestamp`: Was ist im Namespace passiert?

## Selbst herausfinden (10 Minuten)

Jetzt ohne vorgegebene Befehle. Das ist der Alltag im Betrieb: Ihr wisst, welche Information ihr braucht, und sucht den Weg dorthin. Werkzeuge:

- `kubectl BEFEHL --help` zeigt Optionen und Beispiele
- `kubectl explain` erklärt Felder
- [kubectl Quick Reference](https://kubernetes.io/docs/reference/kubectl/quick-reference/)

Alle Aufgaben lesen nur.

1. **Nur Warnungen.** Zeigt in `kube-system` ausschließlich Events vom Typ `Warning`. Tipp: Events haben ein Feld `type`. Sucht in `kubectl get --help` nach einer Option, die nach Feldern filtert.
2. **Image auf einen Blick.** Gebt für jeden Pod in `kube-system` eine Zeile aus: Pod-Name und Image, ohne die lange YAML-Ausgabe. Tipp: `kubectl get --help`, Stichwort `custom-columns`. Den Pfad zum Image kennt ihr aus Schritt 7.
3. **Wer startet neu?** Sortiert die Pods in `kube-system` nach der Anzahl ihrer Neustarts. Tipp: `--sort-by` und das Feld `restartCount` im Status eines Pods (`kubectl explain pod.status.containerStatuses`).
4. **Kurzformen.** Welche Kurzform hat `deployments`, welche `services`? Gibt es ein Objekt `namespaces` in einem Namespace? Tipp: Ein Befehl listet alle Objektarten mit Kurzform und der Spalte `NAMESPACED`.

Aufgaben 3 und 4 sind für Schnelle. Notiert zu jeder Aufgabe den Befehl, den ihr gefunden habt. Ihr braucht sie in Lab 3 wieder.

## Checkpoint

```bash
python3 scripts/pruefen.py dns
```

Das Skript prüft, ob ihr mit dem richtigen Cluster sprecht und die DNS-Pods laufen. Es liest nur und meldet `OK` oder `FEHLT` mit einem Hinweis.

**Abgabe:** DNS-Pod, Image, Node, euer Befehl aus Aufgabe 1 und ein Satz dazu, welche Ausgabe euch bei einem fehlgeschlagenen Image-Pull helfen würde.

## Bonus

```bash
kubectl get nodes -o wide
kubectl get pods -n kube-system -w
```

`-o wide` zeigt zusätzliche Spalten, beim Node etwa die Kubernetes-Version, die IP und das Betriebssystem. `-w` (watch) beobachtet die Liste und zeigt jede Änderung als neue Zeile. Beendet die Beobachtung mit Strg+C. Das beendet nur den Befehl, die Pods laufen weiter.
