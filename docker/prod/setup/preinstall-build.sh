#!/bin/bash
set -euxo pipefail

get_architecture() {
  if command -v uname > /dev/null; then
    ARCHITECTURE=$(uname -m)
    case $ARCHITECTURE in
      aarch64|arm64)
        echo "arm64"
        return 0
        ;;
      ppc64le)
        echo "ppc64le"
        return 0
        ;;
    esac
  fi

  echo "x64"
  return 0
}

ARCHITECTURE=$(get_architecture)

apt-get update -qq
apt-get install -yq --no-install-recommends \
  ca-certificates \
  curl \
  git \
  build-essential \
  libyaml-dev \
  libpq-dev \
  libclang-dev

if ! command -v node > /dev/null || ! command -v npm > /dev/null; then
  curl -s https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCHITECTURE}.tar.gz | tar xzf - -C /usr/local --strip-components=1
fi

npm install -g npm@${NPM_VERSION}

rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
truncate -s 0 /var/log/*log
