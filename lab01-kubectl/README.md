# Lab 1: kubectl-Rallye

**Ziel:** Ihr lest Clusterzustand, Logs und Events. Dauer: 25 Minuten. Voraussetzung: [Lab 0](../lab00-check/README.md). Diese Rallye ändert keine Kubernetes-Objekte.

## Aufgabe

Führt jeden Befehl selbst aus. Nennt vor dem nächsten Befehl, was er zeigen soll.

```bash
kubectl config current-context
kubectl get namespaces
kubectl get pods -A
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl describe pod -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=30
kubectl get pods -n kube-system -l k8s-app=kube-dns -o yaml
kubectl explain pod.spec.containers.image
kubectl get events -n kube-system --sort-by=.metadata.creationTimestamp
```

Sucht in den Ausgaben:

1. Den aktuellen Kontext. Erwartet: `minikube`.
2. Einen DNS-Pod, sein Image und seinen Node.
3. Den Abschnitt `Events` in `describe`.
4. Den Unterschied zwischen einem Pod-Log und einem Kubernetes-Event.

Leere Events sind möglich. Falls der DNS-Selektor keine Pods findet, schaut mit `kubectl get pods -n kube-system --show-labels` nach den vorhandenen Labels. Namen und Images können je nach Cluster-Version abweichen.

## Checkpoint

```bash
python3 scripts/pruefen.py dns
```

**Abgabe:** DNS-Pod, Image, Node und ein Satz dazu, welche Ausgabe euch bei einem fehlgeschlagenen Image-Pull helfen würde.

## Bonus

```bash
kubectl get nodes -o wide
kubectl get pods -n kube-system -w
```

Beendet die Beobachtung mit Strg+C. Das beendet den Befehl, die Pods laufen weiter.

<details>
<summary>Auflösung</summary>

Der DNS-Pod heißt in minikube üblicherweise `coredns-...`. `spec.containers[].image` enthält das Image, `spec.nodeName` den Node. Anwendungslogs stammen vom Prozess im Container. Events beschreiben Clusteraktionen wie Scheduling, Image-Pulls oder fehlgeschlagene Probes. Bei einem Image-Pull-Fehler beginnt ihr mit `describe pod` und den Events.

</details>
