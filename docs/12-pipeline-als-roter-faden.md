# Brief: The pipeline as the backbone of every lab

Brief for Claude Code in `gke-workshop`. Read `AGENTS.md`, `docs/11-cicd-brief.md`, `scripts/pipeline.sh`, `scripts/render.py`, `lab06-abschluss/README.md`, `lab07-betrieb/README.md` and `lab05-stoerungen/` first. Everything in `AGENTS.md` still applies.

## Idea in one sentence

Every change to the cluster goes through `scripts/pipeline.sh`, every fault comes as a numbered YAML file, every finding is backed by logs, secrets come from Google Secret Manager, and one script brings the namespace back to a known good state, so nobody gets stuck and everyone can start the next part clean.

## Why

- CI/CD is how the customer works (TeamCity, Artifactory, Artifact Registry, GKE). Today it is one block (3.4) and one lab stage. It should be the normal way to deploy from the first cloud lab on.
- Lab 3 was skipped on Day 2. Troubleshooting is the customer's top goal. Participants need many short break, find, fix rounds, not one long lab.
- Today a broken namespace stays broken: `rollout undo` only reverts the Deployment, `stoerung.sh` patches objects by hand, and hand-made objects (e.g. the demo LoadBalancer) pile up. People who fall behind cannot catch up.

## Phase 0: Renumbering (decided 25 Nov, 13:15 SGT, do this first)

Participants have not received the Day 3 material yet, so today's labs are renumbered in the order they run. Labs 0 to 4 keep their numbers (participants already typed those paths). Lab 1 and Lab 3 stay bonus.

| New | Old | Folder new (old) | Runs |
| --- | --- | --- | --- |
| Lab 5 Störungssuche mit Logs | Lab 7 | `lab05-stoerungen/` (`lab07-stoerungen/`) | 3.2, short version |
| Lab 6 Abschlussübung mit Pipeline | Lab 5 | `lab06-abschluss/` (`lab05-abschluss/`) | 3.5, afternoon, devs |
| Lab 7 Vertiefung Betrieb | Lab 6 | `lab07-betrieb/` (`lab06-betrieb/`) | 3.6, afternoon, ops, parallel |

Fault numbers follow the lab: 5.1 to 5.5 (Störungssuche, `stoerung.sh 1` to `5`), 6.1 to 6.6 (Abschluss, 6.4 to 6.6 Secret Manager), 7.1 to 7.3 (Betrieb). This whole document already uses the new numbers.

What Claude Code does:

- [ ] `git mv` the three folders (via a temporary name, the names overlap)
- [ ] In `lab06-abschluss/`: `releases/release-a.yaml` to `stoerungen/6.1-konfiguration.yaml`, `release-b` to `6.2-speicher.yaml`, `release-c` to `6.3-bereitschaft.yaml`; `repariert/` files renamed to match. No comment in a fault file may name its cause
- [ ] Output folders: Störungssuche renders to `out/lab05/` (`AUSGABE` in `stoerung.sh`), Abschluss to `out/lab06/`. `stoerung.sh` prints `Stoerung 5.1 eingebaut: ...` but keeps the arguments `1` to `5`
- [ ] Update every reference: lab READMEs (titles "Lab 5: Störungssuche mit Logs", "Lab 6: Abschlussübung", "Lab 7: Vertiefung Betrieb"), root `README.md`, `AGENTS.md`, `scripts/pruefen.py`, `scripts/validate.sh`, `scripts/check-files.py`, `scripts/integration.py`, `demos/` (3.4c uses `out/lab06/stoerungen/6.3-bereitschaft.yaml`, 3.6a/b use `lab07-betrieb/`), `trainer/RUNBOOK.md`, `docs/06`, `docs/07`, `docs/09`. Add one line at the top of `docs/11-cicd-brief.md`: "Renumbered on 25 Nov, see docs/12"
- [ ] Same on `practice` (without solutions)
- [ ] `grep -rn "lab05-abschluss\|lab06-betrieb\|lab07-stoerungen\|release-[abc]"` returns nothing outside `docs/11`
- [ ] Separate commit "Renumber Day 3 labs in run order" before any other Phase

The Day 3 slides already use these paths (published 25 Nov 13:20 SGT):

