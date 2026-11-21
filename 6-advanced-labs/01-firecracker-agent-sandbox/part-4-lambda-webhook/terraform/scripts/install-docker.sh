#!/bin/bash
# SSH tests, Docker Engine and Compose inside the guest, and three container tests.
source "$(dirname "$0")/common.sh"

step "SSH in, DNS and HTTPS out"
run "ssh root@172.16.0.2 'head -2 /etc/os-release; ip -br addr'"
run "ssh root@172.16.0.2 'resolvectl query github.com'"
run "ssh root@172.16.0.2 \"curl -sS -o /dev/null -w '%{http_code}\\n' https://github.com\""

step "Install Docker Engine and Compose"
guest 'curl -fsSL https://get.docker.com | sh > /root/docker-install.log 2>&1; tail -3 /root/docker-install.log'
guest 'systemctl is-active docker'
guest "docker version --format '{{.Server.Version}}'"
guest 'docker compose version'
guest "docker info --format 'cgroup v{{.CgroupVersion}}, storage {{.Driver}}'"

step "A container, a volume, and a way out"
guest "docker run --rm -v jobdata:/data alpine sh -c 'echo hello from a container > /data/hello.txt'"
guest 'docker run --rm -v jobdata:/data alpine cat /data/hello.txt'
guest 'docker run --rm alpine wget -qO- https://api.github.com/zen'
