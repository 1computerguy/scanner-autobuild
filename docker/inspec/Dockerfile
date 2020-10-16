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
RUN apk --update add --no-cache ca-certificates \
        less \
        ncurses-terminfo-base \
        krb5-libs \
        libgcc \
        libintl \
        libssl1.1 \
        libstdc++ \
        tzdata \
        userspace-rcu \
        zlib \
        icu-libs \
        curl && \
    apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache lttng-ust

# Download and install PowerShell
RUN curl -L https://github.com/PowerShell/PowerShell/releases/download/v7.0.3/powershell-7.0.3-linux-alpine-x64.tar.gz -o /tmp/powershell.tar.gz && \
    mkdir -p /opt/microsoft/powershell/7 && \
    tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 && \
    chmod +x /opt/microsoft/powershell/7/pwsh && \
    ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

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
COPY ./scripts/inspec-scan.sh /usr/local/bin/scan.sh

# Set entrypoint permissions and accept license for InSpec
RUN chmod +x /usr/local/bin/scan.sh && \
    sed -i "s/<ver>/$(inspec -v)/" /etc/chef/accepted_licenses/inspec && \
    sed -i "s/<date>/$(date +"%Y-%m-%dT%T+00:00")/" /etc/chef/accepted_licenses/inspec

WORKDIR /inspec

ENTRYPOINT ["scan.sh"]
