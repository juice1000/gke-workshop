# Vorbereitung für Teilnehmende

Bitte vor dem ersten Workshop-Tag erledigen. Dauer: etwa 45 Minuten, davon viel Wartezeit für Downloads. Wenn etwas nicht klappt, schickt uns die Fehlermeldung vorab. Das spart am ersten Morgen Zeit für alle.

## 1. Google-Konto

Ab Tag 2 arbeitet ihr in unserem Google-Cloud-Projekt. Dafür braucht jede Person ein Google-Konto. Am Morgen von Tag 1 sammeln wir die Adressen ein und richten über Nacht euren Zugang ein.

- Habt ihr schon ein Google-Konto (z. B. Gmail), nutzt dieses.
- Sonst könnt ihr eure Firmenadresse als Google-Konto registrieren, ohne Gmail: auf [accounts.google.com/signup](https://accounts.google.com/signup) "Meine aktuelle E-Mail-Adresse verwenden" wählen.
- Testet die Anmeldung einmal auf [console.cloud.google.com](https://console.cloud.google.com). Ein eigenes Projekt oder eine Kreditkarte braucht ihr nicht.

## 2. Rechner

- 2 freie CPU-Kerne, 4 GB freier Arbeitsspeicher zusätzlich zu euren anderen Programmen, 20 GB freier Plattenplatz
- Rechte zum Installieren von Software, oder die IT installiert vorab
- Zugriff auf GitHub, Docker Hub, Maven Central, `registry.k8s.io` und `*.googleapis.com`, ggf. über den Firmen-Proxy

## 3. Werkzeuge installieren

Ihr braucht: Docker, minikube, kubectl, Git, curl, Python 3 (ab 3.9), die Google Cloud CLI (`gcloud`) und das GKE-Auth-Plugin. Java und Maven braucht ihr nicht, sie laufen im Docker-Build.

### Windows: alles in WSL2

Alle Workshop-Befehle laufen in Bash unter WSL2 (Ubuntu), nicht in PowerShell oder CMD.

1. WSL2 mit Ubuntu einrichten. In PowerShell als Administrator, danach neu starten:

   ```powershell
   wsl --install -d Ubuntu-24.04
   ```

   Beim ersten Start von "Ubuntu" einen Linux-Benutzer und ein Passwort anlegen.

2. Docker in WSL2 verfügbar machen. Eine der beiden Varianten:

   - **Docker Desktop** für Windows. Unter Settings, Resources, WSL Integration die Ubuntu-Distribution einschalten. Hinweis: Docker Desktop braucht in größeren Unternehmen eine kostenpflichtige Lizenz. Klärt das mit eurer IT.
   - **Docker Engine direkt in Ubuntu**, ohne Docker Desktop und ohne Lizenzfrage. In der Ubuntu-Shell:

     ```bash
     curl -fsSL https://get.docker.com | sudo sh
     sudo usermod -aG docker "$USER"
     ```

     Danach in PowerShell `wsl --shutdown` und Ubuntu neu öffnen. Prüfen mit `docker run --rm hello-world`. Falls Docker nicht startet: In `/etc/wsl.conf` muss unter `[boot]` die Zeile `systemd=true` stehen.

3. Weiter mit "Linux und WSL2" unten, in der Ubuntu-Shell.

Legt das Repository im Linux-Home ab (`~/gke-workshop`), nicht unter `/mnt/c/...`. Dort sind Dateizugriffe deutlich langsamer. VS Code öffnet den Ordner aus WSL mit `code .` (Erweiterung "WSL").

### Linux und WSL2 (Ubuntu)

Google Cloud CLI, Auth-Plugin und kubectl kommen aus Googles Paketquelle:

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates gnupg curl git python3
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get update
sudo apt-get install -y google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin kubectl
```

minikube:

```bash
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
```

Auf einem reinen Linux-Rechner installiert ihr Docker Engine wie oben unter Windows beschrieben.

### macOS

Mit [Homebrew](https://brew.sh):

```bash
brew install git kubectl minikube python
brew install --cask google-cloud-sdk
gcloud components install gke-gcloud-auth-plugin
```

Docker: [Docker Desktop für Mac](https://docs.docker.com/desktop/setup/install/mac-install/). Auch hier gilt die Lizenzfrage in größeren Unternehmen. Eine Alternative stimmt ihr mit uns ab.

## 4. Probelauf

Im Terminal (Windows: Ubuntu-Shell):

```bash
git clone https://github.com/juice1000/gke-workshop.git
cd gke-workshop
bash lab00-check/check.sh
```

Erwartet: nur `OK`-Zeilen. Bei `FEHLT` steht ein Hinweis dabei. `HINWEIS`-Zeilen betreffen Werkzeuge für Tag 2 oder die Ablage unter Windows.

Dann einmal den Cluster starten und das Übungsimage bauen. Beides lädt viele Daten herunter, die ihr dann am Workshop-Tag nicht mehr laden müsst:

```bash
minikube start --driver=docker --cpus=2 --memory=4096 --kubernetes-version=v1.35.0
kubectl get nodes
docker build --build-arg APP_VERSION=1.0 -t hallo-app:1.0 lab02-hallo-app
minikube stop
```

Erwartet: ein Node `minikube` mit `STATUS Ready` und am Ende des Builds `naming to docker.io/library/hallo-app:1.0`. `minikube stop` hält den Cluster an, er bleibt für den Workshop erhalten.

## 5. Hinter einem Proxy

Falls euer Netzwerk einen Proxy nutzt:

- `HTTPS_PROXY`, `HTTP_PROXY` und `NO_PROXY` in der Shell setzen, unter WSL in `~/.bashrc`
- `NO_PROXY` um `localhost,127.0.0.1,192.168.49.0/24` ergänzen, damit kubectl den lokalen Cluster nicht über den Proxy anspricht
- Docker braucht den Proxy zusätzlich in seiner eigenen Konfiguration. Bei Firmenzertifikaten fragt eure IT

## Wenn etwas nicht geht

Schickt uns die Ausgabe von `bash lab00-check/check.sh` und die Fehlermeldung. Ein Rechner, auf dem es am ersten Tag nicht läuft, ist kein Problem: Ihr arbeitet dann zu zweit, und für den Cloud-Teil gibt es die Cloud Shell im Browser als Ausweg.
