#!/bin/bash

set -eu

BASEDIR="$(dirname "$0")"
CONFIG_TEMPDIR="$(mktemp -d)"

trap 'rm -rf "$CONFIG_TEMPDIR"' EXIT

if ! test -f "$BASEDIR/config/config.sh"; then
    cp "$BASEDIR/config/config.example.sh" "$CONFIG_TEMPDIR/config.sh"
    cat ~/.ssh/id_*.pub >"$CONFIG_TEMPDIR/authorized_keys"
    tar zcf "$BASEDIR/config/config.tar.gz" -C "$CONFIG_TEMPDIR" .
fi

rm -rf "$CONFIG_TEMPDIR"

exec podman run -it \
     -p 2222:2222 \
     --rm \
     -v "$BASEDIR/config:/mnt/config" \
     qemu "$@"
