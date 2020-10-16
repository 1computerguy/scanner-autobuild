#!/bin/bash

function help () {
    echo ""
    echo -e "|  This script performs STIG scans against VMware 6.7"
    echo -e "|  environments ONLY. To use this script please indicate"
    echo -e "|  what to scan."
    echo -e "|"
    echo -e "| Scan Arguments:"
    echo -e "|  --vm <all|VM name in vCenter>      -  Scan all or single VMs"
    echo -e "|  --host <all|Host FQDN or IP>       -  Scan all or single hosts"
    echo -e "|  --vcenter <vcenter FQDN or IP>     -  Scan vCenter VM"
    echo -e "|  --all | -a                         -  Scan all systems"
    echo -e "|  --upload | -u                      -  Upload to Heimdall"
    echo -e "|  --control | -c <Control number>    -  Scan single control can be"
    echo -e "|                                        used with single host/vm or"
    echo -e "|                                        all VMs/Hosts"
    echo -e "|  --creds | -d /credential/file      -  Use a file with credentials stored"
    echo -e "|                                        in a base64 encoded user:pass format"
    echo -e "|  --creds | -d prompt                -  This option is to prompt for credentials"
    echo -e "|  --basedir | -b <script directory>  -  Set script resource directory"
    echo -e "|  --force | -f                       -  Force rescan of system"
    echo -e "|  --syslog | -s <syslog IP>          -  Dynamically set SysLog IP"
    echo -e "|  --ntp1 | -n <NTP IP>               -  Set NTP1 IP"
    echo -e "|  --ntp2 <NTP IP>                    -  Set NTP2 IP"
    echo -e "|  --ntp | -n <NTP IP>                -  If -n used, first value is"
    echo -e "|                                        first value is NTP1 and"
    echo -e "|                                        second value is NTP2"
    echo -e "|"
    echo -e "| Usage of -n option:"
    echo -e "|   $0 --vcenter --vc vcenter.domain -n '1.2.3.4' -n '2.3.4.5'"
    echo -e "|"
    echo -e "|  --help                             -  Print this menu"
    echo -e "|"
    echo -e "| NOTE: The below options are not recommended for security reasons"
    echo -e "|     because your username and passwords will be stored in your"
    echo -e "|     shell history. It is recommended to either:"
    echo -e "|        1) Use the --creds prompt option and enter them when prompted. (most secure)"
    echo -e "|        2) Use a file to store the credentials then use the"
    echo -e "|           '--creds /file/location' option"
    echo -e "|     creds file format:"
    echo -e "|        - Base64 encode username and password as:"
    echo -e "|                 username:password"
    echo -e "|        - Example command to do this:"
    echo -e "|           $ echo 'vcuser@domain:vcpassword' | base64 > .creds"
    echo -e "|           $ echo 'sshuser:sshpassword' | base64 >> .creds"
    echo -e "|"
    echo -e "|  --user | -u <username@domain>      -  Set vCenter Username"
    echo -e "|  --pass | -p <vcenter password>     -  Set vCenter Password"
    echo -e "|  --sshuser <ssh username>           -  Set vCenter SSH Username"
    echo -e "|  --sshpass <ssh password>           -  Set vCenter SSH Password"
    echo -e "|"
    echo -e "| Example:"
    echo -e "|  Scan all VMs and vCenter (vcenter has separate STIG)"
    echo -e "|   $0 --vm all --vcenter --force --vc vcenter.domain"
    echo -e "|"
    echo -e "|  Scan single host with stored creds"
    echo -e "|   $0 --host esxi1.domain --creds --vc vcenter.domain"
    echo -e "|"
    echo -e "|  Scan all systems and prompt for creds (simplest but longest)"
    echo -e "|   $0 --all --creds prompt --vc vcenter.domain"
    echo -e "|"
    echo -e "| If you have problems, please contact Bryan Scarbrough"
    echo -e "|   bscarbrough@vmware.com"
    echo ""
    exit 0
}

