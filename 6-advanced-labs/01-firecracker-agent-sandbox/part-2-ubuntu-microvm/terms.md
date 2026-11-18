# Part 2: the terms

The technical terms used in [Part 2: An Ubuntu microVM](README.md), in the order they appear. One line each; the lab page has the details.

| Term | What it means here |
|---|---|
| **microVM** | A small virtual machine started by Firecracker: a kernel, a root disk, a few devices, nothing else |
| **Firecracker** | The open-source virtual machine monitor behind AWS Lambda. One process per microVM, configured through an API or a JSON file |
| **Nested virtualization** | The EC2 instance gets the CPU's virtualization features, so its own KVM can run a microVM inside the instance |
| **KVM** | The Linux kernel's hypervisor (`/dev/kvm`). Firecracker uses it to run the guest's CPU |
| **Host and guest** | The host is the EC2 instance; the guest is the Ubuntu system inside the microVM |
| **Root filesystem (rootfs)** | The disk the guest boots from: here a file, `ubuntu.ext4`, that holds a complete Ubuntu |
| **Root archive** | Canonical's `…-root.tar.xz`: a tar file of the Ubuntu filesystem, with no partitions and no boot loader. Not the `.img` disk image |
| **ext4** | The Linux filesystem format of the image file; `mkfs.ext4` formats it |
| **Sparse file** | A file whose empty blocks take no disk space. `truncate -s 4G` makes one; `ls -ls` shows the real usage in the first column |
| **Loop mount** | Mounting a file as if it were a disk (`mount -o loop`), so the host can write into the image |
| **chroot** | Runs a shell with another folder as its root, so commands act on the image's files as if they were the running system |
| **cloud-init** | The first-boot tool of cloud images; it asks the cloud for network, hostname and SSH keys. Switched off here: there is no cloud inside a microVM |
| **fstab** | The guest's table of filesystems: tells Ubuntu that `/dev/vda` is `/` |
| **virtio** | The paravirtual devices Firecracker gives the guest: `virtio-blk` is the disk (`/dev/vda`), `virtio-net` is the network card (`eth0`) |
| **Serial console (`ttyS0`)** | The guest's text console, shown in Firecracker's terminal; `console=ttyS0` in the boot arguments and `serial-getty@ttyS0` for a login prompt |
| **systemd** | Ubuntu's init system (PID 1): starts the services, including the network and SSH |
| **systemd-networkd** | The network service configured by the `eth0.network` file: static address, gateway, DNS |
| **Host keys** | The SSH server's own key pair; `ssh-keygen -A` creates them, because cloud-init normally does and it is off |
| **Kernel config** | The list of features a kernel was built with (`vmlinux-6.18.54.config`); Docker's `check-config.sh` reads it |
| **Namespaces, cgroups v2, overlayfs** | Kernel features Docker needs: isolation of processes and networks, resource limits, and the layered filesystem of images |
| **TAP device** | A virtual network card on the host (`tap0`); Firecracker connects the guest's `eth0` to it |
| **NAT (MASQUERADE)** | The host rewrites the guest's packets with its own address on the way out, so the guest can reach the internet with a private address |
| **ip_forward** | The kernel setting that lets the host pass packets between interfaces, a router's job |
| **FORWARD rules** | The iptables rules that allow the forwarded traffic: out from `tap0`, and replies back |
| **Instance metadata (`169.254.169.254`)** | The EC2 service that hands out the instance's credentials and settings; the guest is blocked from it |
| **Two layers of NAT** | The host's NAT for the guest, and Docker's NAT (the `docker0` bridge) for the containers inside the guest |
| **Boot arguments** | The kernel command line in `vm.json`: `console=ttyS0 reboot=k panic=1 root=/dev/vda rw` |
| **`reboot=k`** | Makes a reboot inside the guest end the Firecracker process instead of restarting the VM |
| **Config file (`vm.json`)** | Firecracker's `--config-file`: the same settings as the API calls (kernel, drive, machine size, network), in one JSON file |
| **Docker Engine** | The container runtime inside the guest; the Compose plugin runs several containers from one file |
| **Named volume** | A Docker-managed folder (`jobdata`) that outlives the container that wrote to it |
| **Base image** | `ubuntu-docker-base.ext4`: the clean guest disk saved at the end. Every job in Part 3 starts from a copy of it |
| **User data** | A script EC2 runs at the first boot; the Terraform path uses it to run the lab's scripts on the host |