```text
3.2   bash lab05-stoerungen/stoerung.sh start | pruefen | 1 | 4 | aufloesen
      kubectl logs deployment/verkehr -f
3.4   bash scripts/pipeline.sh out/lab06/starter/
      bash scripts/pipeline.sh out/lab06/stoerungen/6.3-bereitschaft.yaml   (Demo 3.4c)
3.5   python3 scripts/render.py lab06-abschluss --image "$IMAGE" --output out/lab06
      kubectl apply -f out/lab06/starter/ ; python3 scripts/pruefen.py abschluss
      bash scripts/pipeline.sh out/lab06/stoerungen/6.1-*.yaml
      kubectl delete -f out/lab06/starter/
3.6   kubectl --context minikube -n workshop apply -f lab07-betrieb/pdb.yaml
```

If anything here cannot be done by 16:00 SGT, say so at once, so the slides can be switched back.

## The rhythm (same in every lab part)

```text
1. Basis       bash scripts/basis.sh lab06            -> GRUEN, Ausgangslage steht
2. Stoerung    bash scripts/pipeline.sh out/lab06/stoerungen/6.1-*.yaml
                                                       -> ROT (Gate) oder GRUEN, aber kaputt
3. Suchen      Belege der Pipeline, kubectl, auf GKE Logs Explorer
4. Beheben     Datei nach out/lab06/fix/ kopieren, aendern, wieder durch die Pipeline -> GRUEN
5. Pruefen     bash scripts/basis.sh lab06 --pruefen   -> alle Checks OK
6. Weiter      bash scripts/basis.sh lab06             -> sauberer Start fuer 6.2
```

Step 6 also works from a broken state. That is the safety net: stuck for more than 10 minutes, reset, read the solution, go on.

## Numbering and layout

Faults are numbered per lab: `5.1`, `6.1`, `6.2`, `7.1`. The number is what slides, README, demo and Abgabe table use.

```text
labNN-name/
  basis/                 known good state: every object the lab needs, WORKSHOP_IMAGE placeholder
  stoerungen/
    N.1-kurzname.yaml    only the object(s) that change, exactly one fault each
    N.2-kurzname.yaml
  loesungen/             main only: fixed file + one line cause per fault
  README.md              same rhythm for every part
```

Rules for fault files:

- Valid YAML that passes `kubectl apply --dry-run=server`. The fault is in the behaviour, not the syntax (syntax errors are a separate, explicit case if wanted)
- Exactly one fault per file. No comment that names the cause
- Expressible as `apply` only. No `kubectl patch`, `delete` or `set env` inside the lab flow, so the pipeline is always the way in
- Every object carries the label `workshop-lab: "NN"` so the reset script can find and remove what the lab created
- Kurzname describes the symptom area, not the cause (`6.2-speicher.yaml`, not `6.2-limit-zu-klein.yaml`)

## Scripts

### `scripts/basis.sh LAB [TEIL] [--pruefen]` (new)

1. Check `WORKSHOP_CONTEXT`, `WORKSHOP_NAMESPACE`, `IMAGE` like `pipeline.sh`. Refuse `kube-system` and other namespaces than the participant's
2. Render the whole lab folder fresh into `out/labNN/` (current `IMAGE`, existing files replaced, never the source)
3. Remove drift: delete objects with label `workshop-lab=NN` that are not in `basis/`, and print a warning for unlabelled objects in the namespace (`Fremdes Objekt im Namespace: service/hallo-...`), without deleting them
4. Ensure `hallo-secret` exists with the course value (Secret stays out of Git, as today)
5. Run `scripts/pipeline.sh out/labNN/basis/`. Must end GRUEN
6. Run the lab's health checks (the `pruefen` checks from `lab05-stoerungen/stoerung.sh` moved here, generalised): ready replicas, no restarts, Service has endpoints, HTTP 200 from inside the namespace
7. Print `Ausgangslage NN steht.` Exit 0 green, 1 not healthy, 2 wrong input

`TEIL` selects a checkpoint inside a lab (`basis/2b/`), so people who fell behind can jump to the start of a part. `--pruefen` runs only step 6.

### `scripts/pipeline.sh` (extend, keep the interface and output words)

- Accept manifests without a Deployment (a Service or ConfigMap alone). The gate always checks `deployment/hallo` in the namespace, and also `deployment/verkehr` when it exists
- New stage **Smoke-Test** after the gate: one HTTP request to `http://hallo/` from inside the namespace (short-lived curl pod or the `verkehr` logs). Red on failure, same rollback as today. Keep the five stage labels on screen, show the smoke test as part of `[4/5] Gate`
- Rollback stays `rollout undo` today (slides show it). Phase 2: re-apply the last green manifest set (`out/pipeline/letzter-gruener-stand/`), which also reverts Service and ConfigMap changes. Note the difference in the README
- Write `out/pipeline/verlauf.txt`: one line per run, time, manifest, GRUEN/ROT/GESTOPPT. Participants use it for the Abgabe

