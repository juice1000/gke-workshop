# Demo 3.6b: PDB blockiert drain

**Folie:** Tag 3, 3.6 Lab 7: Vertiefung Betrieb  
**Dauer:** etwa 3 Minuten  
**Ändert den Cluster:** ja, legt ein PDB an, sperrt den Node und räumt beides ab, auch bei Strg+C  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../../tag2/00-vorbereiten/README.md)

```bash
bash demos/tag3/3.6b-pdb-drain/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag3/3.6b-pdb-drain/demo.sh --auto     # ohne Pausen
bash demos/tag3/3.6b-pdb-drain/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Ein PodDisruptionBudget schützt vor geplanten Unterbrechungen. Mit `minAvailable: 2` bei zwei Pods darf `drain` keinen Pod verdrängen.

## Schritte und was ihr zeigt

1. `kubectl get deploy hallo`  
   Zeigen: Zwei Pods bereit.

2. `kubectl create pdb hallo-pdb-demo --selector=app=hallo --min-available=2`  
   Zeigen: Mindestens 2 müssen bleiben. Lab 7 nutzt 1, hier absichtlich 2.

3. `kubectl get pdb hallo-pdb-demo`  
   Zeigen: `ALLOWED DISRUPTIONS 0`.

4. `kubectl drain minikube --pod-selector=app=hallo --timeout=30s; echo "Exit-Code: $?"`  
   Zeigen: Wiederholt `Cannot evict pod as it would violate the pod's disruption budget`, nach 30 s `Exit-Code: 1`.

5. `kubectl get nodes`  
   Zeigen: Node gesperrt: `SchedulingDisabled`.

6. `kubectl get pods -l app=hallo`  
   Zeigen: Beide Pods laufen trotzdem weiter.

## Häufige Fragen

- **Schützt ein PDB vor Abstürzen?** Nein. Nur vor freiwilligen Unterbrechungen wie `drain` oder Node-Upgrade.
- **Was macht GKE bei einem Upgrade?** Es wartet, bis das PDB es zulässt, höchstens eine Stunde. Danach verdrängt es trotzdem.
- **Welcher Wert ist sinnvoll?** So, dass mindestens eine Unterbrechung erlaubt bleibt. Bei 2 Pods `minAvailable: 1`, wie in Lab 7.

## Wenn es hakt

- Nach hartem Abbruch: `kubectl uncordon minikube` und `kubectl delete pdb hallo-pdb-demo`.

## Aufräumen

Automatisch: `uncordon`, PDB löschen, `rollout status`.

Alle Demos: [Übersicht](../../README.md)
