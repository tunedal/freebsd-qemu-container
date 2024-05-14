#!/usr/bin/env python3

import sys
from base64 import b64encode
from textwrap import dedent
from shlex import quote
from pathlib import Path

import pexpect

# Script written to /etc/rc.local in custom.qcow2.
rc_local = (Path(__file__).parent / "rc.local").read_text()

# Script executed in boot.qcow2.
bootstrap_script = dedent(fr"""
  set -eu
  gpart recover ada1
  gpart resize -i4 ada1
  growfs -y /dev/ada1p4
  mount -o noatime /dev/ada1p4 /mnt
  echo 'autoboot_delay="3"' >>/mnt/boot/loader.conf
  echo 'PermitRootLogin prohibit-password' >>/mnt/etc/ssh/sshd_config
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
    # This only seems to happen with more than one CPU.
    crashed = child.expect(["Enter full pathname of shell.*$",
                            "Automatic reboot in 15 seconds"])

child.sendline("/bin/sh")

child.expect("root@.*$")
child.sendline("stty -icanon")

child.expect("root@.*$")
child.sendline("mount -rw /")

blob = b64encode(bootstrap_script.encode("utf-8")).decode("ascii")
chunk_size = 40
for i in range(0, len(blob), chunk_size):
    chunk = blob[i:i+chunk_size]
    child.expect("root@.*$")
    child.sendline(f"echo '{chunk}' >>bootstrap.base64")

child.expect("root@.*$")
child.sendline("b64decode -r <bootstrap.base64 >bootstrap.sh")
child.expect("root@.*$")
child.sendline("sh bootstrap.sh")

child.expect(r"Bootstrap script finished\.")
child.close()
child.wait()