## Teaching point to build in

Not every fault turns the pipeline red. Lab 6 faults are caught by the gate. Lab 5 faults pass it: GRUEN, and users still get errors. That is the bridge between 3.4 (CI/CD) and 3.2 (logs): a gate checks what you told it to check. Every fault table in the solutions gets a column **Pipeline: rot / gruen**.

## Fault catalogue

| Nr | File | What breaks | Pipeline | Where it shows |
| --- | --- | --- | --- | --- |
| 5.1 | `5.1-neustarts.yaml` | liveness path wrong | gruen, then restarts | events: Liveness probe failed, RESTARTS |
| 5.2 | `5.2-stiller-service.yaml` | Service targetPort 8081 | rot with smoke test, gruen without | EndpointSlice port, verkehr: curl-Fehler 7 |
| 5.3 | `5.3-geheimnis.yaml` | secretKeyRef to a Secret that does not exist | rot | describe: secret not found |
| 5.4 | `5.4-fehlerflut.yaml` | verkehr calls `/fehler` (env PFADE) | gruen | logs: ERROR FEHLER in series |
| 5.5 | `5.5-alte-begruessung.yaml` | ConfigMap changed, no restart | gruen | users still see the old greeting |
| 6.1 | `6.1-konfiguration.yaml` | ConfigMap key `GRUSS` does not exist | rot | describe: CreateContainerConfigError |
| 6.2 | `6.2-speicher.yaml` | 512 MiB heap in 512 MiB limit | rot | describe: Last State OOMKilled |
| 6.3 | `6.3-bereitschaft.yaml` | readiness path does not exist | rot | describe: Readiness probe failed |
| 7.1 | `7.1-platz.yaml` | requests larger than any node | rot (timeout) | events: FailedScheduling |
| 7.2 | `7.2-wartung.yaml` | PDB minAvailable equals replicas | gruen | `drain` blocked (local) |
| 7.3 | `7.3-ort.yaml` | nodeSelector on a label no node has | rot (timeout) | events: node affinity |

6.1 to 6.3 are today's releases a to c, renamed. 5.1 to 5.5 are today's `stoerung.sh` faults, rewritten as YAML (5.3 and 5.5 changed so they work with `apply` only). Lab 7 part 2 (cordon) stays a command: it is cluster scoped and local only.

Phase 2 (next run): Lab 3 cases become `3.1` to `3.5` with the same rhythm, Lab 2 gets checkpoints `basis/2a`, `2b`, `2c`, Lab 4 deploys through the pipeline from the start.

## Logs in every part, not only in Lab 5

Logs are a required piece of evidence in every fault round, not an optional extra.

- Step 3 of the rhythm always has three views: pipeline evidence (`out/pipeline/<zeit>/`), `kubectl logs` / `--previous`, and on GKE a saved Logs Explorer query
- The Abgabe line per fault gets a column **Logs Explorer**: the query that showed the cause (or the note "keine Logzeile, Befund aus Events" when the app never started; that is a finding too)
- `basis.sh` deploys `verkehr` (from Lab 5) in every lab from Lab 6 on, so there is always a user view in the logs: `GET / -> 200` or the error
- hallo-app logs at startup where its configuration came from (ConfigMap key, Secret source: env or file), never the value. One line, so participants can prove in the logs which config a pod really got (ties to 5.5 and the Secret Manager part below)
- README per lab: one Logs Explorer query per fault in the solutions, written for the participant's namespace (`resource.labels.namespace_name="workshop-personNN"`)
- Slides: the Spickzettel gets a fourth column "Logs Explorer"

## Secret Manager: the secret comes from Google, not from kubectl

Google's managed "key vault" is **Secret Manager**. On GKE it reaches pods through the **Secret Manager add-on** (managed CSI driver, provider `gke`) with Workload Identity Federation. This replaces `kubectl create secret ... --from-literal` for the cloud labs and turns Workload Identity (3.3) from theory into practice.

Verified against the [Secret Manager add-on docs](https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component):

