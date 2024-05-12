#!/bin/bash

set -eu

BASEDIR="$(dirname "$0")"
BASEURL="https://download.freebsd.org/ftp/releases/VM-IMAGES"
VERSION="13.3-RELEASE"
PODMAN_TMPDIR=/mnt/podman/tmp

TMPDIR="$PODMAN_TMPDIR" podman --tmpdir="$PODMAN_TMPDIR" \
      build -t qemu "$BASEDIR"

mkdir -p "$BASEDIR/config"

# podman run -it \
#        -v "$BASEDIR/FreeBSD-$VERSION-amd64.qcow2:/freebsd.qcow2" \
#        qemu bash
