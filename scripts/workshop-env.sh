#!/usr/bin/env bash
# Aus dem Repository-Hauptordner mit source scripts/workshop-env.sh laden.
# Setzt nur die Terminalumgebung und definiert Kontextwechsel, startet keine Cloud-Ressourcen.
if [ ! -f scripts/workshop-env.sh ] || [ ! -f lab02-hallo-app/pom.xml ]; then
  printf 'Zuerst in den Hauptordner von gke-workshop wechseln.\n' >&2
  return 1
fi

WORKSHOP_ROOT="$(pwd -P)"
export WORKSHOP_ROOT
export MINIKUBE_HOME="$WORKSHOP_ROOT/.cache/minikube-home"
export KUBECONFIG="$WORKSHOP_ROOT/.cache/workshop.kubeconfig"
export CLOUDSDK_ACTIVE_CONFIG_NAME=gke-workshop
if [ -f "$WORKSHOP_ROOT/.cache/workshop-cloud.env" ]; then
  # shellcheck source=/dev/null
  . "$WORKSHOP_ROOT/.cache/workshop-cloud.env"
fi
case ":$PATH:" in
  *":$WORKSHOP_ROOT/.cache/bin:"*) ;;
  *) export PATH="$WORKSHOP_ROOT/.cache/bin:$PATH" ;;
esac
export WORKSHOP_CONTEXT=minikube
export WORKSHOP_NAMESPACE=workshop
if [ -s "$KUBECONFIG" ]; then
  if WORKSHOP_CURRENT_CONTEXT="$(kubectl config current-context 2>/dev/null)"; then
    export WORKSHOP_CONTEXT="$WORKSHOP_CURRENT_CONTEXT"
    WORKSHOP_CURRENT_NAMESPACE="$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)"
    export WORKSHOP_NAMESPACE="${WORKSHOP_CURRENT_NAMESPACE:-default}"
  fi
  unset WORKSHOP_CURRENT_CONTEXT WORKSHOP_CURRENT_NAMESPACE
fi

workshop_local() {
  kubectl config use-context minikube || return
  kubectl config set-context minikube --namespace=workshop || return
  export WORKSHOP_CONTEXT=minikube
  export WORKSHOP_NAMESPACE=workshop
}

workshop_gke() {
  if [ -z "${GKE_CONTEXT:-}" ]; then
    printf 'Cloud-Metadaten fehlen: .cache/workshop-cloud.env einrichten.\n' >&2
    return 1
  fi
  kubectl config use-context "$GKE_CONTEXT" || return
  kubectl config set-context "$GKE_CONTEXT" --namespace="${1:-${GKE_NAMESPACE:-workshop-trainer}}" || return
  export WORKSHOP_CONTEXT="$GKE_CONTEXT"
  export WORKSHOP_NAMESPACE="${1:-${GKE_NAMESPACE:-workshop-trainer}}"
}

printf 'Workshop-Umgebung geladen. kubeconfig: %s\n' "$KUBECONFIG"
printf 'Kontext: %s, Namespace: %s. Wechsel: workshop_local / workshop_gke\n' "$WORKSHOP_CONTEXT" "$WORKSHOP_NAMESPACE"
