#!/usr/bin/env python3

import os
import logging
import crypt
import argparse
import docker

from socket import gethostbyname
from pathlib import Path
from vcconnect import *

# Define logger for cross appliction logging consistency
logger = logging.getLogger(__name__)

# Create custom logging class for exceptions
class OneLineExceptionFormatter(logging.Formatter):
    def formatException(self, exc_info):
        result = super().formatException(exc_info)
        return repr(result)
 
    def format(self, record):
        result = super().format(record)
        if record.exc_text:
            result = result.replace("\n", "")
        return result

def get_creds(cred_method, vcenter_creds=False, ssh_creds=False):
    '''
    '''
    if cred_method == "prompt":
        print("\nPlease enter vCenter admin credentials required to scan\n")
        read -p 'vCenter Username: ' USER
        read -sp 'vCenter Password: ' PASS
        print("\n\n")

        read -p 'SSH Username: ' SSH_USER
        read -sp 'SSH Password: ' SSH_PASS
        print("\nNOTE: Make sure to enable SSH on the VCSA before running this scan.\n"
    elif cred_method == "encoded":
        if vcenter_creds == True:
            USER=$(echo $VCENTERCREDS | base64 -d | cut -d':' -f1)
            PASS=$(echo $VCENTERCREDS | base64 -d | cut -d':' -f2)
        else
            echo "There are no valid vCenter credentials, please enter them at the prompts."
            echo ""
            get_creds "prompt"


        if ssh_creds == True and vc_scan == True:
        then
            SSH_USER=$(echo $SSHCREDS | base64 -d | cut -d':' -f1)
            SSH_PASS=$(echo $SSHCREDS | base64 -d | cut -d':' -f2)
        elif ([[ -z $SSHCREDS ]] && [[ ! -z $VCSCAN ]])
        then
            echo "There are no valid SSH credentials, please enter them at the prompts."
            echo ""
            get_creds "prompt"
        fi
    else
        echo "You have to enter either 'prompt' or '/file/location' when using the"
        echo "--creds option. For more information use --help or -h."
    fi

def scan(scan, scan_systems, output_dir, vcenter, username, password, force):
    '''
    '''
    if scan == 'vcenter':
        docker run -it --rm -v "$OUTPUT_DIR":/scans --env VISERVER="$VCENTER" --env SSH_USER=$SSH_USER --env SSH_PASS=$SSH_PASS --env SYSLOG=$SYSLOG --env PHOTON=$PHOTON_IP --env NTP1=$NTP1 --env NTP2=$NTP2 inspec-pwsh vcenter $FORCE
    else:
        docker run -it --rm -v "$OUTPUT_DIR":/scans --env VISERVER="$VCENTER" --env VISERVER_USERNAME=$USER_WQ --env VISERVER_PASSWORD=$PASS_WQ --env TO_SCAN="$HOSTS" inspec-pwsh scan $FORCE

def upload(output_dir):
    '''
    '''
    # If upload option is selected, then upload scans to Heimdal server
    for file in output_dir:
        curl -F "file=@${file}" -F email=$UPLOAD_USER -F api_key=$UPLOAD_API_KEY http://localhost:3000/evaluation_upload_api >>$LOG_BASE/.upload_success 2>>$LOG_BASE/.upload_error

def main():
    '''Main function for scanning systems
    '''
    parser = argparse.ArgumentParser(description="This script performs STIG scans against VMware 6.7 environments ONLY. To use, refer to the various command line arguments below.")
    parser.add_argument('-e', '--environment', action='store', dest='environment', default='', type=str,
                        help='Import environment variables and provide location of .env file', required=False)
    parser.add_argument('-m', '--vm', action='store', dest='vms', default=[], type=list,
                        help='List of VMs to scan', required=False)
    parser.add_argument('-t', '--host', action='store', dest='hosts', default=[], type=list,
                        help='List of Hosts to scan', required=False)
    parser.add_argument('-v', '--vcenter', action='store_true', dest='vcscan', default=False,
                        help='This option tells the scanner to scan the vCenter Server', required=False)
    parser.add_argument('--vc', action='store', dest='vcenter', default='', type=str,
                        help='Enter the vCenter IP or FQDN', required=False)
    parser.add_argument('-a', '--all', action='store_true', dest='scan_all', default=False,
                        help='Scan all systems - VMs, Hosts, and vCenter', required=False)
    parser.add_argument('-p', '--photon', action='store', dest='photon_ip', default='', type=str,
                        help='IP address of the vCenter VCSA appliance', required=False)
    parser.add_argument('-u', '-upload', action='store_true', dest='upload', default=False,
                        help='Upload results to local Heimdall server', required=False)
    parser.add_argument('--up_user', action='store', dest='upload_user', default='', type=str,
                        help='Username to use for Heimdall upload', required=False)
    parser.add_argument('--api_key', action='store', dest='api_key', default='', type=str,
                        help='Heimdall API Key for user account to use for upload', requried=False)
    parser.add_argument('-c', '--control', action='store', dest='control', default='', type=str,
                        help='Provide control number of an individual control to scan', required=False)
    parser.add_argument('-s', '--syslog', action='store', dest='syslog', default='', type=str,
                        help='IP or FQDN of Syslog serve', required=False)
    parser.add_argument('-n', '--ntp', action='store', dest='ntp_servers', default=[], type=list, nargs='+',
                        help='IP addresses for NTP servers (minimum of 2 IPs required)', required=False)
    parser.add_argument('-b', '--basedir', action='store', dest='', default=Path.cwd(),
                        help='Set the scanner base directory', required=False)
    parser.add_argument('-f', '--force', action='store_true', dest='force', default=False,
                        help='Force a rescan of a system', required=False)
    parser.add_argument('--vcuser', action='store', dest='vcuser', default='', type=str,
                        help='vCenter username', required=False)
    parser.add_argument('--vcpass', action='store', dest='vcpass', default='', type=str,
                        help='vCenter password', required=False)
    parser.add_argument('--sshuser', action='store', dest='sshuser', default='', type=str,
                        help='VCSA Photon appliance SSH username', required=False)
    parser.add_argument('--sshpass', action='store', dest='sshpass', default='', type=str,
                        help='VCSA Photon appliance SSH password', required=False)
    parser.add_help()

    # Get options and set timestamp
    options = parser.parse_args()

    # Set logging before beginning
    handler = logging.StreamHandler()
    formatter = OneLineExceptionFormatter("%(asctime)s - %(levelname)s|%(message)s","%d/%m/%Y %H:%M:%S")
    handler.setFormatter(formatter)
    root = logging.getLogger()
    root.setLevel(os.environ.get("LOGLEVEL", "WARNING"))
    root.addHandler(handler)

    # vCenter Settings - if these variables are not set, we will set them to empty strings
    # except for the PHOTON_IP which can be set using a DNS lookup if it is forgotten when
    # scanning vCenter
    run_date = datetime.date.today().strftime('%m%d%Y')
    syslog = options.syslog
    ntp1 = options.ntp[0]
    ntp2 = options.ntp[1]
    photon_ip = options.photon_ip if options.photon_ip and options.vcenter else gethostbyname(vcenter)
    vc_user = options.vcuser
    vc_pass = options.vcpass
    ssh_user = options.sshuser
    ssh_pass = options.sshpass
    upload = options.upload
    upload_user = options.upload_user
    upload_api_key = options.api_key
    base_dir = options.base_dir
    output_dir = base_dir / 'scans' / run_date
    log_base = base_dir / 'logs'


    [[ ! -d $OUTPUT_DIR ]] && mkdir -p $OUTPUT_DIR


    # Use vCenter API to get list of VMs and Hosts to scan
    if ([[ $VMSCAN == "all" ]] || [[ $HSCAN == "all" ]]) || ([[ $VMSCAN == "all" ]] && [[ $HSCAN == "all" ]])
    then
        [[ ! -f $COOKIE ]] && curl -k -i -u $USER:$PASS -X POST -c "$COOKIE" "https://$VCENTER/rest/com/vmware/cis/session"
        ([[ -s $COOKIE ]] && [[ $VMSCAN ]]) && VMS=$(curl -k -b "$COOKIE" "https://$VCENTER/rest/vcenter/vm" | jq '.value[] .name' | cut -d'"' -f2 | tr '\n' ' ')
        ([[ -s $COOKIE ]] && [[ $HSCAN ]]) && HOSTS=$(curl -k -b "$COOKIE" "https://$VCENTER/rest/vcenter/host" | jq '.value[] .name')
        rm -f $COOKIE
    else
        # Set HOSTS and/or VMs to input values from command line arguments
        [[ ! $HSCAN == "all" ]] && HOSTS=$HSCAN
        [[ ! $VMSCAN == "all" ]] && VMS=$VMSCAN
    fi
    # Set Date
    RUN_DATE=$(date +"%m%d%Y")


if __name__ == "__main__":
    try:
        exit(main())
    except Exception:
        logging.exception("Exception in main()")
        exit(1)
