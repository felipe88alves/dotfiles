#!/usr/bin/env bash
set -x

GOVERSION=1.23.3

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
INSTALL_DIR="${HOME}/.local"

_installGo() {
    curl -OL https://golang.org/dl/go${GOVERSION}.${OS}-${ARCH}.tar.gz
    tar -C ${INSTALL_DIR}/ -xf go${GOVERSION}.${OS}-${ARCH}.tar.gz
    mkdir -p ${INSTALL_DIR}/go/pkg/mod
    rm go${GOVERSION}.${OS}-${ARCH}.tar.gz
}


if [[ -d ${GOBIN} ]]; then
    INSTALLED_GO_VERSION="$(${GOBIN}/go version | { read _ _ v _; echo ${v#go}; })" || false
    if [[ ${INSTALLED_GO_VERSION:-} != ${GOVERSION} ]]; then
        rm -rf ${HOME}/go
        _installGo
    fi
else
    _installGo
fi
