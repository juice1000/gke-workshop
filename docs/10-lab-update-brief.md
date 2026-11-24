# Lab update brief: Kern, Gut zu wissen, Extra

Brief for Claude Code working in `gke-workshop`. Read `AGENTS.md`, `README.md` and `docs/06-labs-und-trainer.md` first. Everything in `AGENTS.md` still applies.

## 1. Why this change

Feedback after day 1 (23.11.2026):

- The theory was too detailed and jumpy for beginners. Example: how the control plane components work together was worth one sentence, not a walkthrough.
- Participants want more hands-on time and room to experiment.
- The trainer is new to Kubernetes himself. He needs the material to explain *how things work* in simple terms, so he can answer questions on the spot.

Decision: every topic gets an explicit depth. The labs must show it.

Source pages in Notion (read them, they are the reference):

- Strategy: https://app.notion.com/p/4217a614759581779548cef104a65559
- Participant FAQ from day 1: https://app.notion.com/p/4217a614759581e6a54eed256812c1ae
- Trainer learning journal with the 61 live questions: https://app.notion.com/p/41f7a6147595812da43afa50cbd9be37

## 2. The three levels

| Level | Meaning | In the lab README | Checked by `pruefen.py` |
| --- | --- | --- | --- |
| **Kern** | Needed for the next lab or for running an app on GKE. Everyone must finish it | Section `## Kern`, numbered steps | Yes |
| **Gut zu wissen** | Helps understanding, nobody acts on it | One line, starting with `**Gut zu wissen:**` | No |
| **Extra** | For fast or curious people. Safe to skip | Section `## Extra zum Ausprobieren` at the end, files in `labNN/extra/` | No |

The test for Kern: will participants type or click it today or tomorrow, or meet it in their own project in the first weeks? If not, it is Gut zu wissen (one sentence) or Extra.

The five goals every Kern item must serve, by the end of day 3:

1. Deploy an app to GKE from Artifact Registry, with configuration from outside the image
2. Tell healthy from broken and find the cause (status, describe, logs, events, Logs Explorer)
3. Roll out a new version and roll it back
4. Explain who runs what on GKE and who may do what (IAM to get in, RBAC inside the namespace)
5. Always know which cluster and namespace you are in

## 3. The two branches

| Branch | Audience | What it contains |
| --- | --- | --- |
| `main` | Trainer, and participants after the course | Exercises **plus** solutions **plus** background: how it works, why, and what to say when someone asks |
| `practice` | Participants during the course (`git clone -b practice`) | The same exercises, Kern and Extra structure, short explanations, **no solutions** |

Rules:

- Do the work on `main` first. Port the participant-facing parts to `practice` the way the git history already does it (commits named "Record main ... without applying them"). Never merge `main` into `practice`: solutions would leak.
- Participants already cloned `practice` on day 1. Keep folder names, file names, manifest names, labels and checkpoint stage names (`dns`, `lab02`, `betrieb`, `gke`, `abschluss`) stable so `git pull` works. Add and move text, do not rename.
- `main` has uncommitted changes in `lab02-hallo-app/README.md` and `lab02-hallo-app/k8s/service.yaml`. Look at them first, do not overwrite them.

## 4. The main job: explain how it works, briefly

`main` needs much more background, written so a beginner trainer can read it once and explain it. But too much text does the opposite. The rule is **short text, clear relations, one picture**.

### Per lab README on `main`

```text
# Lab N: Titel

**Ziel:** ein Satz. **Voraussetzung:** ein Satz.

## Das Minimum              <- 3 to 5 bullets, the Kern of the lab
## Das Bild dazu            <- one ASCII diagram, at most about 15 lines
## Kern
### 1. Schritt
Was passiert: 1 to 3 sentences
```bash
befehl            # comment in ASCII, what it does
```
Erwartet: what the output should look like
> **Hintergrund:** at most 3 sentences on how it works   <- main only
**Gut zu wissen:** one line                              <- optional
## Checkpoint
## Extra zum Ausprobieren
### Extra 1: Titel
## Für den Trainer                                        <- main only
```

`## Für den Trainer` (main only, end of the README):

