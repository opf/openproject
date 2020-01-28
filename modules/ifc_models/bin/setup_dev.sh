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

# Install BIM specifics
echo "-- Installing dependencies --"
apt-get update -qq && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
  curl wget unzip git cmake gcc g++ libboost-all-dev libicu-dev \
  libpcre3-dev libxml2-dev \
  liboce-foundation-dev liboce-modeling-dev liboce-ocaf-dev liboce-visualization-dev liboce-ocaf-lite-dev

echo "-- (Re-)creating /usr/local/src/bim base folder --"
rm -rf /usr/local/src/bim || true
mkdir -p /usr/local/src/bim
cd /usr/local/src/bim

# OpenCOLLADA
echo "-- Downloading and building OpenCOLLADA --"
git clone https://github.com/KhronosGroup/OpenCOLLADA.git --depth 1
mkdir OpenCOLLADA/build
pushd OpenCOLLADA/build
cmake ..
make -j
make install
popd

# Install COLLADA2GLTF
echo "-- Downloading COLLADA2GLTF --"
wget --quiet https://github.com/KhronosGroup/COLLADA2GLTF/releases/download/v2.1.5/COLLADA2GLTF-v2.1.5-linux.zip
unzip -fq COLLADA2GLTF-v2.1.5-linux.zip -d /usr/lib/COLLADA2GLTF
ln -fs /usr/lib/COLLADA2GLTF/COLLADA2GLTF-bin /usr/local/bin/COLLADA2GLTF
rm -rf COLLADA2GLTF-v2.1.5-linux.zip

# IFCconvert
echo "-- Downloading IfcConvert --"
wget --quiet https://s3.amazonaws.com/ifcopenshell-builds/IfcConvert-v0.6.0-9bcd932-linux64.zip
unzip -q IfcConvert-v0.6.0-9bcd932-linux64.zip -d /usr/local/src/bim/IfcConvert-v0.6.0-9bcd932-linux64
ln -fs /usr/local/src/bim/IfcConvert-v0.6.0-9bcd932-linux64/IfcConvert /usr/local/bin/IfcConvert
rm -rf IfcConvert-v0.6.0-9bcd932-linux64.zip

echo "-- Downloading and building xeokit-metadata --"

wget --quiet https://github.com/bimspot/xeokit-metadata/releases/download/0.0.5/xeokit-metadata-linux-x64.tar.gz
tar -zxvf xeokit-metadata-linux-x64.tar.gz
chmod +x xeokit-metadata-linux-x64/xeokit-metadata
cp -r xeokit-metadata-linux-x64/ /usr/lib/xeokit-metadata
ln -fs /usr/lib/xeokit-metadata/xeokit-metadata /usr/local/bin/xeokit-metadata
rm -rf xeokit-metadata-linux-x64.tar.gz

which IfcConvert
echo "✔ IfcConvert is in your path."

which COLLADA2GLTF
echo "✔ COLLADA2GLTF is in your path."

which xeokit-metadata
echo "✔ xeokit-metadata is in your path. (without .NET yet, see below)"

echo "DONE - BUT! You still need to:

1. Install the NPM dependency under your user account

    npm install xeokit/xeokit-gltf-to-xkt -g

2. install your distribution's version of .NET core:

   Select distribution and follow steps at
   https://dotnet.microsoft.com/download/linux-package-manager/ubuntu18-04/runtime-2.2.0"
