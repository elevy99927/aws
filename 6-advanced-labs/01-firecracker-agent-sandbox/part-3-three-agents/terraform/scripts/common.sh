#!/bin/bash
# Shared by the lab scripts. They run on the host as ubuntu, in ~/fc. Each command is printed before its output
# ("$ ..." on the host, "guest$ ..." inside the guest), so the logs read like the terminal in the video.
set -euo pipefail
cd "$HOME/fc"
GUEST=172.16.0.2
run()   { printf '\n$ %s\n' "$1"; eval "$1"; }
guest() { printf '\nguest$ %s\n' "$1"; ssh root@$GUEST "$1"; }
step()  { printf '\n#### %s\n' "$1"; }

# Wait until the guest answers on SSH (Ubuntu takes a few seconds to boot).
wait_ssh() {
  for _ in $(seq 1 120); do ssh -o ConnectTimeout=2 root@$GUEST true 2>/dev/null && return 0; sleep 2; done
  echo "the guest did not answer on SSH"; return 1
}

# Wait until the Firecracker process has exited (after a reboot inside the guest).
wait_exit() {
  for _ in $(seq 1 60); do pgrep -x firecracker >/dev/null || return 0; sleep 1; done
  echo "firecracker is still running"; return 1
}
