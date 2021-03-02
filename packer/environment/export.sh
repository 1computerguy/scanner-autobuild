#!/bin/bash

set -ep

if [[ -z "$@" ]]
then
    echo "You must provide an argument. Use --help or -h to get additional information."
    echo ""
    exit 1
fi

if [[ "$@" =~ '-e' ]] || [[ "$@" =~ '--environment' ]]
then
    case $1
    in
        -e | --environment )
            ;;
        *)
            echo "If you wish to use the -e or --environment option, it must be the first argument..."
            echo "Any additional arguments provided after -e or --environment will be overwritten by"
            echo "options provided at the command line."
            echo ""
            exit 1
            ;;
    esac
fi

function help () {
    cat <<EOF
  |-------------------------------------------------------------------------------------------
  |  This script exports scans performed by this system to CKL or XCCDF format.
  |
  |  NOTE: There currently exists an export issue with the XCCDF files that does not allow
  |        them to import properly into STIG viewer. This is a known issue and is currently
  |        being worked with Mitre.
  |
  | If you have problems, please contact Bryan Scarbrough
  |   bscarbrough@vmware.com
  |
  |
  |  OPERATIONAL NOTE: Easiest usage is to modify the variables in the ~/.env-export file and
  |       point the script to that file. See examples at the bottom of this message.
  |
  | Scan Arguments:
  |  --environment | -e <filename>      -  Export based on variables set in <filename>
  |                                        See or edit the ~/.env-export file (or make your own)
  |  --output_dir                       -  Specify the output directory where files are stored.
  |                                         This value defaults to '<current dir>/exports/RUN_DATE'
  |  --scan_dir                         -  Directory location of files to export - useful for exporting
  |                                         all the files in a single directory
  |  --scan_file                        -  Use this if you want to export a single scan file
  |  --export_type                      -  File type to export. Current valid values:
  |                                           xccdf
  |                                           ckl
  |  --vcenter                          -  This is the FQDN of vCenter and is required if you are
  |                                         exporting a scan of a vCenter server.
  |
  |  --help | -h                        -  Print this menu
  |
  | Example:
  |  Export using .env-export file (easiest method)
  |   $(basename "$0") -e .env-export
  |
  |  Export single scan file
  |   $(basename "$0") --scan_file /full/path/to/scanfile.json --export_type ckl
  |
  |  Export all Scans in a directory
  |   $(basename "$0") --scan_dir /full/path/to/scans 
  |
  |___________________________________________________________________________________________
EOF
    exit 0
}

while [ $1 ]
do
    case $1
    in
        -e | --environment )
            shift
            source "$1"
            ;;
        --output_dir )
            shift
            OUTPUT_DIR=$1
            ;;
        --scan_dir )
            shift
            SCAN_DIR=$1
            ;;
        --scan_file )
            shift
            SCAN_FILE="$1"
            ;;
        --export_type )
            shift
            EXPORT_TYPE=$1
            ;;
        --vcenter )
            shift
            VCENTER=$1
            ;;
        -h | --help )
            help
            ;;
    esac
    shift
done

# Set some default variable values if they are not already set
FILES=''
RUN_DATE=$(date +"%m%d%Y")
: ${BASE_DIR="$(pwd)"}
: ${OUTPUT_DIR="$BASE_DIR/exports/$RUN_DATE"}
: ${VCENTER=''}
META_DIR="$OUTPUT_DIR/metadata"

