#!/bin/bash 

set -ep

[[ -z "$@" ]] && echo "You must provide an argument. Use --help or -h to get additional information."

# Set Date
RUN_DATE=$(date +"%m%d%Y")

function help () {
    cat <<EOF
  |-------------------------------------------------------------------------------------------
  |  This script performs STIG scans against VMware 6.7 environments ONLY.
  |  To use this script and the associated DoD STIG validation scripts, refer to the
  |  help information below.
  |
  | If you have problems, please contact Bryan Scarbrough
  |   bscarbrough@vmware.com
  |
  |
  | NOTE: Easiest usage is to modify the variables in the ~/.env file and point the script
  |       to that file. See examples at the bottom of this message.
  |
  | Scan Arguments:
  |  --environment | -e <filename>      -  Scan based on variables set in <filename>
  |                                        See or edit the ~/.env file (or make your own)
  |  --all | -a                         -  Scan all systems (VMs, ESX Hosts, and vCenter)
  |  --vm <all|VM name in vCenter>      -  Scan all or single VMs
  |  --host <all|Host FQDN or IP>       -  Scan all or single hosts
  |  --vcenter <vcenter FQDN or IP>     -  Scan vCenter VM
  |  --pip                              -  vCenter Photon IP address if scanning VCSA
  |  --upload | -u                      -  Upload to Heimdall
  |  --upload-user <heimdal username>   -  Account for Heimdall visualization uploads
  |                                        Value ignored if -u|--upload option not used
  |  --upload-api-key <heimdall api key>-  API Key to use for Heimdall automatic uploads
  |                                        Value ignored if -u|--upload option not used
  |  --control | -c <Control number>    -  Scan single control can be
  |                                        used with single host/vm or
  |                                        all VMs/Hosts
  |  --creds | -d prompt                -  This option is to prompt for credentials
  |  --basedir | -b <script directory>  -  Set script resource directory
  |  --force | -f                       -  Force rescan of system (scanner ignores systems
  |                                        scanned during the same day)
  |  --syslog | -s <syslog IP>          -  Dynamically set SysLog IP
  |  --ntp1 <NTP IP>                    -  Set NTP1 IP
  |  --ntp2 <NTP IP>                    -  Set NTP2 IP
  |  --ntp | -n <NTP IP>                -  If -n used, first value is is NTP1 second
  |                                        value is NTP2
  |
  | Usage of -n option:
  |   scan --vcenter --vc vcenter.some.domain -n '1.2.3.4' -n '2.3.4.5'
  |
  |  --vcuser <username@some.domain> -  Set vCenter Username
  |  --vcpass <vcenter password>     -  Set vCenter Password
  |  --sshuser <ssh username>           -  Set vCenter Photon appliance SSH Username
  |  --sshpass <ssh password>           -  Set vCenter Photon appliance SSH Password
  |
  |  --help | -h                        -  Print this menu
  |
  | Example:
  |  Scan using .env file (easiest method)
  |   scan -e .env
  |
  |  Scan all VMs and vCenter (vcenter has separate STIG)
  |   scan --vm all --vcenter --force --vc vcenter.some.domain
  |
  |  Scan single host with stored creds
  |   scan --host esxi1.domain --creds --vc vcenter.some.domain
  |
  |  Scan all systems and prompt for creds (simplest but longest)
  |   scan --all --creds prompt --vc vcenter.some.domain
  |
  |___________________________________________________________________________________________

EOF
    exit 0
}

function get_creds () {
    GET_CREDS="$1"

    if [[ $GET_CREDS == "prompt" ]]
    then
        echo "Please enter vCenter admin credentials required to scan"
        echo ""
        read -p 'vCenter Username: ' USER
        read -sp 'vCenter Password: ' PASS
        echo ""
        echo ""

        echo ""
        read -p 'SSH Username: ' SSH_USER
        read -sp 'SSH Password: ' SSH_PASS
        echo ""
        echo "NOTE: Make sure to enable SSH on the VCSA before running this scan."
    elif [[ $GET_CREDS == "encoded" ]]
    then
        if [[ ! -z $VCENTERCREDS ]]
        then
            USER=$(echo $VCENTERCREDS | base64 -d | cut -d':' -f1)
            PASS=$(echo $VCENTERCREDS | base64 -d | cut -d':' -f2)
        else
            echo "There are no valid vCenter credentials, please enter them at the prompts."
            echo ""
            get_creds "prompt"
        fi

        if ([[ ! -z $SSHCREDS ]] && [[ ! -z $VCSCAN ]])
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
}

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
        --upload-user )
            shift
            UPLOAD_USER="$1"
            ;;
        --upload-api-key )
            shift
            UPLOAD_API_KEY="$1"
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
        --sshuser )
            shift
            SSH_USER="$1"
            ;;
        --sshpass )
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
