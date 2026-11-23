#!/bin/bash
# Clean up, shut the guest down, and keep its disk as the base image.
source "$(dirname "$0")/common.sh"

step "Shut down, and keep the base image"
guest 'docker volume rm jobdata'
printf '\nguest$ reboot\n'; ssh root@$GUEST reboot || true
wait_exit
run 'tail -2 console.log'
run 'cp --sparse=always ubuntu.ext4 ubuntu-docker-base.ext4'
run 'ls -lsh ubuntu*.ext4'
