#!/usr/bin/env bash
# Demo 2.2c (Extra): ConfigMap oder Secret?
# Folie: Tag 2, Anhang, Extra-Aufloesung "ConfigMap oder Secret?"
# Zeigt: ein Secret ist nur base64-kodiert. Wer es lesen darf, sieht den Wert.
# Voraussetzung: demos/tag2/00-vorbereiten/demo.sh. Dauer: etwa 2 Minuten.
# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib.sh"
title 2.2c "ConfigMap oder Secret? (Extra)" "Anhang, Extra-Aufloesung ConfigMap oder Secret?"
require_betrieb

say "So steht das Secret im Cluster:"
run "kubectl get secret hallo-secret -o yaml | grep DB_PASSWORT"
say "base64 ist keine Verschluesselung:"
run "kubectl get secret hallo-secret -o jsonpath='{.data.DB_PASSWORT}' | base64 -d; echo"
say "Entscheidend ist, wer Secrets lesen darf. Lokal seid ihr Admin, auf GKE regelt das RBAC (Tag 3)."
run "kubectl auth can-i get secrets"
finish
