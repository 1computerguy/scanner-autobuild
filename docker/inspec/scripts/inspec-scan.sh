#!/bin/sh

if [ -z "$@" ]
then
        echo "This script expects an input argument for what to scan, and whether"
        echo "or not you want to force the scan."
        echo "Please make sure you are running it correctly..."
        echo ""
        echo " Example to FORCE scan:"
        echo "   $0 hosts force"
        echo ""
        echo " Example to NOT force:"
        echo "   $0 hosts"
        echo ""
fi

RUNVAL="$1"
FORCE="$2"
LOG_TIME=$(date +"%m-%d-%y_%H%M%S")
SCAN_VAL=''
SCAN_VAL_SHORT=''
cd /share

echo ""
echo "-------------------------------------------------"
echo "Scanning $RUNVAL, please wait patiently..."
echo "-------------------------------------------------"
echo ""

if [ ! "$RUNVAL" = "vcenter" ]
then
        for SCAN_VAL in $TO_SCAN
        do
                if [ "$RUNVAL" = "hosts" ]
                then
                        INSPEC_DIR="/inspec/vmware-esxi-6.7-stig-baseline"
                        SCAN_VAL_SHORT=$(echo $SCAN_VAL | cut -d'.' -f1 | cut -d'"' -f2)
                elif [ "$RUNVAL" = "vms" ]
                then
                        INSPEC_DIR="/inspec/vmware-vm-6.7-stig-baseline"
                        SCAN_VAL_SHORT=$(echo $SCAN_VAL | cut -d'"' -f2)
                fi
                echo ""
                echo -e "Scanning $SCAN_VAL"
                echo ""
                if [ $(ls /scans | grep -e "$SCAN_VAL_SHORT") ] && [ -z $FORCE ]
                then
                        echo "Skipping $SCAN_VAL_SHORT, scan already performed today"
                else
                        if ([ $(ls /scans | grep -e "$SCAN_VAL_SHORT") ] && [ $FORCE = "force" ])
                        then
                                echo "Forcing scan of $RUNVAL"
                                NEXT_FILE_TIME=$(echo $LOG_TIME | cut -d'_' -f2)
                                SCAN_VAL_SHORT="$SCAN_VAL_SHORT"_$NEXT_FILE_TIME
                        fi
                        cd $INSPEC_DIR
                        inspec exec $INSPEC_DIR -t vmware:// --input $SCAN_NAME=$(echo $SCAN_VAL | cut -d'"' -f2) --show-progress --reporter=cli json:/scans/$SCAN_VAL_SHORT.json 2>> /logs/$RUNVAL-$LOG_TIME-error.log
                fi
        done
else
        INSPEC_DIR="/inspec/vmware-vcsa-6.7-stig-baseline"
        SCAN_VAL=$VCENTER
        SCAN_VAL_SHORT=$(echo $SCAN_VAL | cut -d'.' -f1 | cut -d'"' -f2)
        echo ""
        echo "Scanning $SCAN_VAL_SHORT"
        echo ""
        if [ $(ls /scans | grep -e $SCAN_VAL_SHORT) ] && [ -z $FORCE ]
        then
                echo "Skipping $SCAN_VAL_SHORT, scan already performed today"
        else
                if ([ $(ls /scans | grep -e $SCAN_VAL_SHORT) ] && [ $FORCE = "force" ])
                then
                        echo "Forcing scan of $RUNVAL"
                        NEXT_FILE_TIME=$(echo $LOG_TIME | cut -d'_' -f2)
                        SCAN_VAL_SHORT="$SCAN_VAL_SHORT"_$NEXT_FILE_TIME
                fi
                cd $INSPEC_DIR
                inspec exec $INSPEC_DIR/wrapper -t ssh://$SSH_USER@$VISERVER --password $SSH_PASS --input syslogServer=$SYSLOG photonIp=$PHOTON ntpServer1=$NTP1 ntpServer2=$NTP2 --show-progress --reporter=cli json:/scans/$SCAN_VAL_SHORT.json 2>> /logs/$RUNVAL-$LOG_TIME-error.log
        fi
fi

echo ""
echo "------------------------------"
echo "Done scanning $RUNVAL"
echo "------------------------------"
