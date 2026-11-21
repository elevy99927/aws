#!/bin/bash
# Firecracker, the guest kernel, and the Ubuntu root filesystem in an ext4 image.
source "$(dirname "$0")/common.sh"

step "Firecracker v1.17.0 (as in the Firecracker lab)"
run 'ARCH=$(uname -m); VER=v1.17.0'
run 'URL=https://github.com/firecracker-microvm/firecracker/releases/download/$VER'
run 'curl -fsSLO $URL/firecracker-$VER-$ARCH.tgz && curl -fsSLO $URL/firecracker-$VER-$ARCH.tgz.sha256.txt'
run 'sha256sum -c firecracker-$VER-$ARCH.tgz.sha256.txt'
run 'tar -xzf firecracker-$VER-$ARCH.tgz && cp release-$VER-$ARCH/firecracker-$VER-$ARCH firecracker'
run './firecracker --version'

step "Download the Ubuntu root archive"
run 'URL=https://cloud-images.ubuntu.com/minimal/releases/noble/release'
run 'curl -fsSLO $URL/ubuntu-24.04-minimal-cloudimg-amd64-root.tar.xz'
run 'curl -fsSLO $URL/SHA256SUMS'
run 'sha256sum -c SHA256SUMS --ignore-missing'
run 'ls -lh ubuntu-24.04-minimal-cloudimg-amd64-root.tar.xz'

step "An empty ext4 image, filled from the archive"
run 'truncate -s 4G ubuntu.ext4'
run 'sudo mkfs.ext4 -F -q ubuntu.ext4'
run 'sudo mkdir -p /mnt/rootfs && sudo mount -o loop ubuntu.ext4 /mnt/rootfs'
run 'sudo tar --numeric-owner -xJpf ubuntu-24.04-minimal-cloudimg-amd64-root.tar.xz -C /mnt/rootfs'
run 'ls /mnt/rootfs'
run 'cat /mnt/rootfs/etc/os-release | head -2'

step "Make it bootable: cloud-init off, fstab, console, network, SSH"
run 'ssh-keygen -t ed25519 -N "" -q -f ~/.ssh/id_ed25519 && ls ~/.ssh/id_ed25519*'
run 'printf "Host 172.16.0.2\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null\n  LogLevel ERROR\n" >> ~/.ssh/config'
printf '\n$ sudo chroot /mnt/rootfs /bin/bash\n'
sudo chroot /mnt/rootfs /bin/bash -ex <<'IN' 2>&1 | sed 's/^+ /root@chroot:\/# /'
touch /etc/cloud/cloud-init.disabled
echo '/dev/vda / ext4 defaults 0 1' > /etc/fstab
echo fc-guest > /etc/hostname
printf '[Match]\nName=eth0\n\n[Network]\nAddress=172.16.0.2/30\nGateway=172.16.0.1\nDNS=1.1.1.1\nDHCP=no\n' > /etc/systemd/network/eth0.network
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
ssh-keygen -A
mkdir -p -m 700 /root/.ssh
systemctl enable serial-getty@ttyS0 systemd-networkd systemd-resolved ssh
IN
run 'sudo install -m 600 ~/.ssh/id_ed25519.pub /mnt/rootfs/root/.ssh/authorized_keys'
run 'sudo umount /mnt/rootfs'

step "Can this kernel run Docker?"
run 'S3=https://s3.amazonaws.com/spec.ccfc.min; KEY=firecracker-ci/20261023-dd7c24b0d165-0/x86_64/vmlinux-6.18.54'
run 'curl -fsSLO $S3/$KEY && curl -fsSLO $S3/$KEY.config'
run 'curl -fsSLO https://raw.githubusercontent.com/moby/moby/master/contrib/check-config.sh && chmod +x check-config.sh'
run './check-config.sh vmlinux-6.18.54.config > kernel-check.txt 2>&1 || true'
run "sed 's/\x1b\[[0-9;]*m//g' kernel-check.txt | grep -E 'CONFIG_' | grep -c -E 'enabled'"
run "sed 's/\x1b\[[0-9;]*m//g' kernel-check.txt | grep -E 'CONFIG_.*missing' || echo 'no CONFIG_ line missing'"