- GKE 1.27.14-gke.1042001 or later, Linux nodes; on Standard clusters Workload Identity Federation is required
- Our cluster already has it: `--workload-pool=PROJECT_ID.svc.id.goog`, node pool `kurs` with `--workload-metadata=GKE_METADATA` (trainer/RUNBOOK.md). Check before building: `gcloud container clusters describe workshop --location europe-west3-b --format="value(workloadIdentityConfig.workloadPool)"`
- Enable: `gcloud container clusters update workshop --location=europe-west3-b --enable-secret-manager --enable-secret-manager-rotation`. The docs do not say whether this disturbs the control plane. Our cluster is zonal, so run it **outside course hours** (before 16:00 SGT or in the lunch break) and check `kubectl get nodes` afterwards
- Pods on Standard need `nodeSelector: iam.gke.io/gke-metadata-server-enabled: "true"`
- Access: `roles/secretmanager.secretAccessor` on the secret for `principal://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/PROJECT_ID.svc.id.goog/subject/ns/NAMESPACE/sa/KSA_NAME`
- Not supported by the add-on: open source "Sync as Kubernetes Secret". Mount as file only

### Trainer setup (`trainer/secret-manager.sh`, idempotent, trainer only)

1. Enable the API `secretmanager.googleapis.com`
2. Enable the add-on (command above), wait until the cluster is `RUNNING`
3. Per participant: secret `hallo-db-personNN` with a per-person value, IAM binding `secretAccessor` for `ns/workshop-personNN/sa/hallo`
4. Extend the Role `workshop-entwickler` in `trainer/rbac.yaml`: `serviceaccounts` (get, list, create, update, patch, delete) and `secretproviderclasses.secrets-store.csi.x-k8s.io` (same verbs). No IAM rights for participants; they never touch IAM
5. Same for `workshop-trainer`, then test the whole part there
6. Cleanup in `docs/11-nach-dem-kurs-aufraeumen.md`: delete the secrets and bindings, disable the add-on

### Participant part (Lab 6, new Etappe D, about 20 minutes, GKE only)

Through the pipeline like everything else:

- `basis/` gets a variant `basis-secretmanager/` (or `basis.sh lab06 D`): `ServiceAccount hallo`, `SecretProviderClass hallo-db` (`resourceName: projects/lookbeyond-gke-workshop/secrets/hallo-db-personNN/versions/latest`, `path: DB_PASSWORT`), Deployment with `serviceAccountName: hallo`, the nodeSelector, a CSI volume (`driver: secrets-store-gke.csi.k8s.io`, read only) at `/var/secrets`
- hallo-app must read the password from the file. Prefer configuration over code: Spring Boot `spring.config.import=optional:configtree:/var/secrets/` via env, if the app reads `DB_PASSWORT` as a Spring property. Check the source; change the app only if needed, and rebuild the image tag once for everyone
- The startup log line shows `DB_PASSWORT: aus Datei /var/secrets` (never the value). That line is the checkpoint, found with `kubectl logs` and in the Logs Explorer
- `basis.sh` renders `personNN` from `WORKSHOP_NAMESPACE`

Faults, numbered like the rest:

| Nr | File | What breaks | Pipeline | Where it shows |
| --- | --- | --- | --- | --- |
| 6.4 | `6.4-tresor-name.yaml` | SecretProviderClass points at a secret that does not exist | rot (pod stays ContainerCreating) | events: FailedMount, NotFound |
| 6.5 | `6.5-identitaet.yaml` | Deployment without `serviceAccountName` (default SA has no access) | rot | events: FailedMount, PermissionDenied |
| 6.6 | `6.6-fremder-tresor.yaml` | points at another person's secret | rot | events: PermissionDenied; teaches that IAM is per namespace and SA |

Extra: add a new secret version in the console, wait for rotation (default interval, check the docs value), show the file changed in the pod but the app still uses the old value until restart (same lesson as 5.5).

Without cloud: not possible on minikube. Keep the Kubernetes Secret path there and say so in the README.

Slides to follow (done separately): 3.3 Workload Identity gets a "Lokal ausprobieren" strip with the real SecretProviderClass, Lab 6 gets an Etappe D slide, 6.4 to 6.6 join the Spickzettel.

## Lab 5 short version as the 3.2 exercise (today)

Decided on 25 Nov: Lab 5 replaces the 3.2 challenge ("Logs und Dashboards erkunden") on Day 3.

Why: the customer's own example is "Pod startet ständig neu", and since Lab 3 was skipped nobody practised repeated restarts by hand. Lab 5 also teaches the core of 3.2 better than the old challenge: a pod can be green while users get errors, so you need three views (user = `verkehr` logs, server = `hallo` logs, Kubernetes = events), and a missing log line is a finding.

Timing in 3.2 (09:30 to 10:25 German time, 16:30 to 17:25 SGT):

