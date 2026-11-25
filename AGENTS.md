# GKE workshop

Three-day German introduction for developers. Branch `main` is for participants continuing on their own GKE project after the course; `workshop-master` holds the course as taught, with the shared cluster, trainer setup and briefs. Read `README.md` and `docs/06-labs-und-trainer.md` before changing labs. Context and scope are in `docs/01-kontext.md` through `docs/05-gespraechsnotizen.md`.

- Participant instructions are German. Code comments use ASCII. No em dashes.
- Keep the same small Spring Boot application throughout the course.
- Lab 3 faults and Lab 6 TODOs are intentional. Solutions live alongside exercises.
- Use current Kubernetes APIs. No Terraform, Helm or GitOps in the core labs.
- Scripts must work with Bash 3.2 and Python 3.9+. Participant scripts use the current kubectl context and namespace and print both before changing anything. Keep them short enough to read on one screen.
- Manifests start with `---` and carry one placeholder, `WORKSHOP_IMAGE` (Etappe D also `WORKSHOP_PROJECT`). Participants apply them with `sed ... | kubectl apply -f -`. No render step, no working copies.
- `bash scripts/validate.sh` runs static checks. `bash scripts/dry-run.sh` creates its own local minikube profile, checks healthy and broken cases, and deletes only its own profile.
- Do not claim GKE validation from a local run. Track the actual test coverage in `docs/07-teststatus.md`.
- Each participant creates their own project and cluster by hand, following `SELBST-WEITERMACHEN.md`. No script creates a cluster. Public access is a `LoadBalancer` Service in the participant's own project.
- Notion chapters are source material, linked in `docs/06-labs-und-trainer.md`. Record any implementation differences there.
