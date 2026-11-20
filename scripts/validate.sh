#!/usr/bin/env bash
# Statische Pruefung ohne Cluster. Docker laedt den Schema-Pruefer beim ersten Lauf.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
shellcheck lab00-check/check.sh scripts/*.sh
python3 scripts/check-files.py
manifeste=()
while IFS= read -r file; do
  manifeste+=("$file")
done < <(find lab02-hallo-app lab03-defekt lab04-gke lab05-abschluss lab06-betrieb trainer -name '*.yaml' -type f | sort)
docker run --rm -v "$ROOT:/work:ro" -w /work ghcr.io/yannh/kubeconform:v0.7.0 \
  -strict -summary "${manifeste[@]}"