function creds () {
    [[ "$@" ]] && GET_CREDS="$1"

    if [[ $GET_CREDS == "prompt" ]]
    then
        echo "Please enter vCenter admin credentials required to scan"
        echo ""
        read -p 'vCenter Username: ' USER
        read -sp 'vCenter Password: ' PASS
        echo ""
        echo ""

        read -p 'Are you scanning the vCenter appliance? [y/n] ' input
        if [[ $input == 'y' || $input == 'Y' ]]
        then
            echo ""
            read -p 'SSH Username: ' SSH_USER
            read -sp 'SSH Password: ' SSH_PASS
            echo ""
            echo "NOTE: Make sure to enable SSH on the VCSA before running this scan."
        fi
    elif ([[ -f $GET_CREDS ]] || [[ $(wc -l < $GET_CREDS 2>/dev/null) > 0 ]])
    then
        USER=$(cat $GET_CREDS | head -1 | base64 -d | cut -d':' -f1)
        PASS=$(cat $GET_CREDS | head -1 | base64 -d | cut -d':' -f2)

        if [[ $(wc -l < $GET_CREDS) > 1 ]]
        then
            SSH_USER=$(cat $GET_CREDS | tail -1 | base64 -d | cut -d':' -f1)
            SSH_PASS=$(cat $GET_CREDS | tail -1 | base64 -d | cut -d':' -f2)
        fi
    else
        echo "You have to enter either 'prompt' or '/file/location' when using the"
        echo "--creds option. For more information use --help or -h."
    fi
}

[[ -z "$@" ]] && echo "You must provide an argument. Use --help or -h to get additional information."

while [ $1 ]
do
    case $1
    in
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
            PHOTON_IP=$(dig +short $VCENTER)
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
            CONTROL="$1"
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

# Set Date
RUN_DATE=$(date +"%m%d%Y")

# Directories and files
[[ -z $BASE_DIR ]] && BASE_DIR="$(pwd)"
OUTPUT_DIR="$BASE_DIR/scans/$RUN_DATE"
COOKIE="$BASE_DIR/cookie-jar.txt"
LOG_BASE="$BASE_DIR/logs"

[[ ! -d $OUTPUT_DIR ]] && mkdir -p $OUTPUT_DIR

# vCenter Settings
[[ -z $SYSLOG ]] && SYSLOG=''
[[ -z $NTP1 ]] && NTP1=''
[[ -z $NTP2 ]] && NTP2=''

# User Account Credentials variables - all set to empty will be populated later in script
USER_WQ=''
PASS_WQ=''
[[ -z $USER ]] && USER=''
[[ -z $PASS ]] && PASS=''
[[ -z $SSH_USER ]] && SSH_USER=''
[[ -z $SSH_PASS ]] && SSH_PASS=''
[[ -z $UPLOAD_USER ]] && UPLOAD_USER='bscarbrough@vmware.com'
[[ -z $UPLOAD_API_KEY ]] && UPLOAD_API_KEY='kn4DNXLqmK8ZGHHZrDKJwg'

USER_WQ=$(echo \'$USER\')
PASS_WQ=$(echo \'$PASS\')

# Use vCenter API to get list of VMs and Hosts to scan
if ([[ $VMSCAN == "all" ]] || [[ $HSCAN == "all" ]]) || ([[ $VMSCAN == "all" ]] && [[ $HSCAN == "all" ]])
then
    [[ ! -f $COOKIE ]] && curl -k -i -u $USER:$PASS -X POST -c "$COOKIE" "https://$VCENTER/rest/com/vmware/cis/session"
    ([[ -s $COOKIE ]] && [[ $VMSCAN ]]) && VMS=$(curl -k -b "$COOKIE" "https://$VCENTER/rest/vcenter/vm" | jq '.value[] .name' | cut -d'"' -f2 | tr '\n' ' ')
    ([[ -s $COOKIE ]] && [[ $HSCAN ]]) && HOSTS=$(curl -k -b "$COOKIE" "https://$VCENTER/rest/vcenter/host" | jq '.value[] .name')
    rm -f $COOKIE
fi

# Set HOSTS and/or VMs to input values from command line arguments
[[ ! $HSCAN == "all" ]] && HOSTS=$HSCAN
[[ ! $VMSCAN == "all" ]] && VMS=$VMSCAN

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
