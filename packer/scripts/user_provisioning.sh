#!/bin/sh

PASSWORD="SomeSecurePassword"

HOME_DIR="/home/scanadmin"

# Add scanadmin group
groupadd scanadmin

# Set up a scanadmin user and add the insecure key for User to login
useradd -G scanadmin -m scanadmin

# Avoid password expiration (https://github.com/vmware/photon-packer-templates/issues/2)
chage -I -1 -m 0 -M 99999 -E -1 scanadmin
chage -I -1 -m 0 -M 99999 -E -1 root

# Configure a sudoers for the scanadmin user
echo "scanadmin ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/scanadmin

# Set scanadmin password
echo -e "$PASSWORD\n$PASSWORD" | passwd scanadmin

# Add Docker group
groupadd docker

# Add Photon user to Docker group
usermod -a -G docker scanadmin