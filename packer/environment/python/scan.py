#!/usr/bin/env python3

import os
import logging
import argparse
import docker

from pathlib import Path
from vcconnect import *
from decouple import config

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

def get_creds(vcenter_creds=False, ssh_creds=False):
    '''
    '''
    vcuser = ''
    vcpass = ''
    ssh_user = ''
    ssh_pass = ''
    if vcenter_creds:
        print("\nPlease enter vCenter admin credentials required to scan\n")
        vcuser = input('vCenter Username: ')
        vcpass = input('vCenter Password: ')

    if ssh_creds:
        print('\nPlease enter SSH credentials for the VCSA appliance')
        ssh_user = input('SSH Username: ')
        ssh_pass = input('SSH Password: ')
        print("\nNOTE: Make sure to enable SSH on the VCSA before running this scan.\n")

    return vcuser, vcpass, ssh_user, ssh_pass

def scan(scan, output_dir, log_dir, env):
    '''
    '''
    if scan == 'vcenter':
        docker run -it --rm -v "$OUTPUT_DIR":/scans --env VISERVER="$VCENTER" --env SSH_USER=$SSH_USER --env SSH_PASS=$SSH_PASS --env SYSLOG=$SYSLOG --env PHOTON=$PHOTON_IP --env NTP1=$NTP1 --env NTP2=$NTP2 inspec-pwsh vcenter $FORCE
    elif scan == 'hosts':
        docker run -it --rm -v "$OUTPUT_DIR":/scans --env VISERVER="$VCENTER" --env VISERVER_USERNAME=$USER_WQ --env VISERVER_PASSWORD=$PASS_WQ --env TO_SCAN="$HOSTS" --env NTP1=$NTP1 --env NTP2=$NTP2 --env SYSLOG=$SYSLOG inspec-pwsh scan $FORCE
    elif scan == 'vms':
        docker run -it --rm -v "$OUTPUT_DIR":/scans --env VISERVER="$VCENTER" --env VISERVER_USERNAME=$USER_WQ --env VISERVER_PASSWORD=$PASS_WQ --env TO_SCAN="$HOSTS" inspec-pwsh scan $FORCE

def upload(user, apk_key, output_dir, log_dir):
    '''
    Upload scans to Heimdal server
    '''
    for file in output_dir:
        curl -F "file=@${file}" -F email=user -F api_key=api_key http://localhost:3000/evaluation_upload_api >>log_dir/.upload_success 2>>log_dir/.upload_error

def main():
    '''
    Main function for scanning systems
    '''
    parser = argparse.ArgumentParser(description="This script performs STIG scans against VMware 6.7 environments ONLY. To use, refer to the various command line arguments below.")
    parser.add_argument('-e', '--environment', action='store', dest='environment', default='', type=str,
                        help='Import environment variables and provide location of .env file', required=False)
    parser.add_argument('-m', '--vm', action='store', dest='vms', default=[], type=list, nargs='*',
                        help='List of VMs to scan', required=False)
    parser.add_argument('-t', '--host', action='store', dest='hosts', default=[], type=list, nargs='*',
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
    parser.add_argument('-c', '--control', action='store', dest='control', default='', type=list,, nargs='*',
                        help='Provide control number of an individual control to scan', required=False)
    parser.add_argument('-s', '--syslog', action='store', dest='syslog', default='', type=str,
                        help='IP or FQDN of Syslog serve', required=False)
    parser.add_argument('-n', '--ntp', action='store', dest='ntp_servers', default=[], type=list, nargs='*',
                        help='IP addresses for NTP servers (minimum of 2 IPs required)', required=False)
    parser.add_argument('-b', '--basedir', action='store', dest='', default=Path.cwd(),
                        help='Set the scanner base directory', required=False)
    parser.add_argument('-f', '--force', action='store_true', dest='force', default=False,
                        help='Force a rescan of a system', required=False)
    parser.add_argument('--vcuser', action='store', dest='vcuser', default='', type=str,
                        help='vCenter username', required=False)
    parser.add_argument('--vcpass', action='store', dest='vcpass', default='', type=str,
                        help='vCenter password', required=False)
    parser.add_argument('--sshuser', action='store', dest='ssh_user', default='', type=str,
                        help='VCSA Photon appliance SSH username', required=False)
    parser.add_argument('--sshpass', action='store', dest='ssh_pass', default='', type=str,
                        help='VCSA Photon appliance SSH password', required=False)
    parser.add_argument('--prompt', action='store_true', dest='prompt', default=False,
                        help='Prompt for scan credentials', required=False)
    parser.add_help()

    # Get options and set timestamp
    options = parser.parse_args()
    environment_vars = {}

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
    environment_vars['vcenter'] = config['VCENTER'] if not options.vcenter else options.vcenter
    environment_vars['syslog'] = config['SYSLOG'] if not options.syslog else options.syslog
    environment_vars['ntp1'] = config['NTP1'] if not options.ntp else options.ntp[0]
    environment_vars['ntp2'] = config['NTP2'] if not options.ntp else options.ntp[1]
    environment_vars['photon_ip'] = config['PHOTON_IP'] if not options.photon_ip else options.photon_ip
    environment_vars['vms'] = [ config['VMS'] ] if not options.vms else options.vmscan
    environment_vars['hosts'] = [ config['HOSTS'] ] if not options.hosts else options.hosts
    
    if prompt and vcscan:
        vcuser, vcpass, ssh_user, ssh_pass = get_creds(vcenter, True)
    elif vcscan:
        vcuser = config['VCUSER'] if not options.vcuser else options.vcuser
        vcpass = config['VCPASS'] if not options.vcpass else options.vcpass
        ssh_user = config['SSH_USER'] if not options.ssh_user else options.ssh_user
        ssh_pass = config['SSH_PASS'] if not options.ssh_pass else options.ssh_pass
        
    environment_vars['vc_user'] = vcuser
    environment_vars['vc_pass'] = vcpass
    environment_vars['ssh_user'] = ssh_user
    environment_vars['ssh_pass'] = ssh_pass
    upload = config['UPLOAD'] if not options.upload else options.upload
    upload_user = config['UPLOAD_USER'] if not options.upload_user else options.upload_user
    upload_api_key = config['UPLOAD_API_KEY'] if not options.api_key else options.api_key

    base_dir = options.base_dir
    output_dir = base_dir / 'scans' / run_date
    log_base = base_dir / 'logs'
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    Path(log_dir).mkdir(parents=True, exist_ok=True)

    if environment_vars['vms'][0] == 'all' or environment_vars['hosts'] == 'all':
        vcenter_sess = get_vc_session(environment_vars['vcenter'], vcuser, vcpass)
        if environment_vars['vms'][0] == 'all':
            environment_vars['vms'] = get_vms(vcenter_sess, environment_vars['vcenter'])
        
        if environment_vars['hosts'][0] == 'all':
            environment_vars['hosts'] = get_hosts(vcenter_sess, environment_vars['vcenter'])

    if 
        scan()

if __name__ == "__main__":
    try:
        exit(main())
    except Exception:
        logging.exception("Exception in main()")
        exit(1)
