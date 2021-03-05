# pull base image
FROM ubuntu:20.04

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
    org.label-schema.docker.cmd="docker run --rm -it docker-ansible -i 'IP or FQDN', -u 'username' /ansible/vcsa/vcsa-stig.yaml -k -v"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y gnupg2 python3-pip sshpass git openssh-client && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean
    
RUN python3 -m pip install --upgrade pip cffi && \
    pip install ansible==2.8.17 && \
    pip install mitogen ansible-lint jmespath && \
    pip install --upgrade pywinrm

RUN mkdir /ansible && \
    mkdir -p /etc/ansible && \
    echo 'localhost' > /etc/ansible/hosts

# Copy VCSA, HOSTS, and VMs hardening profiles into container
COPY ./dod-compliance-and-automation/vsphere/6.7/vcsa/ansible/* /ansible/vcsa
COPY ./dod-compliance-and-automation/vsphere/6.7/vsphere/ansible/* /ansible/host
#COPY ./dod-compliance-and-automation/vsphere/6.7/vsphere/ansible/vmware-vm-6.7-stig-ansible-hardening /ansible/vm

# Set working directory
WORKDIR /ansible

ENTRYPOINT [ "ansible-playbook" ]
CMD [ "-h" ]