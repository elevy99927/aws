#!/bin/bash
# Boot the Part 2 base image, copy the agents folder in, pull the three images, bake what the scanners would
# download at run time (the Trivy database, the Semgrep rule sets), install git, shut down, and keep the disk as
# ubuntu-agents-base.ext4: the base image, version 2. Every job starts from a copy of it.
source "$(dirname "$0")/common.sh"

step "Boot a copy of the Part 2 base image, grown to 8 GiB: the agents need room"
./host-net.sh
run 'cp --sparse=always ubuntu-docker-base.ext4 bake.ext4'
run 'truncate -s 8G bake.ext4 && sudo e2fsck -fp bake.ext4 > /dev/null && sudo resize2fs bake.ext4 2>&1 | tail -1'
run 'sed "s/\"ubuntu.ext4\"/\"bake.ext4\"/" vm.json > vm-bake.json'
run 'rm -f /tmp/fc-bake.socket'
run 'nohup ./firecracker --api-sock /tmp/fc-bake.socket --config-file vm-bake.json > console-bake.log 2>&1 &'
wait_ssh

step "git in the guest: the clone runs there, never on the host"
guest 'apt-get update -qq && apt-get install -y -qq git > /dev/null && git --version'

step "The agents folder, and the three images"
run 'scp -rq agents root@172.16.0.2:/opt/agents'
guest 'cd /opt/agents && for i in $(docker compose config --images); do docker pull -q $i; done && docker image ls --format "{{.Repository}}:{{.Tag}}  {{.Size}}"'

step "Bake what the scanners would download at run time"
guest 'docker run --rm -v /opt/agents/trivy-cache:/root/.cache/trivy aquasec/trivy:0.76.2 image --download-db-only --quiet && du -sh /opt/agents/trivy-cache'
guest 'df -h / | tail -1'
guest 'for p in supply-chain security-audit; do curl -fsSL https://semgrep.dev/c/p/$p -o /opt/agents/rules/p-$p.yaml; done; ls -l /opt/agents/rules'
guest 'cd /opt/agents && docker compose config --quiet && echo "compose.yaml is valid"'

step "Shut down, and keep the base image, version 2"
printf '\nguest$ reboot\n'; ssh root@$GUEST reboot || true
wait_exit
run 'mv bake.ext4 ubuntu-agents-base.ext4 && rm -f vm-bake.json'
run 'ls -lsh ubuntu*.ext4'
