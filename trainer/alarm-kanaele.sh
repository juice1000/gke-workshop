#!/usr/bin/env bash
# Lab 5 Abschnitt 5: ein E-Mail-Kanal pro Person fuer die Alarmuebung.
# Nur fuer den Trainer. Mehrfach ausfuehrbar, legt nur Fehlendes an.
#
# Aufruf aus dem Repository-Hauptordner nach source scripts/workshop-env.sh:
#   bash trainer/alarm-kanaele.sh
#
# Liest out/trainer/teilnehmer.tsv (nummer, namespace, konto). Pro Zeile ein
# Kanal "workshop-personNN E-Mail" an das Konto der Person. E-Mail-Kanaele
# brauchen keine Bestaetigung. Teilnehmende lesen Kanaele ueber monitoring.viewer
# und waehlen ihren in der eigenen Richtlinie. Anlegen darf nur der Trainer.
set -euo pipefail

if [ -z "${PROJECT_ID:-}" ]; then
  printf 'Variable PROJECT_ID fehlt. Zuerst: source scripts/workshop-env.sh\n' >&2
  exit 2
fi
LISTE="out/trainer/teilnehmer.tsv"
[ -f "$LISTE" ] || { printf '%s fehlt. Zuerst trainer/teilnehmer-anlegen.sh\n' "$LISTE" >&2; exit 2; }

API="https://monitoring.googleapis.com/v3/projects/${PROJECT_ID}/notificationChannels"
TOKEN="$(gcloud auth print-access-token)"
VORHANDEN="$(curl -s -H "Authorization: Bearer $TOKEN" "$API?pageSize=200" | grep '"displayName"' || true)"

tail -n +2 "$LISTE" | while IFS="$(printf '\t')" read -r nummer ns konto; do
  [ -n "$konto" ] || continue
  name="${ns} E-Mail"
  if printf '%s\n' "$VORHANDEN" | grep -qF "\"$name\""; then
    printf '  da: %s\n' "$name"
    continue
  fi
  antwort="$(curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$API" \
    -d "{\"type\":\"email\",\"displayName\":\"$name\",\"labels\":{\"email_address\":\"$konto\"},\"userLabels\":{\"workshop\":\"person$nummer\"}}")"
  if printf '%s' "$antwort" | grep -q '"name"'; then
    printf '  angelegt: %s\n' "$name"
  else
    printf '  FEHLER bei %s: %s\n' "$name" "$(printf '%s' "$antwort" | tr -d '\n' | cut -c1-200)" >&2
  fi
done