# Set FILES variable value based on scan input variables. If the SCAN_DIR and SCAN_FILE
#  variables are both set, then FILES = SCAN_DIR/SCAN_FILE. However, if only SCAN_DIR is set
#  then FILES is a list of files in the SCAN_DIR location.
([[ ! -z $SCAN_DIR ]] && [[ -z $SCAN_FILE ]]) && FILES=$(ls -d $SCAN_DIR/*) || FILES=$SCAN_DIR/$SCAN_FILE

# Create directories if they don't exist
[[ ! -d $OUTPUT_DIR ]] && mkdir -p $OUTPUT_DIR
[[ ! -d $META_DIR ]] && mkdir -p $META_DIR

echo "------------------------------"
echo "Generating files for export..."
echo "------------------------------"
echo ""
# Iterate over the $FILES list and export CKL or XCCDF files
for file in $FILES
do
    # Convert "CCI-######" strings to a list for xccdf export
    if [[ $(grep -owE '\[\"CCI-[0-9]{6}\"\]' $file | wc -l) == 0 ]]
    then
        sed -E -i 's/"CCI-([0-9]{6})"/\[&\]/g' $file
    fi

    # Extract the profile name from the scan file to determine scan type, then set/extract
    # the FQDN value from the settings
    SCAN_TYPE=$(jq '.profiles[0].name' $file | cut -d'-' -f2)
    if [[ $SCAN_TYPE == 'esxi' ]]
    then
        BENCHMARK='ESXi'
        FQDN=$(jq '.profiles[0].attributes[0].options.value' $file | cut -d'"' -f2)
    elif [[ $SCAN_TYPE == 'vcsa' ]]
    then
        BENCHMARK='VCSA'
        if [[ -z $VCENTER ]]
        then
            echo "You did not enter the vCenter Fully Qualified Domain Name (FQDN)"
            echo "and you are attempting to convert a vCenter scan profile..."
            echo "Please enter a valid vCenter FQDN below"
            echo ""
            echo "  - Example: vcenter.lab.local"
            echo ""
            read -p 'vCenter FQDN: ' VCENTER
        fi
        FQDN=$VCENTER
    elif [[ $SCAN_TYPE == 'vm' ]]
    then
        BENCHMARK='VM'
        FQDN=$(jq '.profiles[0].attributes[0].options.value' $file | cut -d'"' -f2).nase.ds.army.mil
    fi

    HOST=$(echo $FQDN | cut -d'.' -f1)
    IP=$(dig +short $FQDN)

    # Benchmark variables for xccdf-attributes.json completion
    BENCH_ID="VMWare_vSphere_6.7_${BENCHMARK}_Draft_STIG"
    BENCH_TITLE="VMware vSphere $BENCHMARK 6.7 Security Technical Implementation Guide"
    : ${BENCH_DATE=$(date +"%Y-%m-%d")}
    : ${BENCH_VER="1.0"}
    : ${BENCH_STATUS="draft"}
    : ${ORG_NAME=''}

    # Get file name from the full file path to use with the docker command below
    file_name=$(echo $file | tr '/' '\n' | tail -n1)
    if [[ $EXPORT_TYPE == 'xccdf' ]]
    then
        ATTR_FILE="xccdf-attr-$HOST.json"
        ATTR_PATH="$META_DIR/$ATTR_FILE"
        META_FILE="xccdf-meta-$HOST.json"
        META_PATH="$META_DIR/$META_FILE"

        echo "Creating XCCDF Meta files for $file"
        echo ""
        # Create xccdf attribute json file from scan attributes
        jq -n '$ARGS.named' --arg benchmark.id $BENCH_ID \
                            --arg benchmark.status $BENCH_STATUS \
                            --arg benchmark.status.date $BENCH_DATE \
                            --arg benchmark.version $BENCH_VER \
                            --arg benchmark.title $BENCH_TITLE \
                            --arg reference.href: "http://iase.disa.mil" \
                            --arg reference.dc.publisher: "DISA" \
                            --arg reference.dc.source: "STIG.DOD.MIL" > $ATTR_PATH

        # Create xccdf metadata json file from scan attributes
        jq -n '$ARGS.named' --arg hostname $HOST \
                            --arg ip $IP \
                            --arg fqdn $FQDN | \
                            jq --arg identity "root" \
                                --arg priv true \
                                '.identity.identity = $identity |
                                .identity.privileged = $priv' | \
                            jq --arg org "$ORG_NAME" '.organization = $org' > $META_PATH

        echo "Generating file: $OUTPUT_DIR/$HOST-xccdf.xml"
        echo ""
        # Use Mitre's inspec_tools docker container to generate xccdf XML file from
        # attributes and metadata files generated above.
        docker run --rm -it -v $ATTR_PATH:/meta/$ATTR_FILE \
                            -v $META_PATH:/meta/$META_FILE \
                            -v $file:/scan/$file_name \
                            -v $OUTPUT_DIR:/output \
                            mitre/inspec_tools inspec2xccdf \
                            -a /meta/$ATTR_FILE \
                            -m /meta/$META_FILE \
                            -j /scan/$file_name \
                            -o /output/$HOST-xccdf.xml

    elif [[ $EXPORT_TYPE == 'ckl' ]]
    then
        META_FILE="ckl-meta-$HOST.json"
        META_PATH="$META_DIR/$META_FILE"

        echo "Creating CKL Meta file for $file"
        echo ""
        # Create ckl metadata file from scan attributes
        jq -n '$ARGS.named' --arg stigid $BENCH_ID \
                            --arg hostname $HOST \
                            --arg ip $IP \
                            --arg fqdn $FQDN > $META_PATH

        echo "Generating file: $OUTPUT_DIR/$HOST-ckl.ckl"
        echo ""
        # Use Mitre's inspec_tools docker container to generate the ckl file
        # from the metadata file and scan file
        docker run --rm -it -v $META_PATH:/meta/$META_FILE \
                            -v $file:/scan/$file_name \
                            -v $OUTPUT_DIR:/output \
                            mitre/inspec_tools inspec2ckl \
                            -m /meta/$META_FILE \
                            -j /scan/$file_name \
                            -o /output/$HOST-ckl.ckl
    fi
done
echo ""
echo "------------------------------"
echo "Done exporting files"
echo "------------------------------"