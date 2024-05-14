======================
freebsd-qemu-container
======================

This repo contains build scripts for building an OCI container image
(i.e. a Docker image) that bundles QEMU_ with the official
`FreeBSD VM image`_, which is useful when you need to run FreeBSD but
all you have is a Linux VM.

To configure the VM on boot, mount a volume as ``/mnt/config``
containing a shell script named ``config.sh``.

The ``base`` directory builds the basic FreeBSD image with minimal
customizations:

* The boot prompt delay is reduced from 10 to 3 seconds.
* ``PermitRootLogin prohibit-password`` is added to ``sshd_config``.
* ``/etc/rc.local`` is set up to fetch configuration via TFTP.

  * ``config.sh``, ``authorized_keys`` and ``config.tar.gz`` are fetched
    from ``/mnt/config`` if they exist.
  * ``config.tar.gz`` is extracted.
  * If ``authorized_keys`` exists and is non-empty, it's copied to
    ``/root/.ssh`` and the SSH service is started. If it does not exist,
    SSH keys are generated in the container and copied to the host
    and to ``/mnt/config`` and the SSH service is started.
  * Finally ``config.sh`` is executed.

The ``python`` directory builds an image with various versions of
Python installed.

.. _qemu: https://www.qemu.org/

.. _FreeBSD VM image:
   https://download.freebsd.org/ftp/releases/VM-IMAGES/13.3-RELEASE/
