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
pushd /share

if [ "$RUNVAL" = "hosts" ]
then
	SCAN_NAME="vmhostName"
	SCAN_VAL_SHORT=$(echo $SCAN_VAL | cut -d'.' -f1 | cut -d'"' -f2)
elif [ "$RUNVAL" = "vms" ]
then
	SCAN_NAME="vmName"
	SCAN_VAL_SHORT=$(echo $SCAN_VAL | cut -d'"' -f2)
elif [ "$RUNVAL" = "vcenter" ]
then
	SCAN_VAL_SHORT=$(echo $SCAN_VAL | cut -d'.' -f1 | cut -d'"' -f2)
fi

echo ""
echo "-------------------------------------------------"
echo "Scanning $RUNVAL, please wait patiently..."
echo "-------------------------------------------------"
echo ""

if [ ! "$RUNVAL" = "vcenter" ]
then
	for SCAN_VAL in $TO_SCAN
	do
		echo ""
		echo -e "Scanning $SCAN_VAL"
		echo ""
		if [ $(ls /scans | grep $SCAN_VAL_SHORT) ] && [ ! $FORCE = "force" ]
		then
			echo "Skipping $SCAN_VAL_SHORT, scan already performed today"
		else
			if ([ $(ls /scans | grep $SCAN_VAL_SHORT) ] && [ $FORCE = "force" ])
			then
				echo "Forcing scan of $RUNVAL"
				NEXT_FILE_TIME=$(echo $LOG_TIME | cut -d'_' -f2)
				SCAN_VAL_SHORT="$SCAN_VAL_SHORT"_$NEXT_FILE_TIME
			fi

			inspec exec /inspec -t vmware:// --input $SCAN_NAME=$(echo $SCAN_VAL | cut -d'"' -f2) --show-progress --reporter=cli json:/scans/$SCAN_VAL_SHORT.json 2>> /logs/$RUNVAL-$LOG_TIME-error.log
		fi
	done
else
	echo ""
	echo "Scanning $SCAN_VAL_SHORT"
	echo ""
	if [ $(ls /scans | grep $SCAN_VAL_SHORT) ] && [ ! $FORCE = "force" ]
	then
		echo "Skipping $SCAN_VAL_SHORT, scan already performed today"
	else
		if ([ $(ls /scans | grep $SCAN_VAL_SHORT) ] && [ $FORCE = "force" ])
		then
			echo "Forcing scan of $RUNVAL"
			NEXT_FILE_TIME=$(echo $LOG_TIME | cut -d'_' -f2)
			SCAN_VAL_SHORT="$SCAN_VAL_SHORT"_$NEXT_FILE_TIME
		fi

		inspec exec /inspec/wrapper -t ssh://$SSH_USER@$VISERVER --password $SSH_PASS --input syslogServer=$SYSLOG photonIp=$PHOTON ntpServer1=$NTP1 ntpServer2=$NTP2 --show-progress --reporter=cli json:/scans/$SCAN_VAL_SHORT.json 2>> /logs/$RUNVAL-$LOG_TIME-error.log
	fi
fi

echo ""
echo "------------------------------"
echo "Done scanning $RUNVAL"
echo "------------------------------"
