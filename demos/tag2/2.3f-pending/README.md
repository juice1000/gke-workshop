# Demo 2.3f: Pending trotz freier CPU

**Folie:** Tag 2, Check-in 2.3 Ressourcen, Auflösung 1/2 „Pending trotz freier CPU“  
**Dauer:** etwa 3 Minuten  
**Ändert den Cluster:** ja, setzt einen hohen CPU-Request und stellt am Ende die Datei wieder her  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../00-vorbereiten/README.md)

```bash
bash demos/tag2/2.3f-pending/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.3f-pending/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.3f-pending/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Der Scheduler plant nach Requests, nicht nach der tatsächlichen Last. Sind die Requests verplant, bleibt ein Pod Pending, obwohl die CPU kaum arbeitet.

## Schritte und was ihr zeigt

1. `kubectl describe nodes | grep -A8 'Allocated resources'`  
   Zeigen: Vorher: wie viel CPU durch Requests schon verplant ist, z. B. `1450m (18%)`.

2. `kubectl set resources deployment/hallo -c hallo --requests=cpu=...`  
   Zeigen: Jeder neue Pod fordert 60 Prozent der Node-CPU an. Der Wert wird aus der Node-Kapazität berechnet und angesagt.

3. `kubectl get pods -l app=hallo (40 s beobachten)`  
   Zeigen: Ein neuer Pod bleibt `Pending`. Bei 2 CPUs schon der erste, bei 8 CPUs der zweite.

4. `kubectl describe pod PENDING-POD | tail -n 4`  
   Zeigen: Der Beleg: `FailedScheduling ... 0/1 nodes are available: 1 Insufficient cpu`.

5. `kubectl describe nodes | grep -A8 'Allocated resources'`  
   Zeigen: Nachher: CPU-Requests z. B. `6 (75%)`. Verplant, aber kaum benutzt.

## Häufige Fragen

- **Die CPU ist doch frei?** Tatsächlich ja. Der Scheduler schaut aber nur auf die Summe der Requests. Was reserviert ist, ist weg.
- **Was macht GKE in dem Fall?** Mit Cluster Autoscaler kommt ein neuer Node dazu. Ohne bleibt der Pod Pending, wie hier.
- **Merkt der Nutzer etwas?** Nein. Die alten Pods laufen weiter (`maxUnavailable: 0`), nur das Update steht.
- **Warum nicht einfach mehr Kopien?** Docker Desktop meldet minikube oft alle CPUs des Rechners. Mit 10 Kopien blieb bei 8 CPUs kein Pod Pending. Der berechnete Request funktioniert auf jedem Rechner.

## Wenn es hakt

- `Kein Pod Pending`: sehr großer Node. Alternative: Lab 3, Fall 4.

## Aufräumen

Automatisch: `betrieb/deployment.yaml` anwenden, CPU-Request wieder 250m.

Alle Demos: [Übersicht](../../README.md)
