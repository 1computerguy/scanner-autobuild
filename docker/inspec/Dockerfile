FROM chef/inspec

LABEL maintainer="Bryan Scarbrough <bscarbrough@vmware.com>" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.name="inspec-pwsh" \
    org.label-schema.description="Chef InSpec and PowerCLI inside Docker" \
    org.label-schema.url="https://github.com/1computerguy/dod-compliance-and-automation" \
    org.label-schema.vcs-url="https://github.com/1computerguy/dod-compliance-and-automation" \
    org.label-schema.vendor="VMware" \
    org.label-schema.docker.cmd="docker run --rm -it inspec-pwsh"

# Install Pre-Requisits
RUN apt-get update && \
    apt-get install -y wget apt-transport-https software-properties-common && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download and install PowerShell
RUN wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y powershell && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install VMware.PowerCLI module disable incompatible submodules, accept licenses, and ignore certificates
RUN pwsh -Command "& {Set-PSRepository -Name PSGallery -InstallationPolicy Trusted}" && \
    pwsh -Command "& {Install-Module -Name VMware.PowerCLI -Force}"

RUN file=$(find / -name "VMware.PowerCLI.psd1" 2>/dev/null) && \
    for module in "HorizonView" "DeployAutomation" "ImageBuilder" "VumAutomation"; do sed -ie "/$module/s/^/#/" $file; done && \
    pwsh -Command "& {Set-PowerCLIConfiguration -InvalidCertificateAction:Ignore -Confirm:\$false}" && \
    pwsh -Command "& {Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP \$true -Confirm:\$false}"

# Copy inspec files to container and startup script into container
RUN mkdir /inspec
COPY ./inspec-license /etc/chef/accepted_licenses/inspec
COPY ./scripts/inspec-scan.sh /usr/local/bin/scan
COPY ./dod-compliance-and-automation/vsphere/6.7/vsphere/inspec/vmware-esxi-6.7-stig-baseline /inspec/vmware-esxi-6.7-stig-baseline
COPY ./dod-compliance-and-automation/vsphere/6.7/vsphere/inspec/vmware-vm-6.7-stig-baseline /inspec/vmware-vm-6.7-stig-baseline
COPY ./dod-compliance-and-automation/vsphere/6.7/vcsa/inspec/vmware-vcsa-6.7-stig-baseline /inspec/vmware-vcsa-6.7-stig-baseline

# Set entrypoint permissions and accept license for InSpec
RUN chmod +x /usr/local/bin/scan && \
    sed -i "s/<ver>/$(inspec -v)/" /etc/chef/accepted_licenses/inspec && \
    sed -i "s/<date>/$(date +"%Y-%m-%dT%T+00:00")/" /etc/chef/accepted_licenses/inspec

WORKDIR /inspec

ENTRYPOINT ["scan"]
CMD ["-h"]

