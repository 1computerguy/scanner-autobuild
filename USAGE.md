# Scan script usage

### Output from `scan -h` command:

```
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
  |   $(basename "$0") --vcenter --vc vcenter.some.domain -n '1.2.3.4' -n '2.3.4.5'
  |
  |  --vcuser <username@some.domain> -  Set vCenter Username
  |  --vcpass <vcenter password>     -  Set vCenter Password
  |  --sshuser <ssh username>           -  Set vCenter Photon appliance SSH Username
  |  --sshpass <ssh password>           -  Set vCenter Photon appliance SSH Password
  |
  |  --help | -h                        -  Print this menu
  |
  | Example:
  |  Scan using .env file (easiest method) - make sure to update the variables in .env
  |   $(basename "$0") -e .env
  |
  |  Scan all VMs and vCenter (vcenter has separate STIG)
  |   $(basename "$0") --vm all --vcenter --force --vc vcenter.some.domain
  |
  |  Scan single host with stored creds
  |   $(basename "$0") --host esxi1.domain --creds --vc vcenter.some.domain
  |
  |  Scan all systems and prompt for creds
  |   $(basename "$0") --all --creds prompt --vc vcenter.some.domain
  |
  |___________________________________________________________________________________________
```

---

### Output from `export-scan -h` command:

```
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
```
