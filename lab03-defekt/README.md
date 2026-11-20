# Lab 3: Fünf defekte Deployments

**Ziel:** Ihr findet Ursachen anhand von Belegen. Dauer: 35 Minuten, zu zweit. Voraussetzung: Image `hallo-app:1.0` in minikube, Kontext `minikube`, Namespace `workshop`. Die Anwendung aus Lab 2 vorher aufräumen.

## Vorgehen je Fall

Wendet genau eine Datei an. Ersetzt in den folgenden Befehlen `N` durch 1 bis 5:

```bash
kubectl config current-context
kubectl apply -f lab03-defekt/fallN.yaml
kubectl get pods -l app=fallN
kubectl describe pod -l app=fallN
kubectl logs deployment/fallN
kubectl logs deployment/fallN --previous
kubectl get events --sort-by=.metadata.creationTimestamp
```

Nicht jeder Befehl liefert in jedem Fall Logs. Ein Container, der noch nicht angelegt wurde, kann noch keine Anwendungsausgabe haben. Auch `--previous` liefert nur nach einem tatsächlichen Neustart etwas.

1. Notiert Symptom und einen Beleg aus Logs oder Events.
2. Formuliert die Ursache vor der Änderung.
3. Repariert die Datei und wendet sie erneut an.
4. Prüft mit `kubectl rollout status deployment/fallN --timeout=180s` und `kubectl get pods -l app=fallN`.
5. Löscht den Fall vor dem nächsten mit `kubectl delete -f lab03-defekt/fallN.yaml`.

Jeder Fall hat einen Fehler. Namen und Labels sind absichtlich getrennt, damit sich die Fälle nicht gegenseitig beeinflussen. Wendet nicht den ganzen Ordner rekursiv an, sonst würden auch Lösungen ausgerollt.

Für Fall 2 gehört zur Reparatur das Anlegen der fehlenden ConfigMap. Räumt sie danach mit `kubectl delete configmap fall2-config` auf.

**Abgabe:** Pro Fall eine Zeile: Symptom, Ursache, Diagnosebefehl und Änderung. Beispiel: „Fall N: kein Start, fehlendes Objekt in den Events, Namen korrigiert“.

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

Bei Bedarf `kubectl apply -f lab03-defekt/loesungen/fallN.yaml`. Mit derselben Lösungsdatei könnt ihr danach alle Ressourcen dieses Falls entfernen. Netzwerk- und Registryfehler können den genauen Eventtext von Fall 1 verändern.

</details>
