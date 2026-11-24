# Demo 00: Ausgangslage herstellen

**Folie:** vor 2.1, vor Kursbeginn. Danach nach jeder hart abgebrochenen Demonstration.  
**Dauer:** 1 bis 5 Minuten (Image-Bau beim ersten Mal)  
**Ändert den Cluster:** ja, stellt den Stand aus `lab02-hallo-app/betrieb/` her  
**Voraussetzung:** minikube läuft

```bash
bash demos/tag2/00-vorbereiten/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/00-vorbereiten/demo.sh --auto     # ohne Pausen
bash demos/tag2/00-vorbereiten/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Keine Folie. Das ist eure Vorbereitung, bevor die Teilnehmenden kommen.

## Schritte und was ihr zeigt

1. `minikube status`  
   Zeigen: `host`, `kubelet`, `apiserver` auf `Running`.

2. `docker build ... / minikube image load ...`  
   Zeigen: Nur, wenn `hallo-app:1.0` oder `2.0` fehlt. Sonst `ist schon geladen`. Lab 3 und Demo 2.4d brauchen 1.0, `betrieb/` braucht 2.0.

3. `kubectl create secret generic hallo-secret --from-literal=DB_PASSWORT=uebung123 || true`  
   Zeigen: `AlreadyExists` ist in Ordnung: Das Secret gibt es schon.

4. `kubectl delete ... --ignore-not-found`  
   Zeigen: Entfernt Reste anderer Demos: `oom`, HPA, PDB, Role `demo-leser`.

5. `kubectl apply -f lab02-hallo-app/betrieb/`  
   Zeigen: Alles `configured` oder `unchanged`. Ein Service mit `type: LoadBalancer` aus eigenen Versuchen wird wieder `ClusterIP`: Die Datei gewinnt.

6. `kubectl rollout status deployment/hallo --timeout=180s`  
   Zeigen: `successfully rolled out`.

7. `kubectl get pods -l app=hallo`  
   Zeigen: Zwei Pods, `1/1`, `Running`.

## Wenn es hakt

- `Kontext minikube fehlt`: minikube läuft nicht. `minikube start`.
- Der Rollout hängt: Ein Image fehlt im Cluster. `minikube image ls | grep hallo`.
- Schneller ohne Pausen: `--auto` anhängen.

## Aufräumen

Nicht nötig. Das Skript ist der Ausgangszustand.

Alle Demos: [Übersicht](../../README.md)
