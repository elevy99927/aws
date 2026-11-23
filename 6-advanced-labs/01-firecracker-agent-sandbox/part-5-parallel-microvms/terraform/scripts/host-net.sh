#!/bin/bash
# Part 5: four network slots on the host, tap0-tap3, made before any job arrives. Slot N gets its own /30:
# the host side is 172.16.0.(4N+1), the guest 172.16.0.(4N+2). A TAP can be attached to one microVM only, so
# one slot = one running microVM. run-job.sh calls this first; it only adds what's missing (after a reboot).
set -euo pipefail
SLOTS=4
for N in $(seq 0 $((SLOTS-1))); do
  ip link show tap$N >/dev/null 2>&1 && continue
  sudo ip tuntap add dev tap$N mode tap user ubuntu
  sudo ip addr add 172.16.0.$((4*N+1))/30 dev tap$N
  sudo ip link set dev tap$N up
done

# The rules name tap+ (every TAP), not tap0. Each one is added once.
sudo sysctl -q -w net.ipv4.ip_forward=1
OUT=$(ip route show default | awk '{print $5}')
add() { sudo iptables -C "$@" 2>/dev/null || sudo iptables -A "$@"; }   # append if missing
top() { sudo iptables -C "$@" 2>/dev/null || sudo iptables -I "$@"; }   # insert at the top if missing
add POSTROUTING -t nat -o $OUT -j MASQUERADE
add FORWARD -i tap+ -o $OUT -j ACCEPT
add FORWARD -i $OUT -o tap+ -m state --state RELATED,ESTABLISHED -j ACCEPT
top FORWARD -i tap+ -d 169.254.169.254 -j DROP   # no guest reaches the instance metadata
top FORWARD -i tap+ -o tap+ -j DROP              # no guest reaches another guest
echo "tap0-tap$((SLOTS-1)) and NAT are up"
