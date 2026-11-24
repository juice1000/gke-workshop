# Brief: CI/CD on Day 3 (pipeline script, merged into Lab 5)

Brief for Claude Code in `gke-workshop`. Read `AGENTS.md`, `lab05-abschluss/README.md`, `scripts/render.py`, `scripts/workshop-env.sh` and `demos/README.md` first. Everything in `AGENTS.md` still applies.

## Why

The trainer decided that CI/CD needs hands-on practice on Day 3, not only the theory in 3.4. The customer builds with TeamCity, keeps artefacts in Artifactory, copies images to Artifact Registry and deploys to GKE. We cannot give participants TeamCity, so we give them **a pipeline as a script** with exactly the stages a TeamCity build configuration would have. They run it themselves in Lab 5.

Lesson the lab must teach, in one sentence: **a pipeline is the same commands you typed by hand, plus a gate (`rollout status` with a timeout) that decides green or red, plus an automatic reaction (collect evidence, roll back).**

## Decisions already made

- Tool-neutral script, no CI service. Optional demo with a real CI tool is not part of this brief.
- Merged into Lab 5. No extra time on Day 3. Etappe A stays manual (participants write the deployment). Etappe B ships the three broken releases **through the pipeline**.
- The Day 3 slides already show the interface below. Keep names, arguments and output words exactly, or list every difference in your summary so the slides can be fixed.

## The script: `scripts/pipeline.sh`

### Interface

```bash
bash scripts/pipeline.sh MANIFEST [--build]
```

- `MANIFEST`: one rendered manifest file or folder, e.g. `out/lab05/starter/` or `out/lab05/releases/release-a.yaml`
- `--build`: optional. Builds and pushes a new image first (see stage 2). Without it the image in the manifest is used as is
- Environment, as in Lab 4 and Lab 5: `WORKSHOP_CONTEXT`, `WORKSHOP_NAMESPACE`, `IMAGE`. Every kubectl call uses `--context "$WORKSHOP_CONTEXT" --namespace "$WORKSHOP_NAMESPACE"`. Never the current context silently (AGENTS.md)
- Optional: `PIPELINE_TIMEOUT` in seconds, default `120`
- Exit code `0` = green, `1` = red (rolled back), `2` = stopped before deploying (wrong input, wrong context, validation failed)

### Stages

Print each stage as a CI log line, German, ASCII only, e.g. `[3/5] Deploy ...` then `OK` or `FEHLER`.

```text
[1/5] Pruefen     context and namespace set and reachable, manifest exists,
                  kubectl apply --dry-run=server -f MANIFEST passes
                  -> on failure: exit 2, nothing deployed
[2/5] Build       only with --build: docker build --platform linux/amd64,
                  tag = ${IMAGE%:*}:2.0-<git short sha>, docker push,
                  use this image for the deploy (write a copy of the manifest
                  under out/pipeline/, never edit the input file)
                  without --build: print "uebersprungen"
[3/5] Deploy      kubectl apply -f MANIFEST (or the copy)
[4/5] Gate        kubectl rollout status deployment/hallo --timeout=${PIPELINE_TIMEOUT}s
                  -> success: stage 5 is skipped, print
                     "Pipeline GRUEN: <image> laeuft in <namespace>", exit 0
[5/5] Rollback    only when the gate fails:
                  a) save evidence to out/pipeline/<YYYYMMDD-HHMMSS>/:
                     pods.txt      kubectl get pods -o wide
                     describe.txt  kubectl describe pod -l app=hallo
                     events.txt    kubectl get events --sort-by=.metadata.creationTimestamp
                     logs.txt      logs of the newest hallo pod, plus --previous if it restarted
                  b) kubectl rollout undo deployment/hallo
                  c) kubectl rollout status deployment/hallo --timeout=300s
                  d) print "Pipeline ROT: Release zurueckgerollt. Belege: out/pipeline/<zeit>/", exit 1
```

### Rules

- Bash 3.2, `set -u`, ASCII comments and output, no em dashes, shellcheck clean, add it to `scripts/validate.sh`
- Deployment name `hallo` and label `app=hallo` as in Lab 5. Fail with exit 2 and a clear German message if the manifest does not contain `kind: Deployment` with name `hallo`
- No cluster creation, no LoadBalancer, no IAM changes. Only objects in the participant's namespace
- Short header comment that maps each stage to a TeamCity build step (Build, Push, Deploy, Gate, Rollback). This is the hook for the customer discussion
- Keep it under about 150 lines. Readable beats clever. The trainer will show it on the projector

## Lab 5 changes (`lab05-abschluss/README.md`, main and practice)

- **Etappe A** unchanged (manual apply). New last step: deploy the starter once through the pipeline, expect green:
  `bash scripts/pipeline.sh out/lab05/starter/`
- **Etappe B** rewritten. Per release:
  1. `bash scripts/pipeline.sh out/lab05/starter/` (green, known good state)
  2. `bash scripts/pipeline.sh out/lab05/releases/release-a.yaml` (expected red, rolled back)
  3. Find the cause from the evidence folder and, on GKE, in the Logs Explorer. Write down: symptom, cause, which evidence file showed it
  4. Fix the release file, run the pipeline again, expect green
  Repeat for b and c. Keep the existing hints and solutions table. Add to the solutions which evidence file shows the cause (A: describe.txt events, B: describe.txt Last State OOMKilled, C: describe.txt Readiness probe failed)
- **Abgabe B**: per release symptom, cause, evidence file, and the exit code of the red and the green run
- Remove the manual `rollout undo` step from Etappe B, the pipeline does it. Mention in one sentence that this is exactly what they did by hand in 2.4
- **Extra zum Ausprobieren**: run the pipeline with `--build` once (new image tag with the commit), then compare the image in `kubectl get deploy hallo -o wide` with the commit (`git log -1 --oneline`)
- "Ohne Cloud" section: the pipeline also runs against minikube with `IMAGE=hallo-app:2.0`; `--build` there needs `minikube image load` instead of push, either support it with a short branch or say it is cloud only
- Timeouts: release B must reach OOMKilled within `PIPELINE_TIMEOUT` (check on GKE, raise the default if needed and tell me the value)

## Demo for the trainer

Add `demos/tag3/3.4c-pipeline/` in the existing demo pattern: run the pipeline once green with the starter, once red with release C, show the evidence folder, show the exit codes. The Day 3 slide "Unsere Pipeline" names `Demo 3.4c`.

## Notion and docs

- Record the change in `docs/06-labs-und-trainer.md` (Lab 5 now uses the pipeline, why) and test results in `docs/07-teststatus.md`. Do not claim GKE validation from a local run
- Notion is updated separately by the trainer

## Done when

- [ ] `scripts/pipeline.sh` exists, shellcheck clean, in `validate.sh`
- [ ] Green run with the starter and red runs with all three releases tested on minikube, evidence files contain the cause, rollback restores the starter
- [ ] Same on GKE in a trainer namespace (if access is available), results in `docs/07-teststatus.md`
- [ ] Lab 5 README updated on main and practice (practice without solutions)
- [ ] Demo 3.4c added to `demos/`
- [ ] Commit on main, separate from other open changes
