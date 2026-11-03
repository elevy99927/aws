#!/bin/bash
# user-data: runs once, as root, at the instance's first boot (Ubuntu).
# Installs Docker and runs nginx in a container on port 80.
apt-get update
apt-get install -y docker.io
systemctl enable --now docker
docker run -d --name nginx --restart unless-stopped -p 80:80 nginx



#mkdir -p /usr/share/nginx/html
#echo "<h1>Hello from $(hostname)</h1><p>Served by nginx in Docker</p>" > /usr/share/nginx/html/index.html

#docker run -d --name nginx --restart unless-stopped -p 80:80 \
#  -v /usr/share/nginx/html:/usr/share/nginx/html:ro \
#  nginx