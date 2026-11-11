#!/bin/bash

sudo apt update
sudo apt install openssh-server -y
sudo systemctl start ssh
sudo systemctl enable --now ssh


sudo apt install docker.io -y
sudo systemctl start docker 
sudo systemctl enable --now docker
sudo docker run -itd -p 80:80 nginx