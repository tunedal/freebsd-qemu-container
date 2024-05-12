#!/usr/bin/env python3

import sys
from base64 import b64encode
from textwrap import dedent
from shlex import quote

import pexpect

# Script written to /etc/rc.local in custom.qcow2.
rc_local = dedent(r"""
  set -eu
  cd "$(mktemp -d)"

  echo 'Fetching customizations via TFTP.'
  printf '%s\n' 'binary' 'get config.sh'|tftp 10.0.3.2

  echo 'Executing customizations.'
  exec sh config.sh
""").lstrip()

# Script executed in boot.qcow2.
bootstrap_script = dedent(fr"""
  set -eu
  gpart recover ada1
  gpart resize -i4 ada1
  growfs -y /dev/ada1p4
  mount -o noatime /dev/ada1p4 /mnt
  echo 'autoboot_delay="3"' >>/mnt/boot/loader.conf
  echo -n {quote(b64encode(rc_local.encode("utf-8")).decode("ascii"))} \
    | b64decode -r >/mnt/etc/rc.local
  umount /mnt
  sync
  echo 'Bootstrap script finished.'
""").lstrip()

qemu_args = ["-m", "4096",
             "-smp", "1",
             "-bios", "/usr/share/ovmf/OVMF.fd",
             "-serial", "mon:stdio",
             "-nographic",
             "-hda", "/boot.qcow2",
             "-hdb", "/custom.qcow2"]

child = pexpect.spawn("qemu-system-x86_64", qemu_args, timeout=120, echo=False)
child.logfile = sys.stdout.buffer

crashed = 1
while crashed:
    child.expect("Welcome to FreeBSD")
    child.send("s")

    # Sometimes the VM crashes on boot, but it's usually fine on the next try.
    crashed = child.expect(["Enter full pathname of shell.*$",
                            "Automatic reboot in 15 seconds"])

child.sendline("/bin/sh")

blob = b64encode(bootstrap_script.encode("utf-8")).decode("ascii")
child.expect("root@.*$")
child.sendline("stty -icanon")
child.expect("root@.*$")
child.sendline(f"echo '{blob}'|b64decode -r|sh -s")

child.expect(r"Bootstrap script finished\.")
child.close()
child.wait()