- **So erklärt ihr es:** the one picture or analogy to use, in 2 to 4 bullets
- **Häufige Fragen:** 3 to 6 questions from the day 1 FAQ that belong to this lab, each with a one or two sentence answer
- **Nur nennen, nicht erklären:** topics that are Gut zu wissen, so the trainer knows where to stop
- **Wenn es hakt:** the 2 or 3 most likely failures with the fix

### Length budget

- Kern part of a README: readable in about 5 minutes
- `Was passiert`: at most 3 sentences per step
- `Hintergrund`: at most 3 sentences per step, and not on every step. Only where a participant is likely to ask "why"
- One diagram per lab or per larger section. No diagram that only repeats the text
- No mechanism tours. Example: the scheduler is "picks a node based on requests", not how it scores nodes

### Writing style

- Participant text in German, short sentences, active voice, "ihr"
- Name the relation, not the definition: "Der Service findet Pods über das Label app: hallo", not "Ein Service ist eine Abstraktion ..."
- Every explanation ends in something visible: "Woran ihr es seht: ..."
- No em dashes, no emojis. Code comments in ASCII (AGENTS.md)

### Diagram style

Plain ASCII inside ```` ```text ```` blocks. Characters `+ - | > < v ^` only, no box-drawing Unicode, so it renders the same in terminals and on GitHub. Width at most about 70 characters. Reuse these shapes so the labs look like one course:

**Image path (Lab 2, Lab 4)**

```text
Dockerfile --docker build--> Image hallo-app:2.0
                                 |
          lokal: minikube image load      Cloud: docker push
                 v                             v
             minikube                  Artifact Registry
                                               |
                                               v
                                     GKE-Node laedt das Image
```

**Who finds whom (Lab 2)**

```text
Deployment hallo
   |  haelt 2 Replikas
   v
ReplicaSet ---> Pod (app: hallo)   Pod (app: hallo)
                   ^                  ^
                   +---- Service -----+
                   selector: app: hallo
```

**Request path (Lab 2, Lab 4)**

```text
curl 127.0.0.1:8080 -> port-forward -> Service :80 -> Pod :8080
                         (Tunnel nur fuer euch, nicht fuer Nutzer)
```

**Configuration (Lab 2 betrieb)**

```text
ConfigMap GREETING --beim Containerstart--> Umgebungsvariable
      ^ geaendert                                  |
      |                         alter Wert bis rollout restart
```

**Probes (Lab 2 betrieb, Lab 3 Fall 5)**

```text
Liveness  faellt dauerhaft aus  -> Container wird neu gestartet
Readiness faellt aus            -> Pod bleibt Running, READY 0/1,
                                   bekommt keinen Traffic
```

**Status to cause (Lab 3)**

```text
kubectl get pods
  Pending                    -> describe: Requests, FailedScheduling
  ErrImagePull/BackOff       -> describe: Name, Tag, Registry-Zugriff
  CreateContainerConfigError -> describe: ConfigMap/Secret fehlt
  CrashLoopBackOff           -> logs --previous
  Running, 0/1               -> describe: Readiness-Events
```

**Contexts (Lab 0, Lab 4)**

```text
kubeconfig
  +-- minikube                              -> lokaler Cluster
  +-- gke_lookbeyond-gke-workshop_..._workshop -> GKE
        (Kontext = Cluster + Benutzer + Standard-Namespace)
```

**Access (Lab 5 Etappe C)**

```text
Google-Konto --IAM--> darf zum Cluster --RBAC--> darf im Namespace
                      (get-credentials)          workshop-personNN
