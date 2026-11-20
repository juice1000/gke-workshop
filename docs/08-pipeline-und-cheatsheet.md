# Pipeline und kubectl-Cheat-Sheet

## Wo der Build-Prozess andockt

```text
Commit -> TeamCity: Tests und Build -> Artifactory
       -> Image nach Artifact Registry -> Manifest mit Image-Referenz
       -> kubectl apply -> Deployment -> ReplicaSet -> Pods
```

Die genaue Übergabe von Artifactory in die Registry hängt von der vorhandenen Pipeline ab. Dieses Repository hat keinen Zugriff auf TeamCity, Gitti oder Artifactory. Die Workshop-CI prüft nur die Labs. Sie deployt nichts auf GKE.

Anwendungs-Tests und Image-Build beweisen nicht, dass der neue Pod im Zielcluster bereit wird. Die Pipeline muss auch den Rollout abwarten und bei einem Fehler Diagnoseinformationen liefern. Neue Pods brauchen ein erreichbares Image, passende Architektur, Konfiguration, Secrets und ausreichend Ressourcen.

Für die Übung sind feste Tags `1.0` und `2.0` gut lesbar. Im späteren Prozess bekommen neue Builds eindeutige Referenzen, beispielsweise einen Commit-Tag und den zugehörigen Digest. Eine Tag-Änderung an der Registry ändert kein Deployment automatisch. Die Pipeline muss die gewünschte Image-Referenz im Pod-Template aktualisieren.

Ein Rollback ändert das Clusterobjekt. Die versionierten Manifeste müssen danach ebenfalls auf den beabsichtigten Stand gebracht werden, sonst spielt der nächste Pipeline-Lauf den Fehler erneut aus.

**Diskussionsaufgabe:** Wo liegen Tests, Registry-Zugriff, Rollout-Freigabe, Secret-Verwaltung, Fehlerdiagnose und Rücknahme im heutigen TeamCity-Prozess? Wer besitzt jeweils die Entscheidung?

## Vor jeder Änderung

```bash
kubectl config get-contexts
kubectl config current-context
kubectl config view --minify -o jsonpath='{..namespace}'
```

## Diagnose in vier Schritten

```bash
kubectl get pods -o wide
kubectl describe pod POD_NAME
kubectl logs POD_NAME --tail=100
kubectl logs POD_NAME --previous --tail=100
kubectl get events --sort-by=.metadata.creationTimestamp
```

| Beobachtung | Zuerst prüfen |
| --- | --- |
| `Pending` | Scheduling-Events, Requests, Node-Zustand |
| `ImagePullBackOff` | Tag, Registry-Rechte, Netzwerk, Architektur |
| `CreateContainerConfigError` | Namen und Schlüssel von ConfigMaps/Secrets |
| `CrashLoopBackOff` | Exit-Grund und vorige Logs |
| `OOMKilled` | Containerlimit, JVM-Heap und Nebenspeicher |
| `Running`, `0/1` | Readiness-Pfad, Port und Events |
| Pods bereit, Service nicht erreichbar | Selektor, Ports, EndpointSlices und Netzwerk |

## Service und Rollout

```bash
kubectl get endpointslices -l kubernetes.io/service-name=hallo -o yaml
kubectl port-forward service/hallo 8080:80
kubectl rollout status deployment/hallo --timeout=180s
kubectl rollout history deployment/hallo
kubectl rollout undo deployment/hallo
kubectl auth can-i create deployments.apps
```

## Primärquellen

- [Kubernetes-Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Spring Boot: Actuator und Kubernetes-Probes](https://docs.spring.io/spring-boot/3.5/reference/actuator/endpoints.html)
- [Spring Boot 3.5: Systemanforderungen](https://docs.spring.io/spring-boot/3.5/system-requirements.html)
- [minikube mit Docker](https://minikube.sigs.k8s.io/docs/drivers/docker/)

Die Manifestwerte setzen Probe-Intervalle und Schwellwerte ausdrücklich. Der Kurs hängt dadurch nicht von erinnerten Standardwerten ab.
