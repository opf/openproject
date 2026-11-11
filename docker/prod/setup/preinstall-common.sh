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
# make sure all dependencies are up to date
apt-get upgrade -y

apt-get install -yq --no-install-recommends \
  ca-certificates \
  curl \
  wget \
  file \
  gnupg2 \
  lsb-release

wget --quiet -O- https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg -
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

apt-get update -qq
apt-get install -yq --no-install-recommends \
  libpq5 \
  libffi8 \
  unrtf \
  tesseract-ocr \
  poppler-utils \
  catdoc \
  imagemagick \
  libjemalloc2

for version in $PGVERSION_CHOICES ; do
  apt-get install -yq --no-install-recommends postgresql-client-$version
done

# Specifics for BIM edition
if [ ! "$BIM_SUPPORT" = "false" ]; then
  apt-get install -yq --no-install-recommends unzip

  # Install node + npm for BIM runtime tools.
  curl -s https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCHITECTURE}.tar.gz | tar xzf - -C /usr/local --strip-components=1
  npm install -g npm@${NPM_VERSION}

  tmpdir=$(mktemp -d)
  cd $tmpdir

  # Install XKT converter
  npm install -g @xeokit/xeokit-gltf-to-xkt@1.3.1

  # Install COLLADA2GLTF
  wget --no-verbose --tries 3 https://github.com/KhronosGroup/COLLADA2GLTF/releases/download/v2.1.5/COLLADA2GLTF-v2.1.5-linux.zip
  unzip -q COLLADA2GLTF-v2.1.5-linux.zip
  mv COLLADA2GLTF-bin "/usr/local/bin/COLLADA2GLTF"

  # IFCconvert
  wget --no-verbose --tries 3 https://s3.amazonaws.com/ifcopenshell-builds/IfcConvert-v0.8.5-a51b2c5-linux64.zip
  echo "4214d58e7cf0929fb04e9b79dca84fb9cc1fe73e56490258eb159c10137ab2c2  IfcConvert-v0.8.5-a51b2c5-linux64.zip" | sha256sum -c -
  unzip -q IfcConvert-v0.8.5-a51b2c5-linux64.zip
  mv IfcConvert "/usr/local/bin/IfcConvert"

  # Install IFC metadata extractor
  npm install -g @openproject/web-ifc-xeokit-metadata@0.0.1

  cd /
  rm -rf $tmpdir
fi

id $APP_USER || useradd -d /home/$APP_USER -m $APP_USER

# Purge helper packages used only while building this stage.
apt-get purge -yq --auto-remove \
  gnupg2 \
  lsb-release

# curl/wget are only needed during installation in this stage.
apt-get purge -yq --auto-remove \
  wget

rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.npm
truncate -s 0 /var/log/*log
