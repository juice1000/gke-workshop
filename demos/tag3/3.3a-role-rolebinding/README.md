# Demo 3.3a: Role und RoleBinding

**Folie:** Tag 3, 3.3 Zugriffsrechte  
**Dauer:** etwa 3 Minuten  
**Ändert den Cluster:** ja, legt Role und RoleBinding `demo-leser` an und löscht beide  
**Voraussetzung:** Cluster läuft, Namespace `workshop`

```bash
bash demos/tag3/3.3a-role-rolebinding/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag3/3.3a-role-rolebinding/demo.sh --auto     # ohne Pausen
bash demos/tag3/3.3a-role-rolebinding/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Die Role sagt WAS, das RoleBinding sagt WER. Erst beides zusammen gibt ein Recht.

## Schritte und was ihr zeigt

1. `kubectl auth can-i list pods --as demo-person@example.com`  
   Zeigen: `no`. Die Testperson hat noch keine Rechte. `--as` prüft für eine andere Person.

2. `kubectl create role demo-leser --verb=get,list,watch --resource=pods,pods/log`  
   Zeigen: Role: Pods lesen, sonst nichts, nur im Namespace `workshop`.

3. `kubectl auth can-i list pods --as demo-person@example.com`  
   Zeigen: Weiter `no`. Die Role allein bewirkt nichts.

4. `kubectl create rolebinding demo-leser --role=demo-leser --user=demo-person@example.com`  
   Zeigen: Verbindet Role und Person.

5. `kubectl auth can-i list pods --as demo-person@example.com`  
   Zeigen: `yes`.

6. `kubectl auth can-i delete pods / get secrets --as demo-person@example.com`  
   Zeigen: Beide `no`. Was nicht in der Role steht, ist verboten.

7. `kubectl auth can-i --list --as demo-person@example.com | head -n 8`  
   Zeigen: Alle Rechte der Person in diesem Namespace.

## Häufige Fragen

- **Darf ich `--as` immer benutzen?** Nur mit dem Recht `impersonate`. Lokal seid ihr Admin, auf GKE als Teilnehmende nicht.
- **Was ist mit IAM auf GKE?** IAM kommt davor: Ohne IAM-Zugang zum Cluster hilft kein RoleBinding. IAM sagt, wer an den Cluster darf, RBAC, was im Namespace.
- **Role oder ClusterRole?** Eine Role gilt in einem Namespace. Eine ClusterRole im ganzen Cluster oder als Vorlage für viele Namespaces.
- **Wo ist das vollständige Beispiel?** `trainer/rbac.yaml`, so sind die Teilnehmenden-Namespaces eingerichtet.

## Wenn es hakt

- Reste nach Abbruch: `kubectl delete rolebinding,role demo-leser`.

## Aufräumen

Automatisch: RoleBinding und Role `demo-leser` löschen.

Alle Demos: [Übersicht](../../README.md)
