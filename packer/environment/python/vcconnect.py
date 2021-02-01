
import requests
import json
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
 
# Function to get the vCenter server session
def get_vc_session(vcip, username, password):
    vcsession = requests.Session()
    vcsession.verify=False
    vcsession.post('https://{}/rest/com/vmware/cis/session'.format(vcip),auth=(username,password))
    return vcsession
 
# Function to get all the VMs from vCenter inventory
def get_vms(sess, vcip):
    vms = sess.get('https://{}/rest/vcenter/vm'.format(vcip))
    return vms

# Function to get all the hosts from vCenter inventory
def get_hosts(sess, vcip):
    hosts = sess.get('https://{}/rest/vcenter/hosts'.format(vcip))
    return hosts