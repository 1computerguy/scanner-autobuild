#!/usr/bin/env python3

import os
import logging
import crypt
import argparse

from environment import *

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

def help ():
    print (
'''
  |-------------------------------------------------------------------------------------
  |  This script performs STIG scans against VMware 6.7 environments ONLY. To use, refer
  |  to the various command line arguments below.
  |
  |  NOTE: For easiest operation, set the variables in the environment.py file
  |
  | Scan Arguments:
  |  --environment | -e <filename>      -  Scan based on variables set in <filename>
  |                                        See or edit the ~/.env file (or make your own)
  |  --vm <all|VM name in vCenter>      -  Scan all or single VMs
  |  --host <all|Host FQDN or IP>       -  Scan all or single hosts
  |  --vcenter <vcenter FQDN or IP>     -  Scan vCenter VM
  |  --pip                              -  vCenter Photon IP address if scanning VCSA
  |  --all | -a                         -  Scan all systems
  |  --upload | -u                      -  Upload to Heimdall
  |  --control | -c <Control number>    -  Scan single control can be
  |                                        used with single host/vm or
  |                                        all VMs/Hosts
  |  --creds | -d /credential/file      -  Use a file with credentials stored
  |                                        in a base64 encoded user:pass format
  |  --creds | -d prompt                -  This option is to prompt for credentials
  |  --basedir | -b <script directory>  -  Set script resource directory
  |  --force | -f                       -  Force rescan of system
  |  --syslog | -s <syslog IP>          -  Dynamically set SysLog IP
  |  --ntp1 | -n <NTP IP>               -  Set NTP1 IP
  |  --ntp2 <NTP IP>                    -  Set NTP2 IP
  |  --ntp | -n <NTP IP>                -  If -n used, first value is
  |                                        first value is NTP1 and
  |                                        second value is NTP2
  |
  | Usage of -n option:
  |   $0 --vcenter --vc vcenter.domain -n '1.2.3.4' -n '2.3.4.5'
  |
  |  --help                             -  Print this menu
  |
  | NOTE: The below options are not recommended for security reasons
  |     because your username and passwords will be stored in your
  |     shell history. It is recommended to either:
  |        1) Use the --creds prompt option and enter them when prompted. (most secure)
  |        2) Use a file to store the credentials then use the
  |           '--creds /file/location' option
  |     creds file format:
  |        - Base64 encode username and password as:
  |                 username:password
  |        - Example command to do this:
  |           $ echo 'vcuser@domain:vcpassword' | base64 > .creds
  |           $ echo 'sshuser:sshpassword' | base64 >> .creds
  |
  |  --user | -u <username@domain>      -  Set vCenter Username
  |  --pass | -p <vcenter password>     -  Set vCenter Password
  |  --sshuser <ssh username>           -  Set vCenter SSH Username
  |  --sshpass <ssh password>           -  Set vCenter SSH Password
  |
  | Example:
  |  Scan using .env file (easiest method)
  |   $0 -e .env
  |
  |  Scan all VMs and vCenter (vcenter has separate STIG)
  |   $0 --vm all --vcenter --force --vc vcenter.domain
  |
  |  Scan single host with stored creds
  |   $0 --host esxi1.domain --creds --vc vcenter.domain
  |
  |  Scan all systems and prompt for creds (simplest but longest)
  |   $0 --all --creds prompt --vc vcenter.domain
  |
  | If you have problems, please contact Bryan Scarbrough
  |   bscarbrough@vmware.com
  |__________________________________________________________________________________
'''
    )

def get_creds(cred_method, vcenter_creds=False, ssh_creds=False):

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

def scan():
    # Host scans
    [[ $HSCAN ]] && docker run -it --rm -v "$OUTPUT_DIR":/scans --env VISERVER="$VCENTER" --env VISERVER_USERNAME=$USER_WQ --env VISERVER_PASSWORD=$PASS_WQ --env TO_SCAN="$HOSTS" inspec-pwsh hosts $FORCE

    # VM scans
    [[ $VMSCAN ]] && docker run -it --rm -v "$OUTPUT_DIR":/scans --env VISERVER="$VCENTER" --env VISERVER_USERNAME=$USER_WQ --env VISERVER_PASSWORD=$PASS_WQ --env TO_SCAN="$VMS" inspec-pwsh vms $FORCE

    # vCenter scans
    [[ $VCSCAN ]] && docker run -it --rm -v "$OUTPUT_DIR":/scans --env VISERVER="$VCENTER" --env SSH_USER=$SSH_USER --env SSH_PASS=$SSH_PASS --env SYSLOG=$SYSLOG --env PHOTON=$PHOTON_IP --env NTP1=$NTP1 --env NTP2=$NTP2 inspec-pwsh vcenter $FORCE



