#!/usr/bin/env bash
set -euo pipefail

installDocker() {
  # Don't run this as root as you'll not add your user to the docker group
  sudo apt update
  sudo apt install apt-transport-https ca-certificates software-properties-common curl
  # sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  # echo deb https://apt.dockerproject.org/repo ubuntu-$(lsb_release -c | awk '{print $2}') main | sudo tee /etc/apt/sources.list.d/docker.list
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt update
  # sudo apt install -y "linux-image-extra-$(uname -r)"
  sudo apt purge lxc-docker docker-engine docker.io
  sudo rm -rf /etc/default/docker
  sudo apt install -y docker-ce
  sudo service docker start
  sudo usermod -aG docker "${USER}"
}

installPackages() {
  sudo apt update -y
  cat files/pkgs/apt-core.lst | grep -v '^$\|^\s*\#' | tr '\n' ' ' | xargs sudo apt install -y
  sudo apt-mark manual $(cat files/pkgs/apt-core.lst | grep -v '^$\|^\s*\#' | tr '\n' ' ')

  if [[  -z "${WSL:-}" ]] && [[ "${WSL:-}" != "true" ]] && ! [ -x "$(command -v docker)" ]; then
    installDocker
  fi

  sudo apt upgrade -y
}

echo "Ubuntu Installer"

case "$1" in
  "packages" | "pkgs")
    installPackages
    ;;
  "termProfiles" | "gnomeTermProfiles" | "termColors")
    installGnomeTerminalProfiles
    ;;
  *)
    installPackages
    ;;
esac
