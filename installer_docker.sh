#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

cecho() {
  local color="$1"; shift
  echo -e "${color}$*${NC}"
}


cecho "${CYAN}" "Welcome to Docker-CE installer for Debian/Ubuntu/RHEL/CentOS/Alma/Rocky"



if [[ $EUID -ne 0 ]]; then
  cecho "${RED}" ">>> Please run as root or via sudo."
  exit 1
fi

. /etc/os-release

install_debian_ubuntu() {
  cecho "${CYAN}" "[+] Removing old Docker packages..."
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    apt-get remove -y "$pkg" || true
  done

  cecho "${CYAN}" "[+] Installing prerequisites..."
  apt-get update
  apt-get install -y ca-certificates curl gnupg lsb-release

  cecho "${CYAN}" "[+] Fetching and dearmoring Docker GPG key..."
  mkdir -p /usr/share/keyrings
  if curl -fsSL "https://download.docker.com/linux/$ID/gpg" \
       | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; then
    cecho "${GREEN}" "Key saved to /usr/share/keyrings/docker-archive-keyring.gpg"
  else
    cecho "${YELLOW}" "dearmor failed, falling back to apt-key adv"
    curl -fsSL "https://download.docker.com/linux/$ID/gpg" \
      | apt-key add - >/dev/null
  fi

  cecho "${CYAN}" "[+] Adding Docker APT repository..."
  CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
  cat > /etc/apt/sources.list.d/docker.list <<EOF
  deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/$ID \
  ${CODENAME} stable
EOF

  cecho "${CYAN}" "[+] Installing Docker Engine and tools..."
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io \
                     docker-buildx-plugin docker-compose-plugin

  cecho "${GREEN}" "[+] Enabling and starting Docker..."
  systemctl enable --now docker
}

install_centos() {
  cecho "${CYAN}" "[+] Removing old Docker packages (CentOS)..."
  dnf remove -y docker \
                docker-client \
                docker-client-latest \
                docker-common \
                docker-latest \
                docker-latest-logrotate \
                docker-logrotate \
                docker-engine || true

  cecho "${CYAN}" "[+] Installing dnf-plugins-core..."
  dnf install -y dnf-plugins-core

  cecho "${CYAN}" "[+] Adding Docker repository (CentOS)..."
  dnf config-manager --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

  cecho "${CYAN}" "[+] Installing Docker Engine and tools..."
  dnf install -y docker-ce docker-ce-cli containerd.io \
                 docker-buildx-plugin docker-compose-plugin

  cecho "${GREEN}" "[+] Enabling and starting Docker..."
  systemctl enable --now docker
}

install_rhel_family() {
  cecho "${CYAN}" "[+] Removing old Docker, Podman and runc packages..."
  dnf remove -y docker \
                docker-client \
                docker-client-latest \
                docker-common \
                docker-latest \
                docker-latest-logrotate \
                docker-logrotate \
                docker-engine \
                podman \
                runc || true

  cecho "${CYAN}" "[+] Installing dnf-plugins-core..."
  dnf install -y dnf-plugins-core

  cecho "${CYAN}" "[+] Adding Docker repository (RHEL)..."
  dnf config-manager --add-repo \
    https://download.docker.com/linux/rhel/docker-ce.repo

  cecho "${CYAN}" "[+] Installing Docker Engine and tools..."
  dnf install -y docker-ce docker-ce-cli containerd.io \
                 docker-buildx-plugin docker-compose-plugin

  cecho "${YELLOW}" "    ↑ When prompted, verify fingerprint is:"
  cecho "${YELLOW}" "      060A 61C5 1B55 8A7F 742B 77AA C52F EB6B 621E 9F35"

  cecho "${GREEN}" "[+] Enabling and starting Docker..."
  systemctl enable --now docker
}

post_install_common() {
  cecho "${CYAN}" "[+] Add current user to docker group ..."
  usermod -aG docker "$USER"

  cecho "${CYAN}" "[+] Identify shell ..."
  if [[ -v BASH ]]; then
    cecho "${CYAN}" "[+] It is bash, install bash completion definition for docker-compose ..."
    curl -Ls https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose \
      -o /etc/bash_completion.d/docker-compose
    source /etc/bash_completion.d/docker-compose
  fi

  # Apply new group membership
  newgrp docker
}


case "${ID,,}" in
  debian|ubuntu)
    cecho "${BLUE}" "Detected distro: $PRETTY_NAME"
    install_debian_ubuntu
    ;;

  centos)
    cecho "${BLUE}" "Detected distro: $PRETTY_NAME"
    install_centos
    ;;

  rhel|almalinux|rocky)
    cecho "${BLUE}" "Detected distro: $PRETTY_NAME"
    install_rhel_family
    ;;

  *)
    cecho "${RED}" "Error: $PRETTY_NAME is not supported by this script."
    exit 2
    ;;
esac

post_install_common

cecho "${MAGENTA}" "🎉 Docker installation complete!"

