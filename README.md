# VMware DoD/Security Scanner Appliance Auto-build
This is a Packer auto-built appliance using Photon and Docker to run the draft v6.7 DoD STIG scripts located at https://github.com/vmware/dod-compliance-and-automation in a VMware vSphere environment.

## Build instructions
 - NOTE: This is how I built and tested it so far, as additional means are validated, they will be written up here.

### Install Chocolatey (this was used to install Packer)
 - Open a PowerShell terminal as an administrator
 - Run the following command to install download an install Chocolatey
   `Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))`
 - Next, run `choco install packer`

### Download scanner-autobuild repository
 - Download this repository from github:
   - Git command line: `git clone https://github.com/1computerguy/scanner-autobuild`
   - From github.com website:
     1) Select `Code` button in top right of the repository
     2) Select `Download Zip`
     3) Unzip the file to a folder on your computer

### Modify Packer build variables
There is a variables section at the top of the packer-scan-autobuild.json file to configure for your environment. Below are the different variables you can configure and why you care.


### Build appliance with Packer
 - Make sure ovftool is installed and added to your PATH environment variable (if you have VMware Workstation installed, you have ovftool)
   1) Open a command prompt and type: `setx path "%PATH%;C:\Program Files (x86)\VMware\VMware Workstation\OVFTool"`
   2) Close and reopen the command prompt
   3) Navigate to the `scanner-autobuild` (location of the downloaded repository) directory
   4) Run the Packer command to build the appliance:
     - Build on VMware Workstation: `packer build -only=vmware-workstation packer-scan-autobuild.json`
     - Build on VMware ESXi: `packer build -only=vmware-esxi packer-scan-autobuild.json`
   5) Packer will run through some validation stages
     - NOTE: If you do not have a local copy of the Photon ISO, Packer will download it for you

