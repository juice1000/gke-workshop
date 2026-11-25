#!/usr/bin/env bash
# Legt fuer jede Google-Konto-Adresse einen Namespace, die Namespace-Rolle, das
# Kontingent (trainer/kontingent.yaml) und die Projekt-IAM-Rollen an. Nur fuer den Trainer.
#
# Aufruf aus dem Repository-Hauptordner nach source scripts/workshop-env.sh:
#   bash trainer/teilnehmer-anlegen.sh KONTOLISTE            # nur rendern und anzeigen
#   bash trainer/teilnehmer-anlegen.sh KONTOLISTE --apply    # zusaetzlich anwenden
#
# KONTOLISTE: eine Adresse pro Zeile, Reihenfolge ergibt die Nummer (01, 02, ...).
# Leere Zeilen und Zeilen mit # werden uebersprungen.
set -euo pipefail

if [ $# -lt 1 ] || [ ! -f "$1" ]; then
  printf 'Aufruf: bash trainer/teilnehmer-anlegen.sh KONTOLISTE [--apply]\n' >&2
  exit 2
fi
LISTE="$1"
APPLY="${2:-}"

for var in PROJECT_ID REGION REPOSITORY GKE_CONTEXT; do
  if [ -z "${!var:-}" ]; then
    printf 'Variable %s fehlt. Zuerst: source scripts/workshop-env.sh\n' "$var" >&2
    exit 2
  fi
done

OUT="out/trainer"
mkdir -p "$OUT"
TABELLE="$OUT/teilnehmer.tsv"
printf 'nummer\tnamespace\tkonto\n' > "$TABELLE"

nr=0
while IFS= read -r zeile || [ -n "$zeile" ]; do
  konto="$(printf '%s' "$zeile" | tr -d '[:space:]')"
  case "$konto" in
    ''|'#'*) continue ;;
    *@*.*) ;;
    *) printf 'Keine gueltige Adresse, uebersprungen: %s\n' "$konto" >&2; continue ;;
  esac
  nr=$((nr + 1))
  nn="$(printf '%02d' "$nr")"
  ns="workshop-person${nn}"
  dir="$OUT/person${nn}"
  mkdir -p "$dir"
  sed "s/workshop-person01/${ns}/g" trainer/namespace.yaml > "$dir/namespace.yaml"
  sed -e "s/workshop-person01/${ns}/g" -e "s/TEILNEHMER_KONTO_ERSETZEN/${konto}/g" \
    trainer/rbac.yaml > "$dir/rbac.yaml"
  sed "s/workshop-person01/${ns}/g" trainer/kontingent.yaml > "$dir/kontingent.yaml"
  printf '%s\t%s\t%s\n' "$nn" "$ns" "$konto" >> "$TABELLE"

  if [ "$APPLY" != "--apply" ]; then
    printf 'Geplant: %s -> %s\n' "$konto" "$ns"
    continue
  fi

  printf '\n== %s -> %s\n' "$konto" "$ns"
  kubectl --context "$GKE_CONTEXT" apply -f "$dir/namespace.yaml"
  kubectl --context "$GKE_CONTEXT" apply -f "$dir/rbac.yaml"
  kubectl --context "$GKE_CONTEXT" apply -f "$dir/kontingent.yaml"
  # Cluster-Metadaten fuer get-credentials. Gibt keine Rechte an Kubernetes-Objekten.
  gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="user:${konto}" \
    --role=roles/container.clusterViewer --condition=None --quiet >/dev/null
  # Logs Explorer und Monitoring fuer Tag 3. Projektweit lesend, keine Kubernetes-Rechte.
  gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="user:${konto}" \
    --role=roles/logging.viewer --condition=None --quiet >/dev/null
  gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="user:${konto}" \
    --role=roles/monitoring.viewer --condition=None --quiet >/dev/null
  # Alarm-Uebung (Lab 7): eigene Alarmrichtlinien anlegen. Projektweit, deshalb
  # Namensregel "workshop-personNN: ..." und Aufraeumen nach dem Kurs.
  gcloud projects add-iam-policy-binding "$PROJECT_ID" --member="user:${konto}" \
    --role=roles/monitoring.alertPolicyEditor --condition=None --quiet >/dev/null
  # Push in das Uebungsrepository.
  gcloud artifacts repositories add-iam-policy-binding "$REPOSITORY" \
    --location="$REGION" --project="$PROJECT_ID" --member="user:${konto}" \
    --role=roles/artifactregistry.writer --quiet >/dev/null
  printf 'OK: %s\n' "$ns"
done < "$LISTE"

printf '\n%s Konten. Zuordnung fuer die Teilnehmenden: %s\n' "$nr" "$TABELLE"
if [ "$APPLY" != "--apply" ]; then
  printf 'Nichts angewendet. Arbeitskopien in %s lesen, dann mit --apply wiederholen.\n' "$OUT"
fi
