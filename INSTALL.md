# Build instructions

## Overview
These procedures should step you through the process of installing packer and building the appliance on both a Windows and Linux environment, and using either VMware Workstation and VMware ESXi. Any untested or unvalidated procedures will be annotated, and if you run into any problems feel free to open an Issue or make the changes and issue a pull request.

__NOTE__: I have only validated running Packer from Windows using VMware Workstation so far. As additional procedures are fully vetted they will be documented here.

## Install procedures to build the appliance in a Windows environment using VMware Workstation

### Install Packer

[Packer Install Instructions](https://learn.hashicorp.com/tutorials/packer/getting-started-install)

### Download this repository

Download this repository from github:

 * Git command line: `git clone https://github.com/1computerguy/scanner-autobuild`
 * From github.com website:
   1) Select `Code` button in top right of the repository
   2) Select `Download Zip`
   3) Unzip the file to a folder on your computer

---

### Modify Packer build variables
There is a variables section at the top of the `packer-scan-autobuild.json` file to configure for your environment.

#### Variables common for Workstation and ESXi build:

  * vmname - The name you want for the Virtual Appliance
  * iso_file - Location of your local Photon ISO
    - __NOTE__: If you download the ISO manually make sure you have the [Full ISO x86_64](https://packages.vmware.com/photon/3.0/Rev3/iso/photon-3.0-a383732.iso)
  * iso_url - Download link for Photon ISO (Packer automatically downloads this if you do not have a local copy)
  * photon_username - set this to root
  * photon_password - root password to use for initial Packer build
  * numvcpus - number of CPUs required for VM
  * ramsize - amount of RAM for VM
  * disksize - size of the VM disk
  * eth_type - Set network interface type (Packer defaults to e1000, so we manually set it to vmxnet3 here)
  * script_dir - location of build scripts (this shouldn't change)
  * env_dir - location of additional files required for packer build (this shouldn't change)
  * output_path - path to output the VM (used for the OVA export script)
  * photon_ovf_template - location of the ovf template file (this shouldn't change)
  * photon_version - This is used in the ovf template to indicate the version of Photon used during build

#### Variables specific to VMware ESXi build:

  * esx_host - IP of esx host where you want to build VM
  * vcenter_username - username for vCenter server (web ui)
  * vcenter_password - password for vCenter server (web ui)
  * vcenter_datastore - Datastore to store the VM during build
  * vcenter - vCenter hostname
  * vcenter_datacenter - Datacenter to use to build the VM
  * vcenter_cluster - Cluster to use to build the VM
  * vcenter_vmfolder - VM folder to store the VM in during build
  * vcenter_portgroup - Portgroup for network connections (requires Internet for initial build)

---

### Build appliance with Packer
__NOTE__: Make sure ovftool is installed and added to your PATH environment variable. If you have VMware Workstation installed, you have ovftool. If you do not have Workstation, you can download and install ovftool from [here](https://code.vmware.com/web/tool/4.4.0/ovf).

  * Add ovftool to your PATH environment variable
    - Follow these instructions for [Windows using setx command](https://www.windows-commandline.com/set-path-command-line/)
    - Follow these instructions for [Windows GUI](https://docs.alfresco.com/4.2/tasks/fot-addpath.html)
    - Follow these instructions for [Linux](https://www.baeldung.com/linux/path-variable)

  * Navigate to the `scanner-autobuild` (location of the downloaded repository) directory
  * Run the Packer command to build the appliance:
    - Build on VMware Workstation: `packer build -only=vmware-workstation packer-scan-autobuild.json`
    - Build on VMware ESXi: `packer build -only=vmware-esxi packer-scan-autobuild.json`
  * Packer will run through some validation stages, and troubleshooting is pretty self explanitory if you read the errors (it is usually problems with your PATH or some variable setting)
  * :fingers-crossed: - The appliance builds properly and you have a packaged ova ready to deploy in your environment
  
  
