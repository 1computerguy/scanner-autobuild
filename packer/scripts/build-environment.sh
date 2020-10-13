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
docker build . -tag inspec-pwsh
docker build . -f Dockerfile-ansible -tag ansible

# Setup scan and remediate automation scripts
pushd scripts
cp scan.sh /usr/local/bin/scan
cp remediate.sh /usr/local/bin/remediate
chmod +x /usr/local/bin/{scan,remediate}

popd

# Remove build containers
docker rmi {chef/inspec,alpine:3.11}
