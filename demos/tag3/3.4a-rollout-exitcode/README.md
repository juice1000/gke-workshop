# Demo 3.4a: Exit-Code von rollout status

**Folie:** Tag 3, 3.4 Anbindung an den Build-Prozess  
**Dauer:** etwa 3 Minuten  
**Ändert den Cluster:** ja, setzt einen falschen Tag, rollt zurück und stellt am Ende die Datei wieder her  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../../tag2/00-vorbereiten/README.md)

```bash
bash demos/tag3/3.4a-rollout-exitcode/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag3/3.4a-rollout-exitcode/demo.sh --auto     # ohne Pausen
bash demos/tag3/3.4a-rollout-exitcode/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Eine Pipeline erkennt einen gescheiterten Rollout am Exit-Code von `kubectl rollout status`. Nicht 0 heißt: abbrechen und zurückrollen.

## Schritte und was ihr zeigt

1. `kubectl set image deployment/hallo hallo=hallo-app:gibtsnicht`  
   Zeigen: Die Pipeline deployt einen Tag, den es nicht gibt.

2. `kubectl rollout status deployment/hallo --timeout=30s; echo "Exit-Code: $?"`  
   Zeigen: `timed out`, dann `Exit-Code: 1`.

3. `kubectl get pods -l app=hallo`  
   Zeigen: Die alten Pods bedienen weiter, der neue hängt beim Image.

4. `kubectl rollout undo deployment/hallo`  
   Zeigen: Zurück auf die vorige Revision.

5. `kubectl rollout status deployment/hallo --timeout=180s; echo "Exit-Code: $?"`  
   Zeigen: `successfully rolled out`, `Exit-Code: 0`.

## Häufige Fragen

- **Was macht TeamCity mit dem Exit-Code?** Ein Schritt mit Exit-Code ungleich 0 schlägt fehl. Darauf hängt man den Rollback-Schritt.
- **Warum `--timeout=30s`?** Ohne Timeout wartet `rollout status` bis zur `progressDeadlineSeconds`. Die Pipeline soll eine klare Grenze haben.
- **Ist danach alles gut?** Im Cluster ja. Das Repository nennt aber noch den kaputten Stand, wenn die Pipeline ihn eingetragen hat. Siehe Demo 2.4d.

## Wenn es hakt

- Nach Strg+C stellt das Skript `betrieb/deployment.yaml` wieder her.

## Aufräumen

Automatisch: `betrieb/deployment.yaml` anwenden.

Alle Demos: [Übersicht](../../README.md)
