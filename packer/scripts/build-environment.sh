#!/bin/bash

echo '> Pulling scanner-autobuild git repo and submodules...'
# download dod-compliance-and-automation git repository to build containers
git clone https://github.com/1computerguy/scanner-autobuild.git
git submodule update --init --recursive

echo '> Building and configuring heimdall visualization...'
pushd scanner-autobuild/heimdall
./setup-docker-secrets.sh
docker-compose up -d
docker-compose run --rm web rake db:create db:migrate
popd

echo '> Building Chef-inspec container...'
# Build Scan and Remediate containers
pushd docker

# Build Chef InSpec container
docker build . -f docker/Docker-chef --tag inspec-pwsh

echo '> Building Ansible container...'
# Build Ansible container
docker build . -f docker/Dockerfile-ansible --tag docker-ansible

echo '> Setting up scan and remediate scripts...'
# Setup scan and remediate automation scripts
pushd scripts
cp scan.sh /usr/local/bin/scan
cp remediate.sh /usr/local/bin/remediate
chmod +x /usr/local/bin/{scan,remediate}
popd

echo '> Removing initial build containers (no longer required)...'
# Remove build containers
docker rmi {chef/inspec,alpine:3.11}
