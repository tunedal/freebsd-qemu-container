#!/bin/bash

set -eu

have_image=0
have_snap=0
if test -f /mnt/config/snap.qcow2; then
     have_image=1
     if qemu-img snapshot -l /mnt/config/snap.qcow2|grep -q ""; then
         have_snap=1
     fi
fi

if test $have_image -eq 1; then
    image=/mnt/config/snap.qcow2
    if ! test -s "$image"; then
        # Create an actual QCOW2 image if it's an empty file.
        qemu-img create -f qcow2 -F qcow2 -b /custom.qcow2 "$image"
    fi
else
    image=/custom.qcow2
fi

if test $# -eq 0; then
    extra_args=()
    if test $have_snap -eq 1; then
        extra_args+=(-loadvm snap)
    fi

    if test -e /dev/kvm; then
        extra_args+=(-enable-kvm)
    fi

    exec qemu-system-x86_64 \
         -m 4096 \
         -smp 1 \
         -bios /usr/share/ovmf/OVMF.fd \
         -serial mon:stdio \
         -nographic \
         -drive file="$image" \
         -nic user,net=10.0.3.0/24,hostfwd=tcp::2222-:22,tftp=/mnt/config \
         "${extra_args[@]}"
else
    exec "$@"
fi
