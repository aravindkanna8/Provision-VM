import xml.dom.minidom
import json
import sys, os
path = os.getcwd()
vm_name = sys.argv[1]

with open(f'{path}/vms/{vm_name}/vmssh.sh', 'r') as file:
    ssh_content = file.read()

# Open the JSON file
with open(f'{path}/vms/{vm_name}/basevm_parameters.json', 'r') as file:
    data = json.load(file)                # Load the JSON data
# Access the data from the JSON object
name = data['vm_name']
# ip = data['network']['ip']
hostname = data['network']['hostname']

with open('config.json', 'r') as file1:
    data1 = json.load(file1)
file_path = data1['autoyast']['file_path']
root_pass = data1['clone']['root_pswd']



dom = xml.dom.minidom.parse(file_path)
root = dom.documentElement # Get the root element of the XML document

post_script = root.getElementsByTagName('source')[0].firstChild.data
# Access element values
# ip_addr = root.getElementsByTagName('ipaddr')[0].firstChild.data
# host_name = root.getElementsByTagName('hostname')[0].firstChild.data
host_name = root.getElementsByTagName('hostname')[0].firstChild.data
user_password = root.getElementsByTagName('user_password')[8].firstChild.data

all_elements = dom.getElementsByTagName('*')

# Update the IP address value for each element
for element in all_elements:
    if element.firstChild and element.firstChild.data == user_password :
        element.firstChild.data = root_pass
    if element.firstChild and element.firstChild.data == host_name :
        element.firstChild.data = hostname
    if element.firstChild and element.firstChild.data == post_script :
        element.firstChild.data = ssh_content

with open(f'{path}/vms/{vm_name}/{name}.xml', 'w') as file:
    dom.writexml(file)
# print(ip_addr, host_name)