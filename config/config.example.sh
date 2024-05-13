#!/bin/sh

echo 'Configuring system.'

chsh -s /bin/sh

echo 'PermitRootLogin prohibit-password' >>/etc/ssh/sshd_config
service sshd onestart

mkdir -p /root/.ssh
chmod 600 /root/.ssh
cp "$(dirname "$0")/authorized_keys" /root/.ssh/
