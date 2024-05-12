#!/bin/bash

set -eu

BASEDIR="$(dirname "$0")"

cp "$BASEDIR/config/config.example.sh" "$BASEDIR/config/config.sh"
echo -n "echo '$(cat ~/.ssh/id_*.pub|base64 -w0)'" >>"$BASEDIR/config/config.sh"
echo '|b64decode -r >>/root/.ssh/authorized_keys' >>"$BASEDIR/config/config.sh"

exec podman run -it \
     -p 2222:2222 \
     --rm \
     -v "$BASEDIR/config:/mnt/config" \
     qemu "$@"
