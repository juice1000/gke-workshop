#!/usr/bin/env bash
# Installiert fehlende Workshop-Werkzeuge: kubectl, minikube, gcloud, GKE-Auth-Plugin,
# Git, curl, Python 3. Docker wird nur geprueft, nicht installiert.
# Unterstuetzt: macOS mit Homebrew, Ubuntu/Debian (auch unter WSL2).
# Aufruf aus dem Repository-Hauptordner: bash scripts/setup.sh
set -euo pipefail

hat() { command -v "$1" >/dev/null 2>&1; }
info() { printf '\n== %s\n' "$1"; }

if [ ! -f lab00-check/check.sh ]; then
  printf 'Zuerst in den Hauptordner von gke-workshop wechseln.\n' >&2
  exit 1
fi

os="$(uname -s)"
if [ "$os" = Darwin ]; then
  if ! hat brew; then
    printf 'Homebrew fehlt. Installation: https://brew.sh, danach erneut starten.\n' >&2
    exit 1
  fi
  info 'macOS: fehlende Werkzeuge mit Homebrew installieren'
  hat git || brew install git
  hat kubectl || brew install kubectl
  hat minikube || brew install minikube
  hat python3 || brew install python
  hat gcloud || brew install --cask google-cloud-sdk
  if ! hat gke-gcloud-auth-plugin; then
    gcloud components install gke-gcloud-auth-plugin --quiet
  fi
elif [ -f /etc/debian_version ]; then
  if grep -qi microsoft /proc/version 2>/dev/null; then
    info 'WSL2 erkannt'
    case "$(pwd -P)" in
      /mnt/*) printf 'HINWEIS: Repository liegt unter /mnt. Besser: cd ~ && git clone ... \n' ;;
    esac
  fi
  info 'Ubuntu/Debian: Paketquellen und Grundwerkzeuge (fragt nach dem sudo-Passwort)'
  sudo apt-get update -qq
  sudo apt-get install -y -qq apt-transport-https ca-certificates gnupg curl git python3
  if [ ! -f /etc/apt/sources.list.d/google-cloud-sdk.list ]; then
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | sudo gpg --dearmor --yes -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
      | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
    sudo apt-get update -qq
  fi
  info 'gcloud, GKE-Auth-Plugin und kubectl'
  sudo apt-get install -y -qq google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin kubectl
  if ! hat minikube; then
    info 'minikube'
    arch="$(dpkg --print-architecture)"
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/minikube" "https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-${arch}"
    sudo install "$tmp/minikube" /usr/local/bin/minikube
    rm -rf "$tmp"
  fi
else
  printf 'Nicht unterstuetztes System. Bitte VORBEREITUNG.md von Hand folgen.\n' >&2
  exit 1
fi

info 'Docker'
if ! hat docker; then
  printf 'Docker fehlt. Siehe VORBEREITUNG.md, Abschnitt 3 (Docker Desktop oder Docker Engine).\n'
elif ! docker info >/dev/null 2>&1; then
  printf 'Docker ist installiert, aber nicht erreichbar. Docker starten bzw. WSL-Integration einschalten.\n'
  printf 'Bei "permission denied": sudo usermod -aG docker %s, dann Terminal neu oeffnen.\n' "$(id -un)"
else
  printf 'Docker laeuft.\n'
fi

info 'Pruefung'
bash lab00-check/check.sh
