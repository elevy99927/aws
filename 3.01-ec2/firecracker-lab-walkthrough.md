# 3.01 Compute: Amazon EC2 – Firecracker Lab: Run Your Own MicroVM

[⬅ EC2 or Containers?](EC2-or-Containers.md) | [⬅ Back to 3.01 EC2](README.md)

**▶ Video walkthrough** (16 min):

[![Video: EC2 – Firecracker lab: run your own microVM](https://img.youtube.com/vi/hjsSbW37ib0/maxresdefault.jpg)](https://youtu.be/hjsSbW37ib0)

In this walkthrough you build a **microVM** by hand with **Firecracker**, the open-source VMM behind AWS Lambda. You start it on an EC2 instance, give it a Linux kernel and a tiny root filesystem, configure and start it through Firecracker's API, and reach a web server running inside it. No Docker: the guest is a minimal Linux system, a kernel and BusyBox.

The theory is in [EC2 or Containers?](EC2-or-Containers.md) and its video. Region: **`us-east-1`**.

![The Firecracker lab: your computer connects with SSH to the EC2 instance fc-lab (L1: m7i-flex.large, Ubuntu 24.04, nested virtualization) running on the AWS Nitro hypervisor (L0). On the host: terminal 1 runs Firecracker with an API socket and shows the serial console; terminal 2 sends API calls over the Unix socket and curls the guest; ~/fc holds firecracker v1.17.0, the guest kernel and rootfs.ext4; tap0 has 172.16.0.1/30. The Firecracker process runs one microVM (L2: 1 vCPU, 256 MiB) with guest kernel 6.18.54, a rootfs with BusyBox and /init, and BusyBox httpd on port 80 at 172.16.0.2. Firecracker runs the guest through KVM in the host kernel.](images/firecracker-lab.jpg)

<sub>Diagram source: [images/firecracker-lab.drawio](images/firecracker-lab.drawio) (open it in [draw.io](https://app.diagrams.net) to edit)</sub>

**Three layers of virtualization:** AWS's Nitro hypervisor runs your EC2 instance (L1). With **nested virtualization**, the instance gets the CPU's virtualization features, so its own KVM can run the microVM (L2).

> **Prerequisites:**
> - [Lab 1](lab-1.md) and [Lab 2](lab-2.md): launching an instance, SSH, security groups
> - The network `ecs-vpc` from [2.04 VPC and Networking – Lab 1](../2.04-vpc-and-networking/lab-1.md), or a default VPC

> 💰 **Cost:** `m7i-flex.large` is **Free Tier eligible**, but outside the Free Tier it costs about **$0.096 an hour** in `us-east-1` (Linux, on-demand), plus **$0.005 an hour** for its public IPv4 address. The walkthrough takes about 30–45 minutes. Nested virtualization itself has no extra charge. Terminate the instance at the end ([step 8](#8-clean-up)).

> Tested in `us-east-1` on 25 October 2026: `m7i-flex.large` with nested virtualization, Ubuntu 24.04 (host kernel 7.0.0-1014-aws), Firecracker v1.17.0, guest kernel 6.18.54, a 32 MB BusyBox rootfs. IDs, the account number and IP addresses in the screenshots are masked. The expected outputs below are from this run; long output is trimmed (`…`).

**Jump to:** [Where to run](#where-you-run-the-commands) · [Decisions](#the-decisions-in-this-lab) · [1. Launch](#1-launch-the-host) · [2. KVM](#2-check-kvm-on-the-host) · [3. Firecracker](#3-get-firecracker) · [4. Kernel and rootfs](#4-the-guest-kernel-and-root-filesystem) · [5. TAP](#5-host-networking-a-tap-device) · [6. API and start](#6-configure-and-start-the-microvm-through-the-api) · [7. curl, pause, snapshot](#7-reach-the-app-then-pause-and-resume) · [8. Clean up](#8-clean-up) · [Check yourself](#check-yourself)

---

## Where you run the commands

| Where | What runs there |
|---|---|
| **The AWS Console** | Step 1: launch the host |
| **Your computer** | The key file (`chmod 400`, step 1) and the `ssh` command that connects to the host |
| **The host** (`fc-lab`, over SSH) | Everything else, from step 2 on, in the folder **`~/fc`** |
| **Terminal 1** on the host | Steps 6–7: Firecracker itself, and the microVM's serial console |
| **Terminal 2** on the host | Steps 6–7: the API calls and `curl` |

Each step starts with a **Run on:** line. For terminals 1 and 2, open two terminals on your computer and SSH to the host from both.

---

## The decisions in this lab

| Choice | What and why |
|---|---|
| Host | **`m7i-flex.large`** (2 vCPUs, 8 GiB) with **nested virtualization**. AWS added nested virtualization in February 2026 for several Intel families (C7i, C8i, M7i, M8i, R7i, R8i, I7i and others, [AWS docs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/amazon-ec2-nested-virtualization.html)). On 2026-10-25 in `us-east-1`, `m7i-flex.large` and `c7i-flex.large` were the only Free Tier eligible types with it. Firecracker's own guide still says to use `.metal` instances; nested virtualization is fine for a lab, and AWS recommends bare metal for performance-sensitive workloads |
| Host OS | **Ubuntu Server 24.04**, x86_64, the OS Firecracker's getting-started guide uses |
| Firecracker | The official release **v1.17.0**, checksum verified |
| Guest kernel | **6.18.54** from Firecracker's CI. 6.18 is a supported guest kernel until 2028 ([kernel policy](https://github.com/firecracker-microvm/firecracker/blob/main/docs/kernel-policy.md)) |
| Guest root filesystem | A **32 MB** ext4 image you build: Ubuntu's static **BusyBox** plus a small **`/init`** script |
| The app | **BusyBox `httpd`**, started by `/init` at boot |
| Access | The **serial console** (to watch the boot) and `curl` from the host. No SSH into the guest, and no HTTP port in the security group |

---

## 1. Launch the host

**Run on:** the AWS Console.

Open **EC2 → Instances → Launch instances**, as in [Lab 1](lab-1.md). Name the instance **`fc-lab`**.

1. AMI: **Ubuntu** → **Ubuntu Server 24.04 LTS**, **64-bit (x86)**. The username is `ubuntu`. The Quick Start may preselect a newer Ubuntu (26.04 in this run): open the AMI list and choose 24.04.

   ![AMI – Ubuntu Server 24.04 LTS – 64-bit (x86) – username ubuntu](images/fc-01-ami-ubuntu.jpg)

2. Instance type: **`m7i-flex.large`** (type it in the search box): 2 vCPUs, 8 GiB, *Free tier eligible*, 0.09576 USD per hour on-demand for Linux.

   ![Instance type m7i-flex.large – Free tier eligible – 2 vCPU – 8 GiB](images/fc-02-instance-type.jpg)

3. Key pair: **Create new key pair** → **`fc-lab-key`**, RSA, `.pem` (as in [Lab 1](lab-1-solution.md#5-key-pair)). Move it to `~/.ssh` and `chmod 400` it.

4. Network settings → **Edit**: VPC **`ecs-vpc`**, subnet **`ecs-public-1a`**, Auto-assign public IP **Enable**. Create security group **`fc-lab-sg`** with **SSH from My IP** only. No other rules: the HTTP test runs on the host itself.

   ![Network settings – ecs-vpc – ecs-public-1a – fc-lab-sg – SSH from My IP](images/fc-03-network-sg.jpg)

5. Storage: keep **8 GiB gp3**.

6. **Advanced details → Nested virtualization → Enabled.** It sits under *CPU options*. This is the important one: without it, the instance has no `/dev/kvm`.

   ![Advanced details – Nested virtualization – Enabled](images/fc-04-nested-virtualization.jpg)

7. **Launch instance**, and wait for **Running** with **3/3 checks passed**. Note the public IPv4 address.

   ![fc-lab – Running – m7i-flex.large – public IPv4 address](images/fc-05-instance-running.jpg)

> With the AWS CLI, nested virtualization is `--cpu-options "NestedVirtualization=enabled"`. To check an instance type: `aws ec2 describe-instance-types --instance-types m7i-flex.large --query "InstanceTypes[].[FreeTierEligible,ProcessorInfo.SupportedFeatures]"`.

## 2. Check KVM on the host

**Run on:** your computer for the SSH command, then **the host** (`fc-lab`) for the rest.

Connect from your computer:

```bash
ssh -i ~/.ssh/fc-lab-key.pem ubuntu@<public-ip>
```

On the host, check that KVM is there:

```bash
lsb_release -ds; uname -r; nproc; free -m | head -2   # the OS, the host kernel, CPUs and memory
ls -l /dev/kvm                         # the KVM device
grep -c -E "vmx|svm" /proc/cpuinfo      # more than 0: the CPU's virtualization flags are visible
lsmod | grep kvm                        # the KVM modules are loaded
```

Expected output (from this run):

```text
Ubuntu 24.04.5 LTS
7.0.0-1014-aws
2
               total        used        free      shared  buff/cache   available
Mem:            7776         502        7166           2         358        7273
crw-rw---- 1 root kvm 10, 232 Oct 25 12:36 /dev/kvm
4
kvm_intel             540672  0
kvm                  1503232  1 kvm_intel
irqbypass              12288  1 kvm
```

`/dev/kvm` exists, the CPU shows its `vmx` flags, and `kvm_intel` is loaded: nested virtualization works.

Still on the host, install the tools and give your user access to KVM:

```bash
sudo apt-get update
sudo apt-get install -y jq busybox-static
sudo usermod -aG kvm ubuntu
exit                                    # log out, then SSH in again so the new group applies
```

## 3. Get Firecracker

**Run on:** the host, after you SSH in again. This step creates the working folder **`~/fc`**; every later step runs in it.

Firecracker is open source on GitHub: [github.com/firecracker-microvm/firecracker](https://github.com/firecracker-microvm/firecracker). Its official builds are on the [releases page](https://github.com/firecracker-microvm/firecracker/releases).

Download the release and **verify its checksum** before you run it:

```bash
mkdir -p ~/fc && cd ~/fc
ARCH=$(uname -m)
VER=v1.17.0
URL=https://github.com/firecracker-microvm/firecracker/releases/download/$VER
curl -fsSLO $URL/firecracker-$VER-$ARCH.tgz
curl -fsSLO $URL/firecracker-$VER-$ARCH.tgz.sha256.txt
sha256sum -c firecracker-$VER-$ARCH.tgz.sha256.txt
tar -xzf firecracker-$VER-$ARCH.tgz
cp release-$VER-$ARCH/firecracker-$VER-$ARCH firecracker
./firecracker --version
```

Expected output:

```text
firecracker-v1.17.0-x86_64.tgz: OK
Firecracker v1.17.0
```

`OK` means the file matches the checksum published with the release.

> The release also contains the **jailer**, which production systems use to sandbox Firecracker. This walkthrough runs Firecracker directly, to keep it simple.

## 4. The guest kernel and root filesystem

**Run on:** the host, in **`~/fc`** (the same session as step 3; if you reconnected, `cd ~/fc` first).

**The guest kernel is not the host kernel.** The host runs Ubuntu's kernel; the microVM boots its own kernel, which you download from Firecracker's CI. It must have the VirtIO drivers for its disk and network built in.

```bash
cd ~/fc
S3=https://s3.amazonaws.com/spec.ccfc.min
KEY=firecracker-ci/20261023-dd7c24b0d165-0/x86_64/vmlinux-6.18.54
curl -fsSLO $S3/$KEY
curl -fsSLO $S3/$KEY.config
grep -E "^CONFIG_(VIRTIO_BLK|VIRTIO_NET|VIRTIO_MMIO|EXT4_FS|SERIAL_8250_CONSOLE)=" vmlinux-6.18.54.config
```

Expected output: all five lines end in `=y`, built into the kernel:

```text
CONFIG_VIRTIO_BLK=y
CONFIG_VIRTIO_NET=y
CONFIG_SERIAL_8250_CONSOLE=y
CONFIG_VIRTIO_MMIO=y
CONFIG_EXT4_FS=y
```

> The CI folder name changes with each build. To find the newest kernels, list the bucket the way Firecracker's [getting-started guide](https://github.com/firecracker-microvm/firecracker/blob/main/docs/getting-started.md) does.

**The root filesystem (rootfs)** is the guest's disk: an ext4 image file on the host. Firecracker doesn't provide a Linux distribution, so you build a minimal one:

- **`/bin/busybox`**: one static binary with `sh`, `mount`, `ip` and `httpd`.
- **`/init`**: the first process the kernel starts (PID 1). Here it mounts `/proc` and `/sys`, configures `eth0`, writes a web page and **becomes the web server** with `exec`.

```bash
cd ~/fc
mkdir -p rootfs/bin rootfs/dev rootfs/proc rootfs/sys rootfs/www
cp /bin/busybox rootfs/bin/busybox
ln -s busybox rootfs/bin/sh

cat > rootfs/init <<'EOF'
#!/bin/sh
# The first process the guest kernel starts (PID 1)
echo "init: mounting /proc and /sys"
/bin/busybox mount -t proc proc /proc
/bin/busybox mount -t sysfs sysfs /sys
echo "init: eth0 = 172.16.0.2/30"
/bin/busybox ip link set lo up
/bin/busybox ip addr add 172.16.0.2/30 dev eth0
/bin/busybox ip link set eth0 up
echo "<h1>Hello from Firecracker</h1><p>Guest kernel: $(/bin/busybox uname -r)</p>" > /www/index.html
echo "init: starting httpd on port 80"
exec /bin/busybox httpd -f -p 80 -h /www
EOF
chmod +x rootfs/init

sudo chown -R root:root rootfs
truncate -s 32M rootfs.ext4
sudo mkfs.ext4 -q -d rootfs -F rootfs.ext4
sudo chown ubuntu:ubuntu rootfs.ext4
sudo find rootfs | sort
ls -lh vmlinux-6.18.54 rootfs.ext4
```

> **Why `exec`?** PID 1 must never exit: if it does, the kernel panics. `exec` replaces the script with `httpd`, so the web server becomes PID 1 and keeps running.

Expected output: the whole rootfs is BusyBox, a `sh` link, `/init` and four empty folders, in a 32 MB image:

```text
rootfs
rootfs/bin
rootfs/bin/busybox
rootfs/bin/sh
rootfs/dev
rootfs/init
rootfs/proc
rootfs/sys
rootfs/www
-rw-rw-r-- 1 ubuntu ubuntu 32M Oct 25 12:39 rootfs.ext4
-rw-rw-r-- 1 ubuntu ubuntu 27M Oct 25 12:38 vmlinux-6.18.54
```

## 5. Host networking: a TAP device

**Run on:** the host (any folder).

The guest's virtual network card (virtio-net) is connected to a **TAP device**: a virtual network interface on the host. The host gets `172.16.0.1`, the guest `172.16.0.2`, in a tiny `/30` subnet. No NAT and no default route here: the guest only talks to the host.

```bash
sudo ip tuntap add dev tap0 mode tap user ubuntu      # owned by ubuntu, so Firecracker can run without sudo
sudo ip addr add 172.16.0.1/30 dev tap0
sudo ip link set dev tap0 up
ip -br addr show tap0
```

Expected output (DOWN until Firecracker attaches to it in step 6):

```text
tap0             DOWN           172.16.0.1/30
```

## 6. Configure and start the microVM through the API

**Run on:** the host, in **`~/fc`**, in **two SSH sessions**. Open a second terminal on your computer and SSH to the host again.

Firecracker is configured through an **HTTP API on a Unix socket**: a local file on the host, not a network port.

**Terminal 1:** start Firecracker. It waits for API calls, and later shows the guest's **serial console**. Leave it running.

```bash
cd ~/fc
rm -f /tmp/firecracker.socket
./firecracker --api-sock /tmp/firecracker.socket
```

Expected output (in terminal 1):

```text
2026-10-25T12:39:51.137535895 [anonymous-instance:main] Running Firecracker v1.17.0
2026-10-25T12:39:51.137647465 [anonymous-instance:main] Listening on API socket ("/tmp/firecracker.socket").
2026-10-25T12:39:51.137830591 [anonymous-instance:fc_api] API server started.
```

**Terminal 2:** define a small helper, check the state, then configure the microVM. **All the configuration comes before the start.**

```bash
cd ~/fc
api() { curl -s -w "HTTP %{http_code}\n" -X "$1" --unix-socket /tmp/firecracker.socket \
          -H "Content-Type: application/json" -d "$3" "http://localhost/$2"; }

curl -s --unix-socket /tmp/firecracker.socket http://localhost/ | jq .

api PUT boot-source '{"kernel_image_path": "./vmlinux-6.18.54", "boot_args": "console=ttyS0 reboot=k panic=1 init=/init"}'
api PUT drives/rootfs '{"drive_id": "rootfs", "path_on_host": "./rootfs.ext4", "is_root_device": true, "is_read_only": false}'
api PUT machine-config '{"vcpu_count": 1, "mem_size_mib": 256}'
api PUT network-interfaces/eth0 '{"iface_id": "eth0", "host_dev_name": "tap0"}'
```

Expected output (in terminal 2): the state is **Not started**, and each configuration call returns **HTTP 204** (success, no content):

```text
{
  "id": "anonymous-instance",
  "state": "Not started",
  "vmm_version": "1.17.0",
  "app_name": "Firecracker"
}
HTTP 204
HTTP 204
HTTP 204
HTTP 204
```

The boot arguments: `console=ttyS0` sends the kernel's output to the serial console, `init=/init` runs your script, and `reboot=k panic=1` make a crash end the microVM instead of hanging.

**Start it** (terminal 2):

```bash
api PUT actions '{"action_type": "InstanceStart"}'
```

Watch **terminal 1**: the guest kernel boots, mounts the rootfs and runs `/init`. Expected output (trimmed):

```text
[    0.000000] Linux version 6.18.54+ … #1 SMP PREEMPT_DYNAMIC
[    0.000000] Command line: console=ttyS0 reboot=k panic=1 init=/init pci=off root=/dev/vda rw virtio_mmio.device=4K@0xc0001000:5 virtio_mmio.device=4K@0xc0002000:6
[    0.000000] Hypervisor detected: KVM
[    0.432303] virtio_blk virtio0: [vda] 65536 512-byte logical blocks (33.6 MB/32.0 MiB)
[    0.439972] virtio_net virtio1: Assigned random MAC address 42:06:3c:ab:d3:d4
[    0.957585] EXT4-fs (vda): mounted filesystem … r/w with ordered data mode.
[    0.968286] Run /init as init process
init: mounting /proc and /sys
init: eth0 = 172.16.0.2/30
init: starting httpd on port 80
```

Firecracker added `root=/dev/vda` and the `virtio_mmio.device=` entries to the kernel command line itself. In this run `/init` started about **0.97 s** after the kernel started, and the first HTTP answer came **1,222 ms** after `InstanceStart`.

## 7. Reach the app, then pause and resume

**Run on:** the host, in **terminal 2** (terminal 1 keeps running Firecracker).

```bash
curl http://172.16.0.2/
uname -r
curl -s --unix-socket /tmp/firecracker.socket http://localhost/ | jq -r .state
ps -o pid,rss,cmd -C firecracker
```

Expected output:

```text
<h1>Hello from Firecracker</h1><p>Guest kernel: 6.18.54+</p>
7.0.0-1014-aws
Running
    PID   RSS CMD
   2190 58352 ./firecracker --api-sock /tmp/firecracker.socket
```

The guest kernel is **6.18.54**, while the host runs **7.0.0-1014-aws**: two different kernels on the same machine. The Firecracker process used about **57 MiB** of resident memory (RSS, which `ps` shows in KiB), including the guest pages it touched, although the guest has 256 MiB: guest memory is backed on demand.

### Pause and resume (advanced exercise)

**Run on:** terminal 2.

```bash
api PATCH vm '{"state": "Paused"}'
curl -s --unix-socket /tmp/firecracker.socket http://localhost/ | jq -r .state
curl -s -m 3 http://172.16.0.2/ || echo "no answer within 3 s (exit $?)"
api PATCH vm '{"state": "Resumed"}'
curl -s --unix-socket /tmp/firecracker.socket http://localhost/ | jq -r .state
curl http://172.16.0.2/
```

Expected output:

```text
HTTP 204
Paused
no answer within 3 s (exit 28)
HTTP 204
Running
<h1>Hello from Firecracker</h1><p>Guest kernel: 6.18.54+</p>
```

While paused, `curl` gets no answer (exit code 28, a timeout). After Resume, the same page comes back from the same IP.

Answer these:
- What happens to HTTP requests while the microVM is paused?
- Does the guest keep its IP address after Resume?
- What's the difference between Pause, Stop and Snapshot?

### Bonus: a snapshot

A snapshot saves the paused microVM's state and memory to files, so a new Firecracker process can resume it without booting.

**Terminal 2:** pause, create the snapshot, then stop Firecracker:

```bash
api PATCH vm '{"state": "Paused"}'
api PUT snapshot/create '{"snapshot_type": "Full", "snapshot_path": "./vm.snap", "mem_file_path": "./vm.mem"}'
ls -lh vm.snap vm.mem
pkill -x firecracker
```

Expected output: a 15 KB state file and a memory file as large as the guest's RAM. Terminal 1 returns to the prompt: the microVM is gone.

```text
HTTP 204
HTTP 204
-rw-rw-r-- 1 ubuntu ubuntu 256M Oct 25 12:40 vm.mem
-rw-rw-r-- 1 ubuntu ubuntu  15K Oct 25 12:40 vm.snap
```

**Terminal 1:** start a new Firecracker process:

```bash
rm -f /tmp/firecracker.socket
./firecracker --api-sock /tmp/firecracker.socket
```

**Terminal 2:** load the snapshot, and the page answers again:

```bash
api PUT snapshot/load '{"snapshot_path": "./vm.snap", "mem_backend": {"backend_type": "File", "backend_path": "./vm.mem"}, "resume_vm": true}'
curl http://172.16.0.2/
```

```text
HTTP 204
<h1>Hello from Firecracker</h1><p>Guest kernel: 6.18.54+</p>
```

The snapshot doesn't contain the disk: the restored microVM uses the same `rootfs.ext4` and `tap0`, so keep them.

In this run, from `snapshot/load` to the HTTP answer took **45 ms**, compared with about 1.1 s for a cold boot. This is the idea behind **Lambda SnapStart**: restore an initialized environment instead of booting a new one.

### Advanced: make it boot faster

**Run on:** terminals 1 and 2, as in step 6.

Measure how long it takes from `InstanceStart` to the first HTTP answer, then add `quiet` to the boot arguments (less console output), and then also `i8042.noaux i8042.nomux i8042.nopnp i8042.dumbkbd` (skip probing the keyboard controller, as Firecracker's own boot-time tests do).

For each run: stop Firecracker, start a fresh process in terminal 1, and send the four configuration calls from step 6 again, with the new `boot_args`. Then start and measure in terminal 2 (this loop tries `curl` up to 100 times):

```bash
t0=$(date +%s%N)
api PUT actions '{"action_type": "InstanceStart"}'
for i in $(seq 1 100); do curl -s -m 1 http://172.16.0.2/ >/dev/null && break; sleep 0.05; done
echo "$(( ($(date +%s%N) - t0) / 1000000 )) ms to the first HTTP answer"
```

Measured in this run (`m7i-flex.large`, nested virtualization):

| Boot arguments | InstanceStart → first HTTP answer |
|---|---|
| `console=ttyS0 reboot=k panic=1 init=/init` | about 1,100 ms |
| … `quiet` | about 735 ms |
| … `quiet i8042.noaux i8042.nomux i8042.nopnp i8042.dumbkbd` | about 275 ms |

- **`quiet`** saved about 0.4 s: printing hundreds of kernel lines to the emulated serial port is slow.
- **The `i8042` options** saved about another 0.45 s: the kernel no longer probes the keyboard controller.
- The published **≤ 125 ms** (to `/sbin/init`) is measured on bare-metal hosts with the serial console fully disabled (`8250.nr_uarts=0`). This run used nested virtualization, and measured up to the first HTTP answer.

## 8. Clean up

**Run on:** the host for the first commands, then the AWS Console (or CloudShell).

On the host:

```bash
pkill -x firecracker          # stop the microVM
sudo ip link del tap0         # remove the TAP device
exit                          # in both terminals
```

In the AWS Console:

- **Terminate** the `fc-lab` instance (see [Lab 2, step 6](lab-2.md#6-stop-and-terminate-the-instance)).
- Delete the security group **`fc-lab-sg`**, the key pair **`fc-lab-key`**, and `fc-lab-key.pem` on your computer.
- Keep `ecs-vpc`.

With the AWS CLI (for example in CloudShell):

```bash
ID=$(aws ec2 describe-instances --filters Name=tag:Name,Values=fc-lab Name=instance-state-name,Values=running,stopped \
  --query 'Reservations[0].Instances[0].InstanceId' --output text)
aws ec2 terminate-instances --instance-ids $ID
aws ec2 wait instance-terminated --instance-ids $ID
aws ec2 delete-security-group --group-id $(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=fc-lab-sg --query 'SecurityGroups[0].GroupId' --output text)
aws ec2 delete-key-pair --key-name fc-lab-key
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| No `/dev/kvm` | Nested virtualization isn't enabled, or the instance type doesn't support it | Stop the instance → **Actions → Instance settings → Change CPU options → Nested virtualization: Enable**, or relaunch on a supported type |
| `Permission denied` on `/dev/kvm` | Your user isn't in the `kvm` group yet | `sudo usermod -aG kvm ubuntu`, then log out and in |
| Firecracker can't open `tap0` | The TAP device belongs to root | Recreate it with `user ubuntu` |
| `Kernel panic` during boot | The rootfs, `root=` or `/init` is wrong (not executable, no `/bin/sh`) | Check the boot arguments, `chmod +x rootfs/init`, and rebuild the image |
| `curl` to `172.16.0.2` fails | TAP, IP addresses or the HTTP server | Check each layer: `ip -br addr show tap0` on the host, and the `init:` lines on the serial console |
| `Address in use` when starting Firecracker | An old socket file | `rm -f /tmp/firecracker.socket` |

> **Host kernel:** this Ubuntu AMI runs host kernel **7.0**, which isn't in Firecracker's validated host list (5.10, 6.1, 6.18). It worked in this run. For a validated host kernel, Amazon Linux 2023 offers kernel 6.18.

## Check yourself

1. Why does Firecracker need access to KVM?
2. What's the difference between the guest kernel and the root filesystem?
3. What does the TAP interface do?
4. What's the difference between Pause and Snapshot?

<details>
<summary><b>Answers</b></summary>

1. **Why KVM?** Firecracker is only the VMM: it sets up the machine and its devices. **KVM**, in the host kernel, runs the guest's code directly on the CPU with hardware virtualization (Intel VT-x / AMD-V) and handles VM exits. Without `/dev/kvm` there's nothing to run the guest on. That's why this walkthrough needs nested virtualization (or bare metal).
2. **Guest kernel vs. root filesystem:** the **guest kernel** (`vmlinux-6.18.54`) is the core of the guest OS: it manages the vCPU, memory and the virtio devices. The **root filesystem** (`rootfs.ext4`) is the guest's disk: the files and programs (`/init`, BusyBox, the web page). Firecracker loads the kernel straight into guest memory and attaches the rootfs as the virtio-block device `vda`.
3. **The TAP interface** is a virtual network card on the host. Firecracker connects the guest's virtio-net `eth0` to it, so packets the guest sends appear on `tap0` (`172.16.0.1`), and the other way round.
4. **Pause vs. snapshot:** **Pause** stops the vCPUs and device emulation, but the microVM stays in the same process and memory: Resume continues at once. A **snapshot** writes the paused microVM's state and memory to files, so a different Firecracker process, even later or on a compatible host, can load it and continue without a cold boot. Neither is a shutdown.

</details>

---

## What's next?

Back to the [3.01 EC2 chapter](README.md), or on to [3.02 Storage](../3.02-storage/README.md).

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
