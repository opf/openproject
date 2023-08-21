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
apt-get install -y dotnet-runtime-6.0 wget unzip

tmpdir=$(mktemp -d)
cd $tmpdir

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
cp -rT xeokit-metadata-linux-x64 "/usr/lib/xeokit-metadata"
rm -f /usr/local/bin/xeokit-metadata
ln -s /usr/lib/xeokit-metadata/xeokit-metadata /usr/local/bin/xeokit-metadata

cd /
rm -rf $tmpdir

which IfcConvert
echo "✔ IfcConvert is in your path."

which COLLADA2GLTF
echo "✔ COLLADA2GLTF is in your path."

which xeokit-metadata
echo "✔ xeokit-metadata is in your path."

echo "DONE - Now execute the following as your development user:
      $ # Install XKT converter
      $ npm install @xeokit/xeokit-gltf-to-xkt@1.3.1 -g"
