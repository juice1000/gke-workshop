#!/usr/bin/env bash
# Demo 3.4d: GitHub Actions darf ohne Schluessel nach workshop-trainer ausrollen.
# Nur fuer den Trainer. Mehrfach ausfuehrbar, legt nur Fehlendes an.
#
# Aufruf aus dem Repository-Hauptordner nach source scripts/workshop-env.sh:
#   bash trainer/einrichtung/github-actions.sh
#
# Was entsteht:
#   Workload-Identity-Pool "github" mit OIDC-Provider "github-oidc". Er nimmt nur
#   Tokens aus juice1000/gke-workshop, Branch main, an.
#   Dienstkonto gh-deployer. Rechte: Cluster sehen (wie Teilnehmende), Images in
#   das Repository "workshop" schreiben, RBAC nur in workshop-trainer.
set -euo pipefail

REPO_GH="juice1000/gke-workshop"
SA_NAME="gh-deployer"
NS="workshop-trainer"

for var in PROJECT_ID REPOSITORY GKE_CONTEXT REGION; do
  if [ -z "${!var:-}" ]; then
    printf 'Variable %s fehlt. Zuerst: source scripts/workshop-env.sh\n' "$var" >&2
    exit 2
  fi
done
NR="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
SA="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

printf '== API\n'
gcloud services enable iam.googleapis.com iamcredentials.googleapis.com sts.googleapis.com --project "$PROJECT_ID"

printf '== Pool und Provider\n'
if ! gcloud iam workload-identity-pools describe github --location=global --project "$PROJECT_ID" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create github --location=global --project "$PROJECT_ID" \
    --display-name="GitHub Actions"
fi
if ! gcloud iam workload-identity-pools providers describe github-oidc --location=global \
    --workload-identity-pool=github --project "$PROJECT_ID" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools providers create-oidc github-oidc --location=global \
    --workload-identity-pool=github --project "$PROJECT_ID" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
    --attribute-condition="assertion.repository=='${REPO_GH}' && assertion.ref=='refs/heads/main'"
fi

printf '== Dienstkonto %s\n' "$SA"
if ! gcloud iam service-accounts describe "$SA" --project "$PROJECT_ID" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$SA_NAME" --project "$PROJECT_ID" \
    --display-name="GitHub Actions Deploy-Demo"
fi
gcloud iam service-accounts add-iam-policy-binding "$SA" --project "$PROJECT_ID" \
  --role=roles/iam.workloadIdentityUser \
  --member="principalSet://iam.googleapis.com/projects/${NR}/locations/global/workloadIdentityPools/github/attribute.repository/${REPO_GH}" \
  --condition=None --quiet >/dev/null
gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:${SA}" \
  --role=roles/container.clusterViewer --condition=None --quiet >/dev/null
gcloud artifacts repositories add-iam-policy-binding "$REPOSITORY" --location="$REGION" \
  --project "$PROJECT_ID" --member="serviceAccount:${SA}" \
  --role=roles/artifactregistry.writer --quiet >/dev/null

printf '== RBAC in %s\n' "$NS"
OUT="out/trainer/github"
mkdir -p "$OUT"
sed -e "s/workshop-person01/${NS}/g" -e "s/TEILNEHMER_KONTO_ERSETZEN/${SA}/g" \
  trainer/rbac.yaml > "$OUT/rbac.yaml"
kubectl --context "$GKE_CONTEXT" apply -f "$OUT/rbac.yaml"

printf '\nProvider fuer den Workflow:\n  projects/%s/locations/global/workloadIdentityPools/github/providers/github-oidc\n' "$NR"
printf 'Dienstkonto: %s\n' "$SA"
printf 'Pruefen: kubectl auth can-i create deployments -n workshop-person01 --as=%s  (erwartet: no)\n' "$SA"
