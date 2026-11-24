# Demo 2.1b: Cluster, Node, Namespace

**Folie:** Tag 2, 2.1 „Eure Fragen: Cluster, Node, Namespace“ (Terminal-Streifen)  
**Dauer:** etwa 2 Minuten  
**Ändert den Cluster:** nein  
**Voraussetzung:** Cluster läuft

```bash
bash demos/tag2/2.1b-cluster-node-namespace/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag2/2.1b-cluster-node-namespace/demo.sh --auto     # ohne Pausen
bash demos/tag2/2.1b-cluster-node-namespace/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Nodes und Namespaces sind zwei unabhängige Richtungen: Der Node sagt, auf welcher Maschine ein Pod läuft. Der Namespace sagt, zu welchem Bereich er gehört.

## Schritte und was ihr zeigt

1. `kubectl get nodes`  
   Zeigen: Ein Node `minikube`, `ROLES control-plane`, `STATUS Ready`, Kubernetes-Version.

2. `kubectl get pods -A -o wide`  
   Zeigen: Spalte `NAMESPACE` (kube-system, workshop) und Spalte `NODE` (alle auf `minikube`). Pods aus verschiedenen Namespaces auf demselben Node.

3. `kubectl api-resources --namespaced=false | grep -E '^NAME|^nodes|^namespaces'`  
   Zeigen: `nodes` und `namespaces` mit `NAMESPACED false`: Sie gehören selbst zu keinem Namespace.

## Häufige Fragen

- **Wechsle ich mit dem Namespace auch den Node?** Nein. Der Namespace ändert nur, welche Objekte `kubectl` ohne `-n` anzeigt. Auf welchem Node ein Pod läuft, entscheidet der Scheduler.
- **Kann ich einen Pod auf einen bestimmten Node legen?** Normalerweise nicht nötig. Mit `nodeSelector`, Affinity oder Taints lässt sich die Platzierung steuern. Lab 4 Extra 3 zeigt die Verteilung über Nodes.
- **Ist ein Namespace eine Sicherheitsgrenze?** Nur zusammen mit RBAC (Tag 3) und NetworkPolicy. Für sich ist er ein logischer Bereich für Namen und Rechte.
- **Hat minikube immer einen Node?** Standardmäßig ja. Mehr gehen mit `minikube start --nodes=3` oder `minikube node add`.

## Wenn es hakt

- Viele Pods in `kube-system`: normal, das ist die Control Plane von minikube. Demo 2.6a geht darauf ein.

## Aufräumen

Nicht nötig, die Demo ändert nichts.

Alle Demos: [Übersicht](../../README.md)
