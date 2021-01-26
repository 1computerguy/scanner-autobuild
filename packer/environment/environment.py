# environment.py

import os

# REQUIRED:
# This is the base directory and is used as a reference for the Output location
#
BASEDIR = os.getcwd()

# Tell the scanner which VMs to scan for compliance (NOTE: This will only scan the VMs
#  configuration settings in ESX/vCenter - not the VM Operating System.)
# Acceptable values:
#   "All"   =   Scan all VMs for configuration compliance
#   "Name of Single VM"   =   Scan single VM
#
VMSCAN = ""

# Tell the scanner which ESXi hosts to scan for compliance.
# Acceptable values:
#   "All"   =   Scan all ESXi hosts
#   "FQDN or IP of host"   =   Scan single host by IP or name
#
HSCAN = ""

# Tell the scanner to scan vCenter.
# Set value to true to scan, and false to not scan vCenter Appliance
#
VCSCAN = True

# Tell the scanner to scan an individual control. If you want to scan for all controls,
# leave this variable commented.
# Use the STIG ID as the control number, e.g. VMCH-67-000001
#
# NOTE: You have to set the appropriate VMSCAN, HSCAN, or VCSCAN varible above to perform
#       a single control scan. For example: if you want to scan VMCH-67-000001, you must
#       add the appropriate VMSCAN variable setting (all or single VM) to scan for this control.
#       Another example, if you want to scan for control ESXI-67-000002 you have to set the HSCAN
#       variable.
#
CSCAN = False

# REQUIRED:
# FQDN of vCenter server
# Example FQDN: VCENTER="vcenter-server.test.lab"
#
VCENTER = ""

# IP address of Photon appliance if scanning the vCenter Server Appliance (VCSA)
#
# NOTE: If you do not remember your vCenter IP address use the dig command to get the value for you
#   Example: PHOTON_IP=$(dig +short $VCENTER)
#
PHOTON_IP = ""

# Uncomment this variable to upload the scan results to Heimdall for visualization and analysis.
#  Acceptable value: 1 = upload
#                    Leave commented to not upload
#
# For Upload user and Upload API key, these can be obtained from the Heimdall web UI at:
#    http://scan-vm-ip:3000
#
UPLOAD = False
UPLOAD_USER = ""
UPLOAD_API_KEY = ""

# IP address of the Syslog server. Required if you wish to scan a ESXi host or vCenter.
#
SYSLOG = ""

# IP addresses of the NTP servers. Required if you wish to scan an ESXi host or vCenter.
# *** NOTE: Both NTP IPs are required - InSpec will fail if there are not 2 NTP server IPs ***
#
NTP1 = ""
NTP2 = ""

# REQUIRED
#
# What file is used to store credentials. Use "prompt" if you want the script to prompt
# you for credentials.
#
# Acceptable values: prompt = script will prompt for credentials at runtime
#                    encrypt = SHA-512, salted password hash ($6$salt$pass format)
#                    plain = plain-text variables below (This option is unsecure)
CREDS = ""

# PROMPT:
#  Leave below values commented
#
# PLAIN:
#  Just enter plain text username and password values below.
#
# ENCRYPT
#  - Use openssl: openssl passwd -6 'S0meSecureP@$$w0rd'
#  - Use python: python3 -c 'import crypt; print(crypt.crypt("S0meSecureP@$$w0rd"))'
#
#USER = 'vcenter username'
#PASS = 'vcenter password'

# Manually add vCenter Photon SSH credentials. Uncomment then add full username and password between quotes.
# **** Make sure to use single quotes due to special characters in these settings ****
#
#SSH_USER = 'ssh username'
#SSH_PASS = 'ssh password'

# By default the scanner will only be scanned once per day. This setting will force a rescan
# of a system. Just uncomment to enable.
#  Acceptable value: 1 = Force scan
#                    Leave commented to ignore already scanned systems
#
FORCE = False