#!/bin/bash -eux

##
## cleanup everything we can to make the OVA as small as possible
##

echo '> Enable setup script to configure system on intial boot...'
systemctl daemon-reload
systemctl enable setup

# Set startup script permissions
chmod +x /root/setup.sh

# Remove packages and clear tdnf cache
echo '> Removing unnecessary packages...'
tdnf --assumeyes remove \
                 openldap \
                 cyrus-sasl \
                 serf \
                 subversion \
                 apr \
                 utf8proc \
                 apr-util \
                 subversion-perl \
                 python2-libs \
                 python2 perl \
                 perl-DBI \
                 perl-YAML \
                 perl-CGI \
                 subversion

echo '> Clearing tdnf cache...'
tdnf clean all

# Cleanup log files
echo '> Removing Log files...'
cat /dev/null > /var/log/wtmp 2>/dev/null
#logrotate -f /etc/logrotate.conf 2>/dev/null
find /var/log -type f -delete
rm -rf /var/log/journal/*
rm -f /var/lib/dhcp/*

# Zero out the free space to save space in the final image, blocking 'til
# written otherwise, the disk image won't be zeroed, and/or Packer will try to
# kill the box while the disk is still full and that's bad.  The dd will run
# 'til failure, so (due to the 'set -e' above), ignore that failure.  Also,
# really make certain that both the zeros and the file removal really sync; the
# extra sleep 1 and sync shouldn't be necessary, but...)
echo '> Zeroing device to make space...'
dd if=/dev/zero of=/EMPTY bs=1M || true; sync; sleep 1; sync
rm -f /EMPTY; sync; sleep 1; sync

unset HISTFILE && history -c && rm -fr /root/.bash_history

echo '> Done'
