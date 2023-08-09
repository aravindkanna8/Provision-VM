#!/usr/bin/bash

snapshot=$(jq '.clone.snapshot' <config.json | tr -d '"')
base_vm=$(jq '.clone.name' <config.json | tr -d '"')
root_pswd=$(jq '.clone.root_pswd' <config.json | tr -d '"')
certificate_file=$(jq '.sshops.certificate_file' <config.json | tr -d '"')
identity_file=$(jq '.sshops.identity_file' <config.json | tr -d '"')
root_certificate_file=$(jq '.sshops.root_certificate_file' <config.json | tr -d '"')
root_identity_file=$(jq '.sshops.root_identity_file' <config.json | tr -d '"')
passphrase=$(jq '.sshops.passphrase' <config.json | tr -d '"')

cluster=$(jq '.cluster.cluster' <$1 | tr -d '"')
treename=$(jq '.edirectory.treename' <$1 | tr -d '"')
basetree=$(jq '.edirectory.base_tree' <$1 | tr -d '"')
cluster_name=$(jq '.cluster.cluster_name' <$1 | tr -d '"')
cluster_ip=$(jq '.cluster.cluster_ip' <$1 | tr -d '"')
replica_ip=$(jq '.edirectory.replicaIP' <$1 | tr -d '"')
cluster_mode=$(jq '.cluster.cluster_mode' <$1 | tr -d '"')


VBoxManage clonevm "${base_vm}" --name="${vm_name}" --register --options=Link --snapshot="${snapshot}"

if [[ $cluster == "True" && $cluster_mode == "new" ]]; then
    VBoxManage createhd --filename VirtualBox\ VMs/"${treename}_${cluster_name}_sdb1.vdi" --size 1024 --variant Fixed
    VBoxManage modifyhd  VirtualBox\ VMs/"${treename}_${cluster_name}_sdb1.vdi" --type shareable
    VBoxManage createhd --filename VirtualBox\ VMs/"${treename}_${cluster_name}_sdb2.vdi" --size 1024 --variant Fixed
    VBoxManage modifyhd  VirtualBox\ VMs/"${treename}_${cluster_name}_sdb2.vdi" --type shareable
    VBoxManage storageattach ${vm_name} --storagectl "SATA Controller" --port 1 --device 0 --type hdd --medium VirtualBox\ VMs/"${treename}_${cluster_name}_sdb1.vdi"
    VBoxManage storageattach ${vm_name} --storagectl "SATA Controller" --port 2 --device 0 --type hdd --medium VirtualBox\ VMs/"${treename}_${cluster_name}_sdb2.vdi"
elif [[ $cluster == "True" && $cluster_mode == "existing" ]]; then
    while ! (vboxmanage list hdds | grep -q "${basetree}_${cluster_name}_sdb1.vdi" && vboxmanage list hdds | grep -q "${basetree}_${cluster_name}_sdb2.vdi"); do
        echo "waiting for vdi's to create.........."
        sleep 10
    done
    echo "Vdi's created and attaching to this vm........"
    VBoxManage storageattach ${vm_name} --storagectl "SATA Controller" --port 1 --device 0 --type hdd --medium VirtualBox\ VMs/"${basetree}_${cluster_name}_sdb1.vdi"
    VBoxManage storageattach ${vm_name} --storagectl "SATA Controller" --port 2 --device 0 --type hdd --medium VirtualBox\ VMs/"${basetree}_${cluster_name}_sdb2.vdi"
fi

#Calling the MAC addresses file
source getmac.sh ${vm_name}

VBoxManage startvm "${vm_name}" --type=gui
sleep 120

#retriving the ip and shaving it in ip_addresses.txt
source retrieve_ip.sh ${vm_name}

#reading the ip address
ip_path="vms/${vm_name}/ip_address.txt"
initial_ip=$(<${ip_path})  

website_path=$(cat "vms/vms.txt")
# Filter out lines starting with "▒▒" and extract URLs using grep
website=$(echo "$website_path" | grep -oE 'https://[^/]*')