| Time | What |
| --- | --- |
| 09:30 to 09:50 | Talk: logs, Logs Explorer, metrics (unchanged) |
| 09:50 to 10:20 | **Lab 5 short, 30 min, in pairs:** `start`, fault 5.1 (restarts, `stoerung.sh 1`), fault 5.4 (flood of errors, `stoerung.sh 4`) |
| 10:20 to 10:25 | One check-in (3.2 1/1, logs of a replaced pod). The second check-in moved to the appendix |

Faults 5.2, 5.3 and 5.5 become an Extra for teams that finish Lab 6 early.

What Claude Code does for this:

- [ ] `lab05-stoerungen/README.md`: a short section **"Kurzfassung (30 Minuten, Tag 3)"** at the top of Kern: `start`, `pruefen`, `kubectl logs deployment/verkehr -f` in a second terminal, then `stoerung.sh 1` and `stoerung.sh 4` (explicit numbers, not `zufall`), repair with kubectl, `pruefen`, `aufloesen`, `start` between rounds. Abgabe: one line per fault, one of the two backed by a Logs Explorer query. Keep the full 60-minute version below it unchanged. Practice branch without the solutions
- [ ] Keep the interface of `stoerung.sh` stable today (`start`, `1` to `5`, `zufall`, `pruefen`, `aufloesen`): the slide "Lab 5 kurz" shows exactly these calls. The YAML conversion to 5.1 to 5.5 (Phase 1b) must keep `stoerung.sh` working as a wrapper, or wait until after the course
- [ ] Capacity check on GKE: 15 people run `start` at once (hallo 2 pods plus `verkehr`). Run `start` in `workshop-trainer` and two test namespaces in parallel and note in `docs/07-teststatus.md` how long it took until `pruefen` was green and whether pods were Pending
- [ ] Faults 1 and 4 on GKE: confirm each shows in the Logs Explorer within about a minute (fault 1: `Liveness probe failed` in `log_id("events")`, fault 4: `textPayload:"FEHLER"` for container `hallo` and `-> 500` in `verkehr`). Note that the ERROR lines arrive with severity INFO
- [ ] Lab 5 runs after Lab 4 and before Lab 6. `start` deletes the Lab 4 `hallo`; Lab 6 Etappe A (and `basis.sh lab06`) must work from the state Lab 5 leaves behind. Test that order once

## Scope and order

| Phase | When | What |
| --- | --- | --- |
| 0 | Today, first, done by 15:00 SGT | Renumbering (section above), own commit |
| 1 | Today, done by 15:30 SGT, tested on GKE in `workshop-trainer` | `basis.sh` for lab05 and lab06, pipeline accepts manifests without Deployment, `verlauf.txt` |
| 1a | Today, before 16:00 SGT | Lab 5 short version for 3.2 (section above): README Kurzfassung, capacity and Logs Explorer check on GKE |
| 1b | Today if time allows | Lab 5 faults as YAML 5.1 to 5.5, smoke test |
| 1c | Today, before the lunch break (19:00 SGT) | Secret Manager: trainer setup, Lab 6 Etappe D with 6.4 to 6.6, startup log line in hallo-app, tested in `workshop-trainer` |
| 2 | After the course | Lab 7 faults 7.1 to 7.3, Lab 2/3/4 conversion, rollback to last green state, slides for all days |

Phase 1 must not break what the Day 3 slides show: `bash scripts/pipeline.sh MANIFEST`, stage names, GRUEN/ROT, exit codes, `out/pipeline/<zeit>/` evidence. List every renamed path in your summary so the slides can follow (Lab 6 B slide, Spickzettel, Demo 3.4c).

## Done when

- [ ] `basis.sh` resets a namespace from any state of Lab 6 and Lab 5 to green in under 3 minutes, on minikube and GKE
- [ ] Each fault: red or green exactly as in the table, cause visible where the table says, fixed copy goes green
- [ ] Hand-made objects in the namespace are reported, not deleted
- [ ] Every fault in the solutions has a Logs Explorer query or the note why there is no log line
- [ ] Secret Manager: add-on on, one secret and binding per participant, Etappe D green in `workshop-trainer`, 6.4 to 6.6 red with the event the table names, startup log line visible in the Logs Explorer
- [ ] `can-i create secretproviderclasses.secrets-store.csi.x-k8s.io` is yes for a participant account, `can-i` on another namespace stays no
- [ ] READMEs (main and practice) use the rhythm, practice without solutions
- [ ] shellcheck clean, Bash 3.2, ASCII, in `validate.sh`
- [ ] Results in `docs/07-teststatus.md`, commit on main separate from other changes
