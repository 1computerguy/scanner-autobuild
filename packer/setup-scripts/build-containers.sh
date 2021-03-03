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
svn export https://github.com/1computerguy/scanner-autobuild.git/trunk/docker
mv ./dod-compliance-and-automation ./docker/inspec
pushd ./docker/inspec
docker build . --tag inspec-pwsh
mv ./dod-compliance-and-automation ../ansible
popd

echo '> Building ansible remediation container...'
pushd ./docker/ansible
docker build . --tag ansible
popd

echo '> cleaning up and pulling inspec_tools container...'
rm -rf ./docker
docker pull mitre/inspec_tools
