#!/bin/bash
# Boots a fresh copy of the base image and runs the same checks as the video. Prints PASS or FAIL per check.
source "$(dirname "$0")/common.sh"
set +e
pass=0; fail=0
ok() { if eval "$2" >/dev/null 2>&1; then echo "PASS  $1"; pass=$((pass+1)); else echo "FAIL  $1"; fail=$((fail+1)); fi; }

step "check.sh: a fresh copy of the base image"
cp --sparse=always ubuntu-docker-base.ext4 job.ext4
sed 's/"ubuntu.ext4"/"job.ext4"/' vm.json > vm-job.json
rm -f /tmp/fc-job.socket
nohup ./firecracker --api-sock /tmp/fc-job.socket --config-file vm-job.json > console-job.log 2>&1 &
ok "the guest boots and answers on SSH" "wait_ssh"
ok "Ubuntu 24.04 inside"                 "ssh root@$GUEST 'grep -q 24.04 /etc/os-release'"
ok "DNS from the guest"                  "ssh root@$GUEST 'resolvectl query github.com'"
ok "HTTPS from the guest"                "[ \"\$(ssh root@$GUEST \"curl -sS -o /dev/null -w '%{http_code}' https://github.com\")\" = 200 ]"
ok "Docker is running"                   "ssh root@$GUEST 'systemctl is-active docker'"
ok "a container runs"                    "ssh root@$GUEST 'docker run --rm alpine true'"
ok "DNS and HTTPS from a container"      "ssh root@$GUEST 'docker run --rm alpine wget -qO- https://api.github.com/zen'"
ok "no instance metadata from the guest" "! ssh root@$GUEST 'curl -s -m 3 http://169.254.169.254/'"
ssh root@$GUEST reboot >/dev/null 2>&1; wait_exit; rm -f job.ext4 vm-job.json
echo; echo "check.sh: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
