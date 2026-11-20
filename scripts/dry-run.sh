#!/usr/bin/env bash
# Baut einen eigenen minikube-Cluster. Bestehende Cluster bleiben unberuehrt.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MINIKUBE_BIN="${MINIKUBE_BIN:-minikube}"
PROFILE="gke-lab-test-$(date +%s)-$$"
export WORKSHOP_CONTEXT="$PROFILE"
export WORKSHOP_NAMESPACE=workshop-test
# Separate kubeconfig: kein Wechsel des persoenlichen aktuellen Kontexts.
mkdir -p "$ROOT/.cache"
TEST_DIRECTORY="$(mktemp -d "$ROOT/.cache/dry-run.XXXXXX")"
export KUBECONFIG="$TEST_DIRECTORY/config"

cleanup() {
  local status=$?
  trap - EXIT
  if [ "$status" -ne 0 ]; then
    "$MINIKUBE_BIN" -p "$PROFILE" logs --file="$TEST_DIRECTORY/minikube.log" >/dev/null 2>&1 || true
    printf 'FEHLER: Probelauf abgebrochen. Diagnose: %s\n' "$TEST_DIRECTORY" >&2
    kubectl --context "$PROFILE" -n workshop-test get pods -o wide 2>/dev/null || true
    kubectl --context "$PROFILE" -n workshop-test logs -l app=hallo --prefix --tail=30 2>/dev/null || true
  fi
  "$MINIKUBE_BIN" delete -p "$PROFILE" || true
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

cd "$ROOT"
docker build --build-arg APP_VERSION=1.0 -t hallo-app:1.0 lab02-hallo-app
docker build --build-arg APP_VERSION=2.0 -t hallo-app:2.0 lab02-hallo-app
"$MINIKUBE_BIN" start -p "$PROFILE" --driver=docker --cpus=2 --memory=4096 --nodes=1 \
  --kubernetes-version=v1.35.0
"$MINIKUBE_BIN" -p "$PROFILE" image load hallo-app:1.0 hallo-app:2.0
# Zum Server passende CLI nutzen, ohne die persoenliche kubectl-Installation zu aendern.
"$MINIKUBE_BIN" -p "$PROFILE" kubectl -- version --client
mkdir -p "$TEST_DIRECTORY/bin"
printf '#!/usr/bin/env bash\nexec "%s" -p "%s" kubectl -- "$@"\n' \
  "$(command -v "$MINIKUBE_BIN")" "$PROFILE" > "$TEST_DIRECTORY/bin/kubectl"
chmod +x "$TEST_DIRECTORY/bin/kubectl"
export PATH="$TEST_DIRECTORY/bin:$PATH"
python3 scripts/integration.py