# If upload option is selected, then upload scans to Heimdal server
if [[ $UPLOAD ]]
then
    for file in ${OUTPUT_DIR}/*
    do
        curl -F "file=@${file}" -F email=$UPLOAD_USER -F api_key=$UPLOAD_API_KEY http://localhost:3000/evaluation_upload_api >>$LOG_BASE/.upload_success 2>>$LOG_BASE/.upload_error
    done
fi

def main():
    '''Main function for scanning systems
    '''
    parser = argparse.ArgumentParser(description="This script performs STIG scans against VMware 6.7 environments ONLY. To use, refer to the various command line arguments below.")
    parser.add_argument("")
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

    # Set Date
    RUN_DATE=$(date +"%m%d%Y")


if __name__ == "__main__":
    try:
        exit(main())
    except Exception:
        logging.exception("Exception in main()")
        exit(1)








while [ $1 ]
do
    case $1
    in
        -e | --environment )
            shift
            source "$1"
            VC_BASE=$(echo $VCENTER | cut -d'.' -f1)
            [[ -z $PHOTON_IP ]] && PHOTON_IP=$(dig +short $VCENTER)
            if [[ -z $CREDS ]]
            then
                echo "You have to set a value for the CREDS variable"
                exit 1
            else
                get_creds "$CREDS"
            fi
            ;;
        --vm | -m )
            shift
            VMSCAN="$1"
            ;;
        --host | -t )
            shift
            HSCAN="$1"
            ;;
        --vcenter | -v )
            VCSCAN="1"
            ;;
        --vc )
            shift
            VCENTER="$1"
            VC_BASE=$(echo $VCENTER | cut -d'.' -f1)
            ;;
        --pip )
            shift
            PHOTON_IP="$1"
            ;;
        --all | -a )
            VMSCAN="all"
            HSCAN="all"
            VCSCAN="1"
            ;;
        --upload | -u )
            UPLOAD="1"
            ;;
        --control | -c )
            shift
            CSCAN="$1"
            ;;
        --syslog | -s )
            shift
            SYSLOG=$1
            ;;
        --ntp1 )
            shift
            NTP1=$1
            ;;
        --ntp2 )
            shift
            NTP2=$1
            ;;
        --ntp | -n )
            if [[ $NTP1 == '' ]]
            then
                shift
                NTP1=$1
            elif [[ ! $NTP1 == '' ]]
            then
                shift
                NTP2=$1
            fi
            ;;
        --basedir | -b )
            shift
            BASE_DIR=$1
            ;;
        --force | -f )
            FORCE="force"
            ;;
        --creds | -d )
            shift
            creds $1
            ;;
        --vcuser )
            shift
            USER=$1
            ;;
        --vcpass )
            shift
            PASS="$1"
            ;;
        --sshu )
            shift
            SSH_USER="$1"
            ;;
        --sshp )
            shift
            SSH_PASS="$1"
            ;;
        --help | -h )
            help
            ;;
    esac
    shift
done

# vCenter Settings - if these variables are not set, we will set them to empty strings
# except for the PHOTON_IP which can be set using a DNS lookup if it is forgotten when
# scanning vCenter
[[ -z $SYSLOG ]] && SYSLOG=''
[[ -z $NTP1 ]] && NTP1=''
[[ -z $NTP2 ]] && NTP2=''
([[ -z $PHOTON_IP ]] && [[ ! -z $VCENTER ]]) && PHOTON_IP=$(dig +short $VCENTER)

# User Account Credentials variables - all set to empty will be populated later in script
USER_WQ=''
PASS_WQ=''
[[ -z $USER ]] && USER=''
[[ -z $PASS ]] && PASS=''
[[ -z $SSH_USER ]] && SSH_USER=''
[[ -z $SSH_PASS ]] && SSH_PASS=''
[[ -z $UPLOAD_USER ]] && UPLOAD_USER=''
[[ -z $UPLOAD_API_KEY ]] && UPLOAD_API_KEY=''

# Directories and files
[[ -z $BASE_DIR ]] && BASE_DIR="$(pwd)"
OUTPUT_DIR="$BASE_DIR/scans/$RUN_DATE"
COOKIE="$BASE_DIR/cookie-jar.txt"
LOG_BASE="$BASE_DIR/logs"

[[ ! -d $OUTPUT_DIR ]] && mkdir -p $OUTPUT_DIR

USER_WQ=$(echo \'$USER\')
PASS_WQ=$(echo \'$PASS\')

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