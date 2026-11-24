# Demo 2.2b: CreateContainerConfigError

**Folie:** Tag 2, Check-in 2.2, Auflösung 2/2 „CreateContainerConfigError“  
**Dauer:** etwa 4 Minuten  
**Ändert den Cluster:** ja, legt Lab 3 Fall 2 und den Namespace `demo-anders` an und räumt beide ab  
**Voraussetzung:** Cluster läuft, `hallo-app:1.0` geladen

```bash
bash demos/tag2/2.2b-falscher-namespace/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.2b-falscher-namespace/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.2b-falscher-namespace/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Ein Pod sieht nur ConfigMaps aus seinem eigenen Namespace. Die ConfigMap existiert, aber am falschen Ort.

## Schritte und was ihr zeigt

1. `kubectl apply -f lab03-defekt/fall2.yaml`  
   Zeigen: Ein Deployment, das die ConfigMap `fall2-config` braucht.

2. `kubectl get pods -l app=fall2 (15 s beobachten)`  
   Zeigen: `0/1 CreateContainerConfigError`. Der Container wurde nie gestartet.

3. `kubectl create namespace demo-anders / create configmap fall2-config -n demo-anders`  
   Zeigen: Die ConfigMap entsteht, aber im falschen Namespace.

4. `kubectl get configmap -A | grep -E 'NAMESPACE|fall2'`  
   Zeigen: Mit `-A` ist sie da: `demo-anders   fall2-config`.

5. `kubectl get configmap`  
   Zeigen: Im eigenen Namespace fehlt sie. Nur dort sucht der Pod.

6. `kubectl describe pod -l app=fall2 | tail -n 4`  
   Zeigen: Der Beleg: `Error: configmap "fall2-config" not found`.

7. `kubectl config view --minify | grep namespace`  
   Zeigen: In welchem Namespace arbeitet euer Terminal ohne `-n`?

8. `kubectl create configmap fall2-config --from-literal=GREETING=Hallo`  
   Zeigen: Reparatur im eigenen Namespace.

9. `kubectl get pods -l app=fall2 (30 s beobachten)`  
   Zeigen: Nach einigen Sekunden `1/1 Running`, ohne weiteres Zutun.

## Häufige Fragen

- **Warum startet der Pod nach der Reparatur von selbst?** Das kubelet versucht es regelmäßig erneut. Sobald die ConfigMap da ist, klappt der Start.
- **Warum liefert `kubectl logs` hier nichts?** Der Container wurde nie angelegt. Die Ursache steht in den Events, nicht in den Logs.
- **Kann ein Pod eine ConfigMap aus einem anderen Namespace nutzen?** Nein. ConfigMap, Secret und Service-Referenzen gelten immer im eigenen Namespace.
- **Ist das nicht Lab 3?** Ja, Fall 2. In Lab 3 suchen die Teilnehmenden die Ursache selbst. Die Demo zeigt eine Variante davon, nicht die Lösung von Fall 2 Schritt für Schritt.

## Wenn es hakt

- Reste nach einem Abbruch: Demo 00 entfernt `fall2`, `fall2-config` und `demo-anders`.

## Aufräumen

Automatisch: `fall2`, `fall2-config` und Namespace `demo-anders` löschen.

Alle Demos: [Übersicht](../../README.md)
