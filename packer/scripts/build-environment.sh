#!/bin/bash

# download dod-compliance-and-automation git repository to build containers
git clone https://github.com/1computerguy/dod-compliance-and-automation.git

# Pull Heimdall for visualization
git clone https://github.com/mitre/heimdall.git

pushd heimdall
./setup-docker-secrets.sh
docker-compose up -d
docker-compose run --rm web rake db:create db:migrate
popd

# Build Scan and Remediate containers
pushd dod-compliance-and-automation

# Build Chef InSpec container
docker build . -f docker/Docker-chef --tag inspec-pwsh

# Build Ansible container
docker build . -f docker/Dockerfile-ansible --tag docker-ansible

# Setup scan and remediate automation scripts
pushd scripts
cp scan.sh /usr/local/bin/scan
cp remediate.sh /usr/local/bin/remediate
chmod +x /usr/local/bin/{scan,remediate}

popd

# Remove build containers
docker rmi {chef/inspec,alpine:3.11}
