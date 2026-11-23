# Lab 5: Abschlussübung

**Ziel:** Ihr schreibt ein vollständiges Deployment und untersucht drei fehlgeschlagene Releases. Dauer: 90 Minuten, zu zweit. Alle Befehle aus dem Repository-Hauptordner.

Voraussetzung: Zielkontext und eigener Namespace aus Lab 4, erreichbares Image der Version 2.0. Die Anwendung aus Lab 4 vorher entfernen. Alternativ funktioniert diese Übung lokal, siehe unten.

## Etappe A: Selbst deployen (25 Minuten)

1. Prüft `kubectl config get-contexts`. Aktueller Kontext, `WORKSHOP_CONTEXT` und Namespace müssen zusammenpassen.
2. Setzt `IMAGE` wie in Lab 4 auf euer bereits hochgeladenes Image. Erstellt eine Arbeitskopie:

```bash
python3 scripts/render.py lab05-abschluss --image "$IMAGE" --output out/lab05
kubectl create secret generic hallo-secret --from-literal=DB_PASSWORT=uebung123
```

3. Ergänzt `out/lab05/starter/deployment.yaml`. Ersetzt `TODO_IMAGE` durch den Wert von `IMAGE`. Schreibt die beiden Umgebungsvariablen, Ressourcen und drei Probes gemäß den TODO-Kommentaren. ConfigMap und Service sind fertig. Muster findet ihr in [Lab 2](../lab02-hallo-app/betrieb/deployment.yaml).
4. Wendet nur `starter/` an:

```bash
kubectl apply -f out/lab05/starter/
kubectl rollout status deployment/hallo --timeout=600s
python3 scripts/pruefen.py abschluss
kubectl port-forward service/hallo 8080:80
```

Im zweiten Terminal `curl http://127.0.0.1:8080/`. Erwartet: `Hallo zum Abschluss von Pod ..., Version 2.0`.

**Abgabe A:** Zwei bereite Pods, Antwort und grüner Checkpoint. `DB_PASSWORT` wird nur als Umgebungsvariable eingebunden. Verwendet keine echten Zugangsdaten.

## Etappe B: Drei kaputte Releases (45 Minuten)

Die Dateien enthalten komplette Deployments. Sie verwenden denselben Anwendungscode der Version 2.0, ändern aber die Betriebsbeschreibung. Wendet immer nur ein Release an. Nicht den gesamten Ordner `out/lab05` anwenden.

Beginnt jedes Release mit eurem gesunden Starter. Damit bezeichnet ein anschließendes `rollout undo` wieder einen bekannten Stand. Beendet alte HTTP-Tunnel bei Bedarf und startet sie neu.

Für Release A:

```bash
kubectl apply -f out/lab05/starter/
kubectl rollout status deployment/hallo --timeout=600s
kubectl apply -f out/lab05/releases/release-a.yaml
kubectl rollout status deployment/hallo --timeout=60s
kubectl get pods -o wide
kubectl describe pod -l app=hallo
kubectl logs -l app=hallo --prefix --tail=50
kubectl get events --sort-by=.metadata.creationTimestamp
```

Der Rollout soll scheitern. Wählt für `logs --previous` gezielt einen neuen Pod mit Neustarts. Ein Log-Aufruf über `deployment/hallo` kann einen alten gesunden Pod auswählen.

Notiert das Symptom und einen Beleg. Prüft die bisherige HTTP-Antwort über einen neu geöffneten Tunnel. Schaut auf GKE zusätzlich in Workloads und Logs Explorer. Rollt dann zurück:

```bash
kubectl rollout undo deployment/hallo
kubectl rollout status deployment/hallo --timeout=600s
python3 scripts/pruefen.py abschluss
```

Korrigiert eure Arbeitskopie von `release-a.yaml`, wendet sie erneut an und prüft Rollout und Checkpoint. Wiederholt denselben Ablauf für `release-b.yaml` und `release-c.yaml`. Setzt vor jedem neuen Fall mit dem Starter auf den gesunden Ausgangsstand zurück.

Warum antworten die alten Pods weiter? Sucht die beiden Einstellungen unter `strategy.rollingUpdate`. Das funktioniert, solange die alten Pods selbst gesund bleiben und genug Kapazität für den zusätzlichen Pod vorhanden ist.

**Abgabe B:** Pro Release Symptom, Ursache, Beleg, Reparatur und Rollback-Befehl.

<details>
<summary>Hinweise</summary>

- A: Welche Schlüssel enthält `hallo-config`, welcher wird referenziert?
- B: Vergleicht JVM-Heap und Containerlimit. Heap ist nur ein Teil des Prozessspeichers. Lest `State` und `Last State` des neuen Containers.
- C: Vergleicht HTTP-Pfad und Readiness-Event. `Running` allein genügt nicht.

</details>

Kommt ihr nicht weiter, fragt den Trainer. Die Auflösung besprechen wir gemeinsam nach dem Lab.

## Etappe C: Rechte prüfen (10 Minuten)

```bash
kubectl auth can-i create deployments.apps
kubectl auth can-i create deployments.apps -n kube-system
kubectl auth can-i get secrets
kubectl auth can-i list nodes
```

**Abgabe C:** Vier Antworten und eure Erklärung. Erwartet in der vorbereiteten Teilnehmerrolle: im eigenen Namespace Deployments und Secrets erlaubt, keine Deployment-Änderung in `kube-system`. Das Auflisten von Nodes hängt von zusätzlichen Rechten ab.

`can-i` zeigt das wirksame Ergebnis. Es beweist auf GKE allein nicht, ob eine Freigabe von IAM oder RBAC kommt. Zusätzliche IAM-Rechte können Zugriff erlauben, den eine enge RBAC-Rolle nicht gewährt. Vergleicht die Antworten mit der Konfiguration des Trainers.

## Aufräumen (10 Minuten)

```bash
kubectl config current-context
kubectl delete -f out/lab05/starter/
kubectl delete secret hallo-secret
kubectl get deployment,pods,service,configmap,secret
```

In einem frischen Namespace kann ein systemseitig vorhandenes Objekt übrig bleiben. `kubectl get all` würde ConfigMaps und Secrets nicht vollständig abdecken.

## Ohne Cloud

```bash
export WORKSHOP_CONTEXT=minikube
export WORKSHOP_NAMESPACE=workshop
export IMAGE=hallo-app:2.0
kubectl config use-context "$WORKSHOP_CONTEXT"
kubectl config set-context "$WORKSHOP_CONTEXT" --namespace="$WORKSHOP_NAMESPACE"
minikube image load hallo-app:2.0
```

Dann Etappen A und B unverändert mit einer neuen Arbeitskopie ausführen. In minikube habt ihr normalerweise Admin-Rechte. Daher zeigt Etappe C dort andere Ergebnisse; die Cloud-Abgrenzung wird gemeinsam besprochen.
