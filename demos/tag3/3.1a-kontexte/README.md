# Demo 3.1a: Welcher Cluster, welcher Namespace?

**Folie:** Tag 3, 3.1 Rückblick, Zugänge prüfen  
**Dauer:** etwa 2 Minuten  
**Ändert den Cluster:** nein, wechselt auch keinen Kontext  
**Voraussetzung:** Cluster läuft

```bash
bash demos/tag3/3.1a-kontexte/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag3/3.1a-kontexte/demo.sh --auto     # ohne Pausen
bash demos/tag3/3.1a-kontexte/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Der aktuelle Kontext entscheidet, wohin ein `kubectl` ohne `--context` geht. Sicher ist nur ein fester Kontext im Befehl.

## Schritte und was ihr zeigt

1. `kubectl config get-contexts`  
   Zeigen: Alle Kontexte der kubeconfig, der Stern markiert den aktuellen. Spalte `NAMESPACE`.

2. `kubectl config current-context`  
   Zeigen: Nur der Name. Auf GKE beginnt er mit `gke_PROJEKT_ZONE_CLUSTER`.

3. `kubectl config view --minify -o jsonpath='{..namespace}'; echo`  
   Zeigen: Der Standard-Namespace dieses Kontexts. Leer heißt `default`.

4. `kubectl --context minikube get nodes`  
   Zeigen: Fester Kontext im Befehl. Die Demos setzen ihn immer.

## Häufige Fragen

- **Ist der Kontext eine Sicherheitsgrenze?** Nein. Er ist nur ein Verbindungsprofil auf eurem Rechner. Rechte regeln IAM und RBAC.
- **Wie wechsle ich?** `kubectl config use-context NAME`. Das gilt für alle Terminals mit derselben kubeconfig.
- **Wie schütze ich mich vor dem falschen Cluster?** `--context` in Skripten immer ausdrücklich setzen und vor Änderungen `current-context` prüfen.

## Wenn es hakt

- Kein GKE-Kontext in der Liste: Lab 4, Schritt 1 (`get-credentials`) fehlt.

## Aufräumen

Nicht nötig, die Demo ändert nichts.

Alle Demos: [Übersicht](../../README.md)
