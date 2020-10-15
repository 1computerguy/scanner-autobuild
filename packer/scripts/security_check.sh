#!/bin/bash
# Minimum security baseline, disabling root user and sshd password
# authentication

echo '> Disabling root account and locking account to prevent any possible exploitation...'
# Remove root password
passwd -d root

# Lock root user
usermod -L root

echo '> Disabling root SSH login...'
# Restore login only through unprivileged users:
sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
