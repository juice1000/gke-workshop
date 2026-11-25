# Demo 3.4d: Ein Merge auf main rollt aus

**Folie:** Tag 3, 3.4 „Merge auf main: dieselbe Pipeline in GitHub Actions“  
**Dauer:** etwa 8 Minuten  
**Ändert den Cluster:** ja, rollt `cicd-demo/` nach `workshop-trainer` aus  
**Voraussetzung:** [trainer/einrichtung/github-actions.sh](../../../trainer/einrichtung/github-actions.sh) einmal ausgeführt, `hallo-secret` in `workshop-trainer` vorhanden (`bash scripts/basis.sh lab06` legt es an), im Browser bei GitHub angemeldet. Kein Skript: Die Demo läuft im Browser.

GitHub Actions ist das Beispiel, das wir zeigen können. Beim Kunden heißt das Werkzeug TeamCity. Die Stufen sind dieselben, das sagt auch die Folie.

## Der Satz dazu

> Dasselbe Skript, dieselben fünf Stufen. Nur startet es jetzt niemand von Hand, sondern ein Merge. Und die Pipeline meldet sich bei Google ohne Schlüssel an.

## Vorher (zu Beginn von 3.4)

Mergt den grünen Lauf schon zu Beginn von 3.4, dann ist er fertig, wenn die Folie kommt. Ein Lauf dauert etwa 4 bis 6 Minuten, der Image-Build ist der größte Teil.

## Schritte und was ihr zeigt

1. **CI-Hälfte:** `https://github.com/juice1000/gke-workshop/actions/workflows/test.yml`  
   Zeigen: Jeder Push und jeder Pull Request prüft Manifeste und Skripte (`validate.sh`) und spielt die Labs auf minikube durch. Das ist der Prüfschritt vor dem Merge.

2. **Grüner Lauf:** Im Browser `cicd-demo/configmap.yaml` öffnen, Stift-Symbol, `GREETING` ändern, z. B. `Hallo aus dem Merge`. Unten „Create a new branch“, Pull Request öffnen, mergen.  
   Zeigen: Unter Actions startet „Deploy-Demo“. Die Schritte: Anmelden (ohne Schlüssel), Docker-Anmeldung, Cluster-Zugang, Pipeline mit `[1/5]` bis `[5/5]` im Log, `Pipeline GRUEN`.

3. **Ergebnis im Cluster:**  
   ```bash
   kubectl --context "$GKE_CONTEXT" -n workshop-trainer get deploy hallo -o wide   # Spalte IMAGES: 2.0-<commit>
   kubectl --context "$GKE_CONTEXT" -n workshop-trainer logs deploy/hallo --tail=3
   ```
   Zeigen: Der Image-Tag enthält den Commit des Merges. In der Zusammenfassung des Laufs steht dieselbe Kurzform.

4. **Anmeldung ohne Schlüssel:** im Lauf den Schritt `auth` aufklappen.  
   Zeigen: GitHub weist sich mit einem kurzlebigen OIDC-Token aus. Google prüft Repository und Branch und gibt ein Token für das Konto `gh-deployer`. Im Repository liegt kein Schlüssel. Dasselbe Prinzip wie Workload Identity in 3.3. Das Konto darf nur in `workshop-trainer` ausrollen:  
   ```bash
   kubectl --context "$GKE_CONTEXT" auth can-i create deployments -n workshop-person01 \
     --as=gh-deployer@lookbeyond-gke-workshop.iam.gserviceaccount.com   # no
   ```

5. **Roter Lauf** (wenn Zeit ist): Pull Request, der in `cicd-demo/deployment.yaml` den Readiness-Pfad auf `/bereit-aber-falsch` setzt, wie Störung 6.3. Mergen.  
   Zeigen: Gate läuft in die Zeitgrenze, Rollback, der Job ist rot. Unter „Artifacts“ liegt `pipeline-belege` mit `describe.txt`. Danach den Pull Request mit „Revert“ zurücknehmen und mergen, der nächste Lauf ist wieder grün.

## Wenn es hakt

- **Lauf startet nicht:** Der Workflow reagiert nur auf Änderungen in `cicd-demo/` auf `main`. Notfalls unter Actions, „Deploy-Demo“, „Run workflow“ (Branch `main`).
- **`auth` scheitert mit `unauthorized` oder `attribute condition`:** Lauf kam nicht von `main` in `juice1000/gke-workshop`. Genau das soll der Provider verhindern.
- **Pipeline GESTOPPT, Cluster nicht erreichbar:** RBAC fehlt. `bash trainer/einrichtung/github-actions.sh` erneut ausführen.
- **Gate rot ohne Absicht:** `hallo-secret` fehlt in `workshop-trainer`. `bash scripts/basis.sh lab06` mit Trainer-Umgebung.
- **Hängt länger als 15 Minuten:** Der Job bricht von selbst ab (`timeout-minutes: 15`). Dann zeigt 3.4 nur die CI-Hälfte aus Schritt 1.

## Gut zu wissen

- Ein echtes Setup erzwingt Pull Request und grüne Prüfung vor dem Merge (Branch Protection). Hier ist sie heute aus, weil Inhalte direkt auf `main` gepflegt werden.
- Kein Auslöser für Pull Requests: Bei einem öffentlichen Repository könnten sonst Forks Code mit Cloud-Zugang ausführen.
