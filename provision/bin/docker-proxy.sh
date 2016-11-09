#!/usr/bin/env bash
#
# Configure proxy settings for Docker daemon
# https://docs.docker.com/engine/admin/systemd/#http-proxy
# 

set -o errexit
set -o nounset
set -o pipefail

mkdir /etc/systemd/system/docker.service.d

sudo tee -a /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=$1"
Environment="HTTPS_PROXY=$2"
Environment="NO_PROXY=$3"
EOF 

systemctl daemon-reload

echo 'Docker daemon proxy settings:'
systemctl show --property=Environment docker

systemctl restart docker
