# Demo 3.4c: Unsere Pipeline

**Folie:** Tag 3, 3.4 „Unsere Pipeline“  
**Dauer:** etwa 4 Minuten  
**Ändert den Cluster:** ja, rollt die Lab-5-Lösung und Störung 6.3 aus, stellt am Ende `betrieb/` wieder her  
**Voraussetzung:** Ausgangslage aus [00-vorbereiten](../../tag2/00-vorbereiten/README.md)

```bash
bash demos/tag3/3.4c-pipeline/demo.sh            # Schritt für Schritt: [Enter] ausführen, [s] überspringen
bash demos/tag3/3.4c-pipeline/demo.sh --auto     # ohne Pausen
bash demos/tag3/3.4c-pipeline/demo.sh --trocken  # nur Befehle zeigen
```

## Der Satz dazu

> Eine Pipeline sind dieselben Befehle wie von Hand, plus ein Gate (`rollout status` mit Zeitgrenze), das grün oder rot entscheidet, plus eine automatische Reaktion (Belege sichern, zurückrollen).

## Schritte und was ihr zeigt

1. `sed -n '/^# Stufe/,/^# \[5\/5\]/p' scripts/pipeline.sh`  
   Zeigen: die fünf Stufen und welchem TeamCity-Schritt sie entsprechen. Hier knüpft das Gespräch über die Build-Konfiguration beim Kunden an.

2. `bash scripts/pipeline.sh out/demo-3.4c/loesung/; echo "Exit-Code: $?"`  
   Zeigen: `[1/5]` bis `[5/5]`, Build und Rollback `uebersprungen`, `Pipeline GRUEN`, `Exit-Code: 0`.

3. `bash scripts/pipeline.sh out/demo-3.4c/stoerungen/6.3-bereitschaft.yaml; echo "Exit-Code: $?"`  
   Zeigen: Gate `timed out`, Belege gesichert, `rollout undo`, `Pipeline ROT`, `Exit-Code: 1`. Erscheint beim Undo eine Warnung: Der Cluster läuft wieder alt, die Datei nennt den neuen Stand (Demo 2.4d).

4. `ls "$BELEGE"` und `grep 'Readiness probe failed' "$BELEGE/describe.txt"`  
   Zeigen: vier Belegdateien. In `describe.txt` steht die Ursache: Readiness-Pfad liefert 404.

5. `kubectl get pods -l app=hallo`  
   Zeigen: zwei bereite Pods vom alten Stand. Nutzer haben vom Fehler nichts gemerkt.

## Häufige Fragen

- **Warum ein Skript und kein TeamCity?** Die Stufen sind dieselben. TeamCity ruft pro Build-Schritt ein Skript auf und wertet den Exit-Code aus. Wer das Skript versteht, versteht die Build-Konfiguration.
- **Warum 45 Sekunden?** Damit der rote Lauf in die Demo passt. Im Lab wartet das Gate 120 Sekunden (`PIPELINE_TIMEOUT`).
- **Wo ist der Build?** Ohne `--build` nimmt die Pipeline das Image aus dem Manifest. Mit `--build` baut sie zuerst ein Image mit dem Git-Commit im Tag. Das ist das Extra in Lab 6.
- **Was heißt Exit-Code 2?** Die Pipeline hat vor dem Deploy angehalten: falscher Kontext, Platzhalter im Manifest, Dry Run abgelehnt. Im Cluster hat sich nichts geändert.

## Wenn es hakt

- `Deployment hallo fehlt` oder `ConfigMap hallo-config fehlt`: zuerst `bash demos/tag2/00-vorbereiten/demo.sh`.
- Grüner Lauf wird rot: Der Cluster lief noch mit einem kaputten Stand. 00-vorbereiten ausführen, dann die Demo erneut.
- Nach Strg+C stellt das Skript `betrieb/` wieder her.

## Aufräumen

Automatisch: `betrieb/` anwenden, `rollout restart`, damit die Pods die Begrüßung aus `betrieb/configmap.yaml` wieder lesen. Die Belege bleiben in `out/pipeline/`, die gerenderten Dateien in `out/demo-3.4c/`.

Alle Demos: [Übersicht](../../README.md)
