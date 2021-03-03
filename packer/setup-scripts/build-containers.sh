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
popd

pushd ./docker/ansible
docker build . --tag ansible
popd

docker pull mitre/inspec_tools

