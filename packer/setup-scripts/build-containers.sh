#!/bin/bash

echo '> Pulling scanner-autobuild git repo and submodules...'
# download dod-compliance-and-automation git repository to build containers
git clone https://github.com/mitre/heimdall2.git
git clone https://github.com/1computerguy/dod-compliance-and-automation.git

echo '> Building and configuring heimdall visualization...'
pushd heimdall2
./setup-docker-secrets.sh
docker-compose up -d
popd

echo '> Building and configuring dod scanner...'
mv ./dod-compliance-and-automation ./scanner-autobuild/docker/inspec
pushd ./scanner-autobuild/docker/inspec
docker build . --tag inspec-pwsh
popd

pushd ./scanner-autobuild/docker/ansible
docker build . --tag ansible
popd

docker pull mitre/inspec_tools

echo '> Making scan and remediate scripts executable...'
# Setup scan and remediate automation scripts
chmod +x /usr/local/bin/{scan,remediate,exports}

echo '> Removing initial build containers (no longer required)...'
# Remove build containers
docker rmi {chef/inspec,alpine:3.11}
