#!/bin/bash

# Build Chef InSpec container
docker build . --tag inspec-pwsh

# Build Ansible container
docker build . -f Dockerfile-ansible --tag docker-ansible

# Install docker-compose to manage Heimdall
curl -L "https://github.com/docker/compose/releases/download/1.27.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Pull and setup and start Heimdall visualization on port 3000
git clone https://github.com/mitre/heimdall.git

pushd heimdall
./setup-docker-secrets.sh
docker-compose up -d
docker-compose run --rm web rake db:create db:migrate

popd

# Setup scan and remediation scripts
pushd scripts
cp scan.sh /usr/local/bin/scan
cp remediate.sh /usr/local/bin/remediate
chmod +x /usr/local/sbin/{scan,remediate}

popd

# Remove build containers
docker rmi {chef/inspec,alpine:3.11}

exit 0