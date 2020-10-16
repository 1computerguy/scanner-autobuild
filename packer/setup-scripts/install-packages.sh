#!/bin/sh

#tdnf --assumeyes update && tdnf --assumeyes upgrade
echo '> Download and install docker-compose...'
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo '> Enable docker service to start on boot...'
systemctl enable docker
systemctl start docker
