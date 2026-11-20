# GKE workshop

Three-day German introduction for developers. Read `README.md` and `docs/06-labs-und-trainer.md` before changing labs. Context and scope are in `docs/01-kontext.md` through `docs/05-gespraechsnotizen.md`.

- Participant instructions are German. Code comments use ASCII. No em dashes.
- Keep the same small Spring Boot application throughout the course.
- Lab 3 faults and Lab 5 TODOs are intentional. Solutions live alongside exercises.
- Use current Kubernetes APIs. No Terraform, Helm or GitOps in the core labs.
- Scripts must work with Bash 3.2 and Python 3.9+. Runtime scripts use explicit context and namespace. Never silently use a current cloud context.
- `bash scripts/validate.sh` runs static checks. `bash scripts/dry-run.sh` creates its own local minikube profile, checks healthy and broken cases, and deletes only its own profile.
- Do not claim GKE validation from a local run. Track the actual test coverage in `docs/07-teststatus.md`.
- Cloud resources and participant access are prepared separately by the trainer. No automatic cluster creation or public load balancers.
- Notion chapters are source material, linked in `docs/06-labs-und-trainer.md`. Record any implementation differences there.
