#!/bin/bash

PASSWORD="SomeSecurePassword"

HOME_DIR="/home/scanadmin"

echo '> Creating scanadmin user...'
# Add scanadmin group
groupadd scanadmin

# Set up a scanadmin user and add the insecure key for User to login
useradd -G scanadmin -m scanadmin

echo '> Setting scanadmin password to never expire...'
# Avoid password expiration (https://github.com/vmware/photon-packer-templates/issues/2)
chage -I -1 -m 0 -M 99999 -E -1 scanadmin

echo '> Adding scanadmin to sudoers file...'
# Configure a sudoers for the scanadmin user
echo "scanadmin ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/scanadmin

echo '> Setting password for scanadmin user...'
# Set scanadmin password
echo -e "$PASSWORD\n$PASSWORD" | passwd scanadmin

echo '> Setting global path environment variable for users...'
# Set global path
echo "PATH=/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" >> /etc/environment

echo '> Adding scanadmin user to docker group...'
# Add Photon user to Docker group
usermod -a -G docker scanadmin