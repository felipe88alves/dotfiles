#!/usr/bin/env bash
set -eo pipefail

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
INSTALLDIR=$(pwd)
dotfiles_dir="$(dirname "$0")"

CMD="${1:-all}"
shift || true
ARGS=("$@")

# shellcheck source=./lib.sh
source "${dotfiles_dir}/lib.sh"

installGoPkgs() {
  source "${dotfiles_dir}/files/scripts/golang"
  installPkgList "go install" <(sed 's|$|@latest|g' files/pkgs/go.lst)
}

installPips() {
  installPkgList "pipx install --include-deps" files/pkgs/pip.lst
  pipx upgrade-all
}

installVscodeConfig() {
  settings="$HOME/.config/Code/User"
  if [[ $OSTYPE == "darwin"* ]]; then
    settings="$HOME/Library/Application Support/Code/User"
  fi
  mkdir -p "$settings"
  cp -r files/config/vscode/* "$settings/"
}

installVscodePackages() {
  installVscodeConfig

  installPkgList "code --install-extension" files/pkgs/vscode-packages.lst
}

# installTmuxConf() {
#   cp files/shell/tmux.conf.local "${HOME}/.tmux.conf.local"
#   git_clone_or_update https://github.com/gpakosz/.tmux.git "${HOME}/.tmux"
#   if [ ! -s "${HOME}/.tmux.conf" ]; then
#     ln -s "${HOME}/.tmux/.tmux.conf" "${HOME}/.tmux.conf"
#   fi
# }

installGitConf() {
  source config.sh

  sedcmd=''
  for var in NAME EMAIL; do
    printf -v sc 's|${%s}|%s|;' ${var} "${!var//\//\\/}"
    sedcmd+="${sc}"
  done
  cat files/git/gitconfig | sed -e "${sedcmd}" >"${HOME}/.gitconfig"
  cp files/git/gitexcludes "${HOME}/.gitexcludes"
}

installShellConf() {
  cp files/shell/variables "${HOME}/.variables"
  cp files/shell/profile "${HOME}/.profile"
  
  configAliases

  installBashConf
  installZshConf
  # installTmuxConf
  installGitConf

  source "${HOME}/.profile"
}

configAliases() {
  mkdir -p "${HOME}/.aliases.d"
  cp -r files/shell/aliases.d/* "${HOME}/.aliases.d"

  if [ -z "${SHELLVARS:-}" ]; then
    SHELLVARS=$(comm -3 <(compgen -v | sort) <(compgen -e | sort) | grep -v '^_')
    source config.sh
    CONF=$(comm -3 <(compgen -v | sort) <(compgen -e | sort) | grep -v '^_')
    CONF=$(comm -3 <(echo "${CONF}" | tr ' ' '\n' | sort -u) <(echo "${SHELLVARS}" | tr ' ' '\n' | sort -u) | grep -v 'SHELLVARS')
  fi

  sedcmd=''
  for var in $(echo "${CONF}"); do
    printf -v sc 's|${%s}|%s|;' "${var}" "${!var//\//\\/}"
    sedcmd+="${sc}"
  done
  cat files/shell/aliases | sed -e "${sedcmd}" > "${HOME}"/.aliases
  source "${HOME}"/.aliases
}

installBashConf() {
  mkdir -p "${HOME}"/.bash/

  cd "${INSTALLDIR}" || exit

  cp files/shell/bash/git_prompt.sh "${HOME}/.bash/"
  cp files/shell/bash/git-prompt-colors.sh "${HOME}/.git-prompt-colors.sh"
  cp files/shell/bash/shell_prompt.sh "${HOME}/.bash/"
  cp files/shell/bash/bashrc "${HOME}/.bashrc"
  cp files/shell/bash/bash_profile "${HOME}/.bash_profile"

  git_clone_or_update https://github.com/cykerway/complete-alias.git "${HOME}/.bash/complete-alias"
  git_clone_or_update https://github.com/magicmonty/bash-git-prompt.git "${HOME}/.bash/bash-git-prompt"
  git_clone_or_update https://github.com/jonmosco/kube-ps1.git "${HOME}/.bash/kube-ps1"
  git_clone_or_update https://github.com/milkbikis/powerline-shell "${HOME}/.bash/powerline-shell"

  source "${HOME}/.bash_profile"
}

installZshConf() {
  ZSH=${ZSH:-${HOME}/.oh-my-zsh}
  ZSH_CUSTOM=${ZSH_CUSTOM:-${ZSH}/custom}

  echo ">>> oh-my-zsh"
  if [ ! -d "${HOME}"/.oh-my-zsh ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    cd "${HOME}"/.oh-my-zsh || exit
    git pull
    cd "${INSTALLDIR}" || exit
  fi
  

  git_clone_or_update https://github.com/denysdovhan/spaceship-prompt.git "${ZSH_CUSTOM}/themes/spaceship-prompt"
  if [ ! -s "${ZSH_CUSTOM}/themes/spaceship.zsh-theme" ]; then
    ln -s "${ZSH_CUSTOM}/themes/spaceship-prompt/spaceship.zsh-theme" "${ZSH_CUSTOM}/themes/spaceship.zsh-theme"
  fi
  git_clone_or_update https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM}/themes/powerlevel10k"
  git_clone_or_update https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
  git_clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
  git_clone_or_update https://github.com/zsh-users/zsh-completions "${ZSH_CUSTOM}/plugins/zsh-completions"
  git_clone_or_update https://github.com/zsh-users/zsh-history-substring-search "${ZSH_CUSTOM}/plugins/zsh-history-substring-search"
  git_clone_or_update https://github.com/hlissner/zsh-autopair.git "${ZSH_CUSTOM}/plugins/zsh-autopair"
  git_clone_or_update https://github.com/Aloxaf/fzf-tab.git "${ZSH_CUSTOM}/plugins/fzf-tab"

  cp files/shell/zsh/zshrc "${HOME}/.zshrc"
  cp files/shell/zsh/zshHighlightStyle "${HOME}/.zshrcHighlightStyle"
  cp files/shell/zsh/p10k.zsh "${HOME}/.p10k.zsh"

  chsh -s $(which zsh)
}

installDotFiles() {
  installShellConf
}

installPackages() {
  installGoPkgs
  installVscodePackages
  installPips
}

installOSSpecific() {
  if [[ $OSTYPE == "darwin"* ]]; then
    ./osx.sh "${@}"
  else
    ./linux.sh "${@}"
  fi
}

installAll() {
  installDotFiles
  if [[ $OSTYPE != *"android"* ]]; then
    installPackages
  fi

}

if isFunction "${CMD}"; then
  $CMD "${ARGS[@]}"
  exit $?
elif isFunction "install${CMD}"; then
  "install${CMD}" "${ARGS[@]}"
  exit $?
fi

case "$CMD" in
"ospkgs")
  installOSSpecific pkgs
  ;;
"alias")
  configAliases
  ;;
"pip")
  installPips
  ;;
"go" | "gopkgs")
  installGoPkgs
  ;;
"dotfiles")
  installDotFiles
  installOSSpecific "dotfiles"
  ;;
"vscodepackages" | "vscode" | "vspkgs")
  installVscodePackages
  ;;
*)
  installOSSpecific "${CMD}" "${ARGS[@]}"
  if [[ -z "${CMD}" || ${CMD} == "all" ]]; then
    installAll
    exec zsh
  fi
  ;;
esac

echo "bootstrap successful!"
