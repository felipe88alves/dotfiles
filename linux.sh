#!/usr/bin/env bash
# set -euo pipefail

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo 'Looks like you are on OS X'
  echo '  please try the install.sh script'
  exit 1
fi

if [[ $OSTYPE == *"android"* ]]; then
  echo 'Looks like you are on Android'
  echo '  please try the install.sh script'
  exit 1
fi

dotfiles_dir="${dotfiles_dir:-$(dirname "$0")}"
INSTALLDIR=$(pwd)

# shellcheck source=./lib.sh
source "${dotfiles_dir}/lib.sh"

detectRelease() {
  if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=${NAME:-}
    VER=${VERSION_ID:-}
  elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
  elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    OS=SuSe
  elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    OS=RedHat
  else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
  fi

  WSL=$([ "$(grep -Ei "(microsoft|wsl)" /proc/version)" ] && echo "true" || echo "false")
  export OS
  export VER
  export WSL
  echo "${OS} WSL=${WSL}" 
}

# installKubernetes() {
#   cd "${HOME}/.local/bin/" || exit
#   curl -sS https://get.k8s.io | bash
#   rm -rf kubernetes.tar.gz
#   ln -s ~/.local/bin/kubernetes/client/bin/* ~/.local/bin/
#   cd "${INSTALLDIR}" || exit
# }

installLinuxbrew() {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

installPackages() {
  case "$(detectRelease)" in
  "Arch"*)
    ./arch.sh packages
    ;;
  *)
    ./ubuntu.sh packages
    ;;
  esac

  # if ! [ -x "$(command -v terraform)" ]; then
  #   installHashicorp terraform
  #   installTerragrunt
  # fi
  if ! [ -x "$(command -v kubectl)" ]; then
    installKubernetes
  fi
}

installFonts() {
  mkdir -p "${HOME}"/.fonts/

  curl -fLo DroidSansMonoForPowerlinePlusNerdFileTypes.otf https://raw.githubusercontent.com/ryanoasis/nerd-fonts/1.0.0/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20for%20Powerline%20Nerd%20Font%20Complete.otf
  chmod 664 DroidSansMonoForPowerlinePlusNerdFileTypes.otf
  mv ./*.otf "${HOME}/.fonts/"
  wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
  sudo mv PowerlineSymbols.otf /usr/share/fonts/
  wget https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf
  sudo mv 10-powerline-symbols.conf /etc/fonts/conf.d/
  wget https://github.com/powerline/fonts/raw/master/Terminus/PSF/ter-powerline-v16b.psf.gz
  sudo mv ter-powerline-v16b.psf.gz /usr/share/consolefonts/
  if ! [ -d "${HOME}/.fonts/ubuntu-mono-powerline-ttf" ]; then
    git clone https://github.com/pdf/ubuntu-mono-powerline-ttf.git "${HOME}/.fonts/ubuntu-mono-powerline-ttf"
  else
    cd "${HOME}/.fonts/ubuntu-mono-powerline-ttf" || exit
    git pull
    cd "${INSTALLDIR}" || exit
  fi
  sudo fc-cache -vf
  cd "${INSTALLDIR}" || exit
}

installAll() {
  installPackages
  installFonts
}

case "$1" in
"packages" | "pkgs")
  installPackages
  ;;
"fonts")
  installFonts
  ;;
"release" | "getRelease")
  detectRelease
  ;;
*)
  installAll
  ;;
esac