if [[ $mode == "existing" ]]; then
    echo "Setting up E-directory for the root tree  ...!!!!!!!!!!!!!!"
    echo -n "Waiting for E-directory for the root tree to come-up."
    while ! ldapsearch -x -H ldap://$replica_ip -s base -b "" "objectclass=*" 2>&1 | grep -q "result: 0 Success"; do
        echo -n "."
        sleep 15
    done
    echo "."
    sleep 70
    sshpass -p ${root_pswd} ssh -o "StrictHostKeyChecking=no" root@${initial_ip} "systemctl stop ndsd.service && rm -f /etc/opt/novell/eDirectory/conf/nds.conf && rm -f /etc/opt/novell/eDirectory/conf/.edir/instances.0 && rm -rf /var/opt/novell/eDirectory/data/dib" >/dev/null 2>&1
    echo "E-directory setup for the Root Tree is done."
fi

sshpass -p ${root_pswd} ssh -o "StrictHostKeyChecking=no" root@${initial_ip} "systemctl stop ndsd.service && rm -f /etc/opt/novell/eDirectory/conf/nds.conf && rm -f /etc/opt/novell/eDirectory/conf/.edir/instances.0 && rm -rf /var/opt/novell/eDirectory/data/dib" >/dev/null 2>&1
sshpass -p ${root_pswd} ssh -o "StrictHostKeyChecking=no" root@${initial_ip} "curl --cacert ~/ca.pem $website/${vm_name}/$vm_name.xml --output $vm_name.xml" >/dev/null 2>&1
sshpass -p ${root_pswd} ssh -o "StrictHostKeyChecking=no" -f root@${initial_ip} "sudo openvt -l -w -- yast2 ayast_setup setup filename=~/${vm_name}.xml dopackages='yes'"

source pingtest.sh

echo -n "Waiting for the post script to execute"
file_to_check="vms/${vm_name}/post.txt"
while [ ! -f "$file_to_check" ]; do
  echo -n "."
  sleep 10  # Adjust the sleep duration (in seconds) as needed
done

echo "."
echo "Postscript is executed."
sed -i "/${initial_ip}/d" ~/.ssh/known_hosts
sleep 60


if [[ $cluster == True ]]; then
    if [[ $cluster_mode == "existing" ]]; then
        echo -n "Cluster is not up. PLease wait ."
        while ! ping $cluster_ip &> pingLogs || ! grep -q "Received = 4" pingLogs; do
            echo -n "."
            sleep 15
        done
        echo "."
        echo "Cluster is now up !!!!"
        echo "Adding this node to the Cluster!!!!!!!!"
        sleep 30
        ssh -o CertificateFile=$root_certificate_file -i $root_identity_file root@$ip "openvt -l -w -- /usr/lib/YaST2/bin/y2base ncs ncurses --macro /root/existingclustermacro.ycp"
    else
        echo ""
        echo "Configuring the Cluster for this vm. PLease wait ..."
        ssh -o CertificateFile=$root_certificate_file -i $root_identity_file root@$ip "openvt -l -w -- /usr/lib/YaST2/bin/y2base ncs ncurses --macro /root/newclustermacro.ycp"
    fi
fi

username=$(jq '.user1.username' <user.json | tr -d '"')
certificate_file=$(jq '.sshops.certificate_file' <config.json | tr -d '"')
identity_file=$(jq '.sshops.identity_file' <config.json | tr -d '"')

name="$(grep "Host ${vm_name}" ~/.ssh/config)"

if [ -z "$name" ]; then
    sed -i -e "\$aHost ${vm_name}\\
        Hostname ${ip}\\
        User $username\\
        Port 22\\
        IdentityFile $identity_file\\
        CertificateFile $certificate_file\\" ~/.ssh/config
else
    echo "host already exists in the file"
fi

echo "Config is set with the certificates"
echo ""
echo "You can use the VM name for logging in to the server eg: ssh $vm_name" 
echo "You can use the VM name for logging in to the server eg: ssh -o CertificateFile=$certificate_file -i $identity_file $username@$ip" 


ssh -o CertificateFile=$certificate_file -i $identity_file $username@$ip