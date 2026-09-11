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

# Resolve the OpenProject repo root from this script's location so the wrapper
# we write below points at the developer's checkout regardless of where they
# run setup from.
REPO_ROOT="$(realpath "$(dirname "$0")/../../..")"
EXT_DIR="$REPO_ROOT/extensions/web-ifc-xeokit-metadata"

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
wget --quiet --tries 3 https://s3.amazonaws.com/ifcopenshell-builds/IfcConvert-v0.7.11-fea8e3a-linux64.zip
unzip -q IfcConvert-v0.7.11-fea8e3a-linux64.zip
mv IfcConvert "/usr/local/bin/IfcConvert"

cd /
rm -rf $tmpdir

# Clean up any prior install of the legacy .NET-based xeokit-metadata.
rm -f /usr/local/bin/xeokit-metadata
rm -rf /usr/lib/xeokit-metadata

# web-ifc-xeokit-metadata: install runtime deps and expose the CLI on PATH.
# Requires Node.js (>=22.18) and npm to already be available on the host.
(cd "$EXT_DIR" && npm install --omit=dev --no-audit --no-fund)
cat > /usr/local/bin/web-ifc-xeokit-metadata <<EOF
#!/bin/sh
exec "$EXT_DIR/node_modules/.bin/tsx" "$EXT_DIR/src/index.ts" "\$@"
EOF
chmod +x /usr/local/bin/web-ifc-xeokit-metadata

which IfcConvert
echo "✔ IfcConvert is in your path."

which COLLADA2GLTF
echo "✔ COLLADA2GLTF is in your path."

which web-ifc-xeokit-metadata
echo "✔ web-ifc-xeokit-metadata is in your path."

echo "DONE - Now execute the following as your development user:
      $ # Install XKT converter
      $ npm install @xeokit/xeokit-gltf-to-xkt@1.3.1 -g"
