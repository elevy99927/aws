#!/bin/bash
# user-data: cloud-init runs this as root, once, at the instance's first boot.
dnf install -y nginx
echo "<h1>Hello from $(hostname)</h1><p>Installed by user-data</p>" \
  > /usr/share/nginx/html/index.html
systemctl enable --now nginx
