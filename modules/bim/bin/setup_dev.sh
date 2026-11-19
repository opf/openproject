#!/bin/bash

set -e

if ! which apt > /dev/null 2>&1; then
        echo "Needs debian/ubuntu system :-("
        exit 1;
fi

if [[ $EUID -ne 0 ]]; then
   echo "Must be run as root user."
   exit 1
fi

# Specifics for BIM edition (Ubuntu)
apt-get update -qq
apt-get install -y wget unzip

tmpdir=$(mktemp -d)
cd $tmpdir

# Install COLLADA2GLTF
wget --quiet --tries 3 https://github.com/KhronosGroup/COLLADA2GLTF/releases/download/v2.1.5/COLLADA2GLTF-v2.1.5-linux.zip
unzip -q COLLADA2GLTF-v2.1.5-linux.zip
mv COLLADA2GLTF-bin "/usr/local/bin/COLLADA2GLTF"

# IFCconvert
wget --quiet --tries 3 https://s3.amazonaws.com/ifcopenshell-builds/IfcConvert-v0.8.5-a51b2c5-linux64.zip
echo "4214d58e7cf0929fb04e9b79dca84fb9cc1fe73e56490258eb159c10137ab2c2  IfcConvert-v0.8.5-a51b2c5-linux64.zip" | sha256sum -c -
unzip -q IfcConvert-v0.8.5-a51b2c5-linux64.zip
mv IfcConvert "/usr/local/bin/IfcConvert"

cd /
rm -rf $tmpdir

# Clean up any prior install of the legacy .NET-based xeokit-metadata.
rm -f /usr/local/bin/xeokit-metadata
rm -rf /usr/lib/xeokit-metadata

# Install IFC metadata extractor
# Requires Node.js (>=22.18) and npm to already be available on the host.
npm install -g @openproject/web-ifc-xeokit-metadata@0.0.1

which IfcConvert
echo "✔ IfcConvert is in your path."

which COLLADA2GLTF
echo "✔ COLLADA2GLTF is in your path."

which web-ifc-xeokit-metadata
echo "✔ web-ifc-xeokit-metadata is in your path."

echo "DONE - Now execute the following as your development user:
      $ # Install XKT converter
      $ npm install @xeokit/xeokit-gltf-to-xkt@1.3.1 -g"
