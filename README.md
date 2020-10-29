
# VMware DoD/Security Scanner Appliance Auto-build

## Overview

This is a Packer auto-built appliance using Photon and Docker to run the draft v6.7 DoD Security Technical Implementaiton Guide (STIG) in a VMware vSphere environment. The intent behind this appliance is to create a lightweight, portable VM for security scanning of VMware infrastracture in DoD environments in compliance with Risk Management Framework (RMF) guildlines as defined in DoDI 8510.01. This appliance will currently only scan an environment against the existing VMware v6.7 STIG, but if you require compatability with previous versions of vSphere, create an issue and I'll see what I can do (or if you would like to contribute, feel free to issue a pull request).

* For more information about the existing vSphere STIG and Security Requirements Guide (SRG), please visit the DoD Compliance and Automation Github repository below.

[VMware DoD Compliance and Automation - vSphere v6.7 STIG (Draft)](https://github.com/vmware/dod-compliance-and-automation)


### Appliance Deployment

---

* For Install instructions refer to the install documentation in this repository.

[Appliance Install and Deployment](https://github.com/1computerguy/scanner-autobuild/blob/main/INSTALL.md)


### Scan Script usage

---

* For scanner usage instructions refer to the usage documenation in this repository (or use the `scan -h` command once you log into the appliance)

[Scanner usage instructions](https://github.com/1computerguy/scanner-autobuild/blob/main/USAGE.md)
