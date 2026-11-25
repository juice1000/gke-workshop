#!/usr/bin/env bash
# Lab 6 Etappe D: Das Passwort kommt aus Google Secret Manager statt aus kubectl.
# Nur fuer den Trainer. Mehrfach ausfuehrbar, legt nur Fehlendes an.
#
# Aufruf aus dem Repository-Hauptordner nach source scripts/workshop-env.sh:
#   bash trainer/secret-manager.sh                 alle Kurs-Namespaces
#   bash trainer/secret-manager.sh workshop-trainer nur diesen Namespace
#
# Pro Namespace workshop-X: Secret hallo-db-X mit eigenem Wert, Leserecht
# (secretAccessor) nur fuer das Kubernetes-Dienstkonto "hallo" in diesem
# Namespace, und die erweiterte Role workshop-entwickler (ServiceAccounts,
# SecretProviderClasses). Teilnehmende bekommen keine IAM-Rechte.
# Dazu ein Secret hallo-db-fremd ohne Leserecht fuer Stoerung 6.6.
#
# Das Add-on einmal vorher, ausserhalb der Kurszeit:
#   gcloud container clusters update workshop --location=europe-west3-b \
#     --enable-secret-manager --enable-secret-manager-rotation
set -euo pipefail

for var in PROJECT_ID GKE_CONTEXT; do
  if [ -z "${!var:-}" ]; then
    printf 'Variable %s fehlt. Zuerst: source scripts/workshop-env.sh\n' "$var" >&2
    exit 2
  fi
done
NR="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
POOL="${PROJECT_ID}.svc.id.goog"

if [ $# -gt 0 ]; then
  NAMESPACES="$*"
else
  NAMESPACES="$(kubectl --context "$GKE_CONTEXT" get namespaces -l workshop=gke-einfuehrung -o name | sed 's#^namespace/##')"
fi

gcloud services enable secretmanager.googleapis.com --project "$PROJECT_ID"
AN="$(gcloud container clusters describe workshop --location=europe-west3-b --project "$PROJECT_ID" \
  --format='value(secretManagerConfig.enabled)')"
[ "$AN" = True ] || { printf 'Secret-Manager-Add-on ist aus. Erst einschalten (siehe Kopf).\n' >&2; exit 1; }

secret_anlegen() {
  # $1 Name, $2 Wert. Vorhandene Secrets bleiben unveraendert.
  if ! gcloud secrets describe "$1" --project "$PROJECT_ID" >/dev/null 2>&1; then
    printf '%s' "$2" | gcloud secrets create "$1" --project "$PROJECT_ID" \
      --replication-policy=automatic --data-file=- >/dev/null
    printf '  Secret %s angelegt\n' "$1"
  fi
}

secret_anlegen hallo-db-fremd "fremd-$(date +%s)"

# Nur die Role aus rbac.yaml (erstes Dokument), ohne RoleBinding.
ROLE="$(awk '/^---/{exit} {print}' trainer/rbac.yaml)"

for ns in $NAMESPACES; do
  kurz="${ns#workshop-}"
  printf '== %s\n' "$ns"
  secret_anlegen "hallo-db-${kurz}" "uebung-${kurz}-$(date +%s)"
  gcloud secrets add-iam-policy-binding "hallo-db-${kurz}" --project "$PROJECT_ID" \
    --role=roles/secretmanager.secretAccessor \
    --member="principal://iam.googleapis.com/projects/${NR}/locations/global/workloadIdentityPools/${POOL}/subject/ns/${ns}/sa/hallo" \
    --condition=None --quiet >/dev/null
  printf '%s\n' "$ROLE" | sed "s/workshop-person01/${ns}/g" \
    | kubectl --context "$GKE_CONTEXT" apply -f - >/dev/null
  printf '  OK: Secret, Leserecht fuer ns/%s/sa/hallo, Role\n' "$ns"
done
