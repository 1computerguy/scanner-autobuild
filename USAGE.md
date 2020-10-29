# Scan script usage

Output from `scan -h` command:

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
```
