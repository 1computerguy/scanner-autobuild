# pull base image
FROM alpine:3.11

# Set attribution labels
LABEL maintainer="Bryan Scarbrough <bscarbrough@vmware.com>" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.name="docker-ansible" \
    org.label-schema.description="Ansible inside Docker" \
    org.label-schema.url="https://github.com/1computerguy/dod-compliance-and-automation" \
    org.label-schema.vcs-url="https://github.com/1computerguy/dod-compliance-and-automation" \
    org.label-schema.vendor="VMware" \
    org.label-schema.docker.cmd="docker run --rm -it docker-ansible ansible-playbook -i 'IP or FQDN', -u 'username' /ansible/vcsa/vcsa-stig.yaml -k -v"

# Install required base packages
RUN apk --no-cache add \
        sudo \
        python3\
        py3-pip \
        openssl \
        ca-certificates \
        sshpass \
        openssh-client \
        rsync \
        git && \
        apk --no-cache add --virtual build-dependencies \
        python3-dev \
        libffi-dev \
        openssl-dev \
        build-base

# Install Python packages
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

# Remove unnecessary packages
RUN apk del build-dependencies python3-dev

# Make /ansible and /etc/ansible directories and create hosts file
RUN mkdir /ansible && \
    mkdir -p /etc/ansible && \
    echo 'localhost' > /etc/ansible/hosts

# Copy VCSA, HOSTS, and VMs hardening profiles into container
COPY vsphere/6.7/vcsa/ansible/* /ansible/vcsa
COPY vsphere/6.7/vsphere/ansible/vmware-esxi-6.7-stig-ansible-hardening /ansible/host
COPY vsphere/6.7/vsphere/ansible/vmware-vm-6.7-stig-ansible-hardening /ansible/vm

# Set working directory
WORKDIR /ansible

CMD [ "ansible" ]
