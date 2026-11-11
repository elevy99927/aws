#!/bin/bash
set -e

KEY_DIR="./ssh"
KEY_NAME="terraform-key"

mkdir -p ${KEY_DIR}

if [ ! -f "${KEY_DIR}/${KEY_NAME}" ]; then
  ssh-keygen -t rsa -b 4096 \
    -f ${KEY_DIR}/${KEY_NAME} \
    -N ""
  chmod 600 ${KEY_DIR}/${KEY_NAME}
fi
echo "SSH key pair generated at ${KEY_DIR}/${KEY_NAME} and ${KEY_DIR}/${KEY_NAME}.pub"
