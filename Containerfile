FROM debian:bookworm-slim

RUN apt-get -y update && apt-get -y install --no-install-recommends \
      qemu-system-x86 qemu-utils ovmf \
      xz-utils curl ca-certificates \
      python3 python3-pexpect

ENV FBSD_URL=https://download.freebsd.org/ftp/releases/VM-IMAGES \
    FBSD_VERSION=13.3-RELEASE

ENV IMG_FILENAME="FreeBSD-$FBSD_VERSION-amd64.qcow2.xz" \
    IMG_HASH="343597127ae381d9a848dc828e96a85382063fe051986402fc80c16ba69995b9"

RUN curl -O "$FBSD_URL/$FBSD_VERSION/amd64/Latest/$IMG_FILENAME" && \
    echo "SHA256 ($IMG_FILENAME) = $IMG_HASH"|sha256sum -c --strict - && \
    unxz "$IMG_FILENAME"

COPY bootstrap.py /

RUN ln -s "$(basename "$IMG_FILENAME" .xz)" freebsd.qcow2 && \
    qemu-img create -f qcow2 -F qcow2 -b freebsd.qcow2 boot.qcow2 && \
    qemu-img create -f qcow2 -F qcow2 -b freebsd.qcow2 custom.qcow2 8G && \
    python3 /bootstrap.py && \
    rm /bootstrap.py boot.qcow2

EXPOSE 2222

CMD ["qemu-system-x86_64", "-m", "4096", "-smp", "2", \
     "-bios", "/usr/share/ovmf/OVMF.fd", \
     "-serial", "mon:stdio", \
     "-nographic", \
     "-drive", "file=custom.qcow2", \
     "-nic", "user,net=10.0.3.0/24,hostfwd=tcp::2222-:22,tftp=/mnt/config"]
