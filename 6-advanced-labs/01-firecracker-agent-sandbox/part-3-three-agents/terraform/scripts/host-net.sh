#!/bin/bash
# tap0 and NAT on the host, the same block as Part 2's boot-guest.sh, but only when tap0 is missing (after a host
# reboot). Every job uses tap0 and the guest address 172.16.0.2; run-job.sh calls this first.
set -euo pipefail
ip link show tap0 >/dev/null 2>&1 && exit 0
sudo ip tuntap add dev tap0 mode tap user ubuntu
sudo ip addr add 172.16.0.1/30 dev tap0 && sudo ip link set dev tap0 up
sudo sysctl -q -w net.ipv4.ip_forward=1
OUT=$(ip route show default | awk '{print $5}')
sudo iptables -t nat -A POSTROUTING -o $OUT -j MASQUERADE
sudo iptables -A FORWARD -i tap0 -o $OUT -j ACCEPT
sudo iptables -A FORWARD -i $OUT -o tap0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -I FORWARD -i tap0 -d 169.254.169.254 -j DROP   # the guest never reaches the instance metadata
echo "tap0 and NAT are up"
