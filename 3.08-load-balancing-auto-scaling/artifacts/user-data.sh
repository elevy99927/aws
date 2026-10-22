#!/bin/bash
dnf install -y docker
systemctl enable --now docker
docker run -d --restart always --name echo -p 80:5678 \
  hashicorp/http-echo -text="Container Hostname: $HOSTNAME"
