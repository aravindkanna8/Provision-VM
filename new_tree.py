import xml.dom.minidom
import json
import sys, os
# import random

vm_name = sys.argv[1]
path = os.getcwd()

# Read the content of the .sh file
with open(f'{path}/vms/{vm_name}/vmssh.sh', 'r') as file:
    ssh_content = file.read()

with open(f'{path}/vms/{vm_name}/user.sh', 'r') as file:
    user_content = file.read()

# open the config.json file to get autoinst.xml file path
with open('config.json', 'r') as file1:
    data1 = json.load(file1)
file_path = data1['sshops']['new_path']



# Open the JSON file
with open(f'{path}/vms/{vm_name}/{vm_name}.json', 'r') as file:
    data = json.load(file)                # Load the JSON data
# Access the data from the JSON object
ip = data['network']['ip']
hostname = data['network']['hostname']
tree = data['edirectory']['treename']
server_con = data['edirectory']['server_context']

modified_server = server_con.replace(",", ".")


dom = xml.dom.minidom.parse(file_path)

root = dom.documentElement # Get the root element of the XML document


# Access element values
host_name = root.getElementsByTagName('hostname')[0].firstChild.data
tree_name = root.getElementsByTagName('tree_name')[0].firstChild.data
# admin = root.getElementsByTagName('admin_password')[0].firstChild.data
server_context = root.getElementsByTagName('server_context')[0].firstChild.data
ws_context = root.getElementsByTagName('ws_context')[0].firstChild.data
common_proxy_context = root.getElementsByTagName('common_proxy_context')[0].firstChild.data
admin_context = root.getElementsByTagName('admin_context')[0].firstChild.data
server_object = root.getElementsByTagName('server_object')[0].firstChild.data
admin_group = root.getElementsByTagName('admin_group')[0].firstChild.data
ip_addr = root.getElementsByTagName('host_address')[1].firstChild.data
post_script = root.getElementsByTagName('source')[0].firstChild.data
nssadmin = root.getElementsByTagName('nssadmin_dn')[0].firstChild.data
partition_root = root.getElementsByTagName('partition_root')[0].firstChild.data
proxy_user = root.getElementsByTagName('proxy_user')[0].firstChild.data
ipaddr = root.getElementsByTagName('ipaddr')[0].firstChild.data


users = root.getElementsByTagName('users')[0].firstChild.data


all_elements = dom.getElementsByTagName('*')

# Update the IP address value for each element
for element in all_elements:
    if element.firstChild and element.firstChild.data == host_name :
        element.firstChild.data = hostname
    if element.firstChild and element.firstChild.data == tree_name :
        element.firstChild.data = tree
    # if element.firstChild and element.firstChild.data == admin :
    #     element.firstChild.data = admin_pass
    if element.firstChild and element.firstChild.data == server_context :
        element.firstChild.data = modified_server
    if element.firstChild and element.firstChild.data == common_proxy_context :
        element.firstChild.data = server_con
    if element.firstChild and element.firstChild.data == admin_context :
        element.firstChild.data = (f"cn=admin,{server_con}")
    if element.firstChild and element.firstChild.data == server_object :
        element.firstChild.data = (f"cn=DNS_edir-,{server_con}")
    if element.firstChild and element.firstChild.data == admin_group :
        element.firstChild.data = (f"cn=admingroup,{server_con}")
    if element.firstChild and element.firstChild.data == ws_context :
        element.firstChild.data = server_con
    if element.firstChild and element.firstChild.data == post_script :
        element.firstChild.data = ssh_content
    if element.firstChild and element.firstChild.data == ip_addr :
        element.firstChild.data = ip
    if element.firstChild and element.firstChild.data == ipaddr :
        element.firstChild.data = ip
    if element.firstChild and element.firstChild.data == nssadmin :
        element.firstChild.data = (f"cn={hostname}admin.{modified_server}")
    if element.firstChild and element.firstChild.data == partition_root :
        element.firstChild.data = modified_server
    if element.firstChild and element.firstChild.data == proxy_user :
        element.firstChild.data = (f"cn=OESCommonProxy_{hostname},{server_con}")
    if element.firstChild and element.firstChild.data == users :
        element.firstChild.data = user_content
    


with open(f'{path}/vms/{vm_name}/{vm_name}.xml', 'w') as file:
    dom.writexml(file)


with open(f'{path}/Vms/{vm_name}/{vm_name}.xml', 'r') as file:
    xml_data = file.read()

# Replace &lt; with <
xml_data = xml_data.replace('&lt;', '<')

# Replace &gt; with >
xml_data = xml_data.replace('&gt;', '>')
xml_data = xml_data.replace('&quot;', '"')
# Write the modified XML back to the file
with open(f'{path}/Vms/{vm_name}/{vm_name}.xml', 'w') as file:
    file.write(xml_data)


