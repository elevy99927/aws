#!/bin/bash
# TAP and NAT on the host, then boot Ubuntu from a Firecracker config file.
source "$(dirname "$0")/common.sh"

step "TAP and NAT on the host"
run 'sudo ip tuntap add dev tap0 mode tap user ubuntu'
run 'sudo ip addr add 172.16.0.1/30 dev tap0 && sudo ip link set dev tap0 up'
run 'sudo sysctl -w net.ipv4.ip_forward=1'
run "OUT=\$(ip route show default | awk '{print \$5}'); echo \$OUT"
run 'sudo iptables -t nat -A POSTROUTING -o $OUT -j MASQUERADE'
run 'sudo iptables -A FORWARD -i tap0 -o $OUT -j ACCEPT'
run 'sudo iptables -A FORWARD -i $OUT -o tap0 -m state --state RELATED,ESTABLISHED -j ACCEPT'
run 'sudo iptables -I FORWARD -i tap0 -d 169.254.169.254 -j DROP   # the guest never reaches the instance metadata'

step "Boot Ubuntu with a config file"
cat > vm.json <<'J'
{
  "boot-source": {"kernel_image_path": "vmlinux-6.18.54", "boot_args": "console=ttyS0 reboot=k panic=1 root=/dev/vda rw"},
  "drives": [{"drive_id": "rootfs", "path_on_host": "ubuntu.ext4", "is_root_device": true, "is_read_only": false}],
  "machine-config": {"vcpu_count": 2, "mem_size_mib": 2048},
  "network-interfaces": [{"iface_id": "eth0", "host_dev_name": "tap0"}]
}
J
run 'cat vm.json'
run 'rm -f /tmp/firecracker.socket'
run 'nohup ./firecracker --api-sock /tmp/firecracker.socket --config-file vm.json > console.log 2>&1 &'
wait_ssh
run 'grep -a -E "Linux version|Reached target|login:" console.log | head -20'
