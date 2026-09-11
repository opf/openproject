#!/usr/bin/env bash
# Regenerate test/golden/*.json by running the currently-shipped .NET
# xeokit-metadata against every .ifc in test/fixtures/.
#
# This produces the reference outputs against which web-ifc-xeokit-metadata is
# validated (parity test). It is only meaningful for IFC schemas the .NET tool
# can actually parse — currently IFC2X3 and IFC4. IFC4X3 fixtures will be
# skipped with a notice; the upcoming web-ifc-based implementation is the very
# reason the upgrade is needed and there is no .NET ground truth for it.
#
# Resolution order for the .NET binary:
#   1. $XEOKIT_METADATA_BIN if set
#   2. xeokit-metadata on $PATH
#   3. /usr/lib/xeokit-metadata/xeokit-metadata (default install location of
#      the opf/xeokit-metadata release tarball, see
#      docker/prod/setup/preinstall-common.sh)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXT_DIR="$(dirname "$SCRIPT_DIR")"
FIXTURES_DIR="$EXT_DIR/test/fixtures"
GOLDEN_DIR="$EXT_DIR/test/golden"

if [[ -n "${XEOKIT_METADATA_BIN:-}" ]]; then
  BIN="$XEOKIT_METADATA_BIN"
elif command -v xeokit-metadata >/dev/null 2>&1; then
  BIN="$(command -v xeokit-metadata)"
elif [[ -x /usr/lib/xeokit-metadata/xeokit-metadata ]]; then
  BIN=/usr/lib/xeokit-metadata/xeokit-metadata
else
  echo "error: xeokit-metadata not found." >&2
  echo "Install via modules/bim/bin/setup_dev.sh or set XEOKIT_METADATA_BIN." >&2
  exit 1
fi

echo "Using xeokit-metadata at: $BIN"
mkdir -p "$GOLDEN_DIR"

shopt -s nullglob
for ifc in "$FIXTURES_DIR"/*.ifc; do
  name="$(basename "$ifc" .ifc)"
  out="$GOLDEN_DIR/$name.json"
  echo -n "  $name ... "
  if "$BIN" "$(realpath "$ifc")" "$out" >/dev/null 2>&1; then
    echo "ok"
  else
    rm -f "$out"
    echo "SKIP (parser rejects this schema — expected for IFC4X3)"
  fi
done

echo "Wrote golden outputs to: $GOLDEN_DIR"
