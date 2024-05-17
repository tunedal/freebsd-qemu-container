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

# Install dependencies for building Python.
ASSUME_ALWAYS_YES=yes pkg install \
                      pkgconf sqlite3 libffi readline

# Build Python 3.12.
PATH="$PATH:/usr/local/sbin:/usr/local/bin"
hash=56bfef1fdfc1221ce6720e43a661e3eb41785dd914ce99698d8c7896af4bdaa1
pydist=Python-3.12.3
exebasename=python3.12
url=https://www.python.org/ftp/python/3.12.3/$pydist.tar.xz
fetch "$url"
sha256 -c "$hash" "$pydist.tar.xz" || exit 1
tar Jxvf "$pydist.tar.xz"
cd "$pydist"
./configure --prefix="/opt/$pydist" --enable-optimizations
make
DESTDIR="/mnt/$pydist" make install
ln -s "/opt/$pydist/bin"/{$exebasename,$exebasename-config} /mnt/usr/local/bin/

poweroff
