#!/bin/bash

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

set -e
set -o pipefail
ARCHITECTURE=$(get_architecture)

apt-get update -qq
apt-get install -y git wget curl gnupg2 apt-transport-https unzip build-essential libpq-dev

# install node + npm
curl -s https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCHITECTURE}.tar.gz | tar xzf - -C /usr/local --strip-components=1

wget --quiet -O- https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list

if [ ! "$BIM_SUPPORT" = "false" ]; then
	# https://learn.microsoft.com/en-gb/dotnet/core/install/linux-debian#debian-11
	wget --quiet https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb && \
		dpkg -i /tmp/packages-microsoft-prod.deb && rm /tmp/packages-microsoft-prod.deb
fi

apt-get update -qq
apt-get install -y \
	poppler-utils \
	unrtf \
	tesseract-ocr \
	catdoc \
	postgresql-9.6 \
	postgresql-client-9.6 \
	postgresql-13 \
	postgresql-client-13 \
	imagemagick \
	memcached

# remove any existing cluster
service postgresql stop
rm -rf /var/lib/postgresql/{9.6,13}

# Specifics for BIM edition
if [ ! "$BIM_SUPPORT" = "false" ]; then
	apt-get install -y dotnet-runtime-6.0 # required for BIM edition

	tmpdir=$(mktemp -d)
	cd $tmpdir

	# Install XKT converter
	npm install @xeokit/xeokit-gltf-to-xkt@1.3.1 -g

	# Install COLLADA2GLTF
	wget --quiet https://github.com/KhronosGroup/COLLADA2GLTF/releases/download/v2.1.5/COLLADA2GLTF-v2.1.5-linux.zip
	unzip -q COLLADA2GLTF-v2.1.5-linux.zip
	mv COLLADA2GLTF-bin "/usr/local/bin/COLLADA2GLTF"

	# IFCconvert
	wget --quiet https://s3.amazonaws.com/ifcopenshell-builds/IfcConvert-v0.6.0-517b819-linux64.zip
	unzip -q IfcConvert-v0.6.0-517b819-linux64.zip
	mv IfcConvert "/usr/local/bin/IfcConvert"

	wget --quiet https://github.com/bimspot/xeokit-metadata/releases/download/1.0.1/xeokit-metadata-linux-x64.tar.gz
	tar -zxvf xeokit-metadata-linux-x64.tar.gz
	chmod +x xeokit-metadata-linux-x64/xeokit-metadata
	cp -r xeokit-metadata-linux-x64/ "/usr/lib/xeokit-metadata"
	ln -s /usr/lib/xeokit-metadata/xeokit-metadata /usr/local/bin/xeokit-metadata

	cd /
	rm -rf $tmpdir
fi

gem install bundler --version "$BUNDLER_VERSION" --no-document

id $APP_USER || useradd -d /home/$APP_USER -m $APP_USER