```

## 5. Changes per lab

Priority: day 2 labs first (Lab 2 `betrieb/`, Lab 3, Lab 4), then day 3 (Lab 5, Lab 6), then day 1 for the next run (Lab 0, Lab 1, Lab 2 `k8s/`).

| Lab | Kern | Gut zu wissen | Extra zum Ausprobieren |
| --- | --- | --- | --- |
| 0 Setup | Tools, cluster start, namespace in the context, dashboard tour | `AlreadyExists` is fine, minikube runs one node by default | Multi-node minikube (`--nodes=3`), `minikube ssh` |
| 1 kubectl | Steps marked "täglich" and "bei Störungen" | Steps marked "gelegentlich" | "Selbst herausfinden" and Bonus. Note: Lab 1 was skipped live and is now self-study. Say so at the top |
| 2 `k8s/` | Build, load, apply, port-forward, delete a pod, scale | `imagePullPolicy`, `HOSTNAME` via `fieldRef` | Run the image without Kubernetes (current 1.2), standalone pod vs deployment |
| 2 `betrieb/` | ConfigMap as env var plus `rollout restart`, Secret is only base64, break readiness and watch, rolling update with `rollout status` and `undo` | YAML spaces vs tabs, startup probe, CPU limit throttles, `set image` is for tests | Config as volume, `envFrom`, `dry-run` and `diff`, maxSurge/maxUnavailable arithmetic, `rollout history` and change-cause, JVM heap with `MaxRAMPercentage`, HPA (`extra/hpa.yaml`) |
| 3 Fehlersuche | The five cases by hand with get, describe, logs, logs --previous, events | Not every command returns something in every case | `diagnose.sh` moves to `lab03-defekt/extra/` with its own short section, OOMKilled with a too small memory limit, Fall 5 with Service and EndpointSlices (current bonus) |
| 4 GKE | Connect, push, render and apply, compare CLI and console, switch context | Why `--platform linux/amd64`, what `render.py` does, DNS endpoint | `/fehler` plus Logs Explorer (current step 6, prepares day 3), `kubectl auth can-i` in own namespace and `kube-system`, spreading replicas with `topologySpreadConstraints` on 3 nodes (`extra/spread.yaml`) |
| 5 Abschluss | Etappe A and B, rollback, Etappe C as "Forbidden, check with can-i" | IAM and RBAC add up | Senior incident variants (see Notion day 3 plan) |
| 6 Betrieb | For the ops colleagues: read the cluster, cordon and drain | A PDB can block a drain | Alarm, upgrades, maintenance windows |

Notes:

- Slides for day 2 already treat `diagnose.sh` as Extra and Lab 3 Kern as the five cases by hand. Keep the README consistent with that.
- Every Extra must be independent, safe in the own namespace and cleaned up in its own last step. No public load balancers, no cluster changes.
- New Extra files: `lab02-hallo-app/extra/hpa.yaml`, `lab04-gke/extra/spread.yaml`, `lab03-defekt/extra/diagnose.sh`. Keep them minimal and commented.
- Fold in the day 1 FAQ where it fits, as `Häufige Fragen` on `main` and as one `Gut zu wissen` line on `practice`. Examples: context is not a permission, namespace is not a node, names may differ but selector and labels must match, kubectl never carries user traffic, HPA scales pods and never nodes, data in a container is gone with the pod.

## 6. Scripts

- `pruefen.py` checks Kern only. No new checks for Extras. A green checkpoint means "done" for everyone
- Keep Bash 3.2 and Python 3.9 compatibility, explicit `--context` and `--namespace` everywhere
- `bash scripts/validate.sh` must pass. Run `bash scripts/dry-run.sh` if the local setup allows it, it uses its own minikube profile
- If you add files, check whether `scripts/check-files.py` or `scripts/integration.py` need to know them
- Do not claim GKE validation from a local run. Update `docs/07-teststatus.md` with what was actually tested

## 7. Do not

- Create clusters, node pools, IAM bindings or public load balancers
- Add Helm, Terraform, GitOps or Kustomize to the Kern
- Put solutions on `practice`
- Rename folders, files, labels or checkpoint stages
- Write long theory sections. If a paragraph needs more than 3 sentences, it is probably Extra or belongs in Notion

## 8. Done when

- [ ] Every lab README on `main` has `Das Minimum`, `Das Bild dazu`, `Kern`, `Checkpoint`, `Extra zum Ausprobieren`, `Für den Trainer`
- [ ] Every lab README on `practice` has the same structure without solutions and without `Für den Trainer`
- [ ] Kern steps each have `Was passiert` and `Erwartet`. `Hintergrund` only where a "why" is likely
- [ ] Lab 3 `diagnose.sh` lives in `extra/` and is described as Extra
- [ ] `validate.sh` passes on both branches
- [ ] `docs/06-labs-und-trainer.md` records the Kern/Extra split and any difference to Notion
- [ ] `docs/07-teststatus.md` updated
- [ ] No em dashes, no emojis, participant text German
