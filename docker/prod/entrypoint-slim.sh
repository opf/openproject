#!/bin/bash

set -e
set -o pipefail

# Use jemalloc at runtime
if [ "$USE_JEMALLOC" = "true" ]; then
	export LD_PRELOAD=libjemalloc.so.2
fi

exec "$@"
