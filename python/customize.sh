#!/bin/sh

set -eu

mount -o noatime /dev/ada1p4 /mnt

ASSUME_ALWAYS_YES=yes pkg bootstrap
ASSUME_ALWAYS_YES=yes pkg -r /mnt install \
                      python3 \
                      python38 py38-sqlite3 \
                      python39 py39-sqlite3 \
                      python310 py310-sqlite3 \
                      python311 py311-sqlite3

poweroff
