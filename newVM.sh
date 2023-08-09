#!/usr/bin/bash

path=$(pwd)/vms/$1/$1.json
echo $path

vm_name=$(jq '.vm_name' <$path | tr -d '"')
ostype=$(jq '.os_type' <$path | tr -d '"')
memory=$(jq '.memory' <$path | tr -d '"')
cpu=$(jq '.cpu' <$path | tr -d '"')
hdsize=$(jq '.hdsize' <$path | tr -d '"')
nic1=$(jq '.nic1.nic' <$path | tr -d '"')
nettype1=$(jq '.nic1.typenet1' <$path | tr -d '"')
namenet1=$(jq '.nic1.netName1' <$path | tr -d '"')
nic2=$(jq '.nic2.nic' <$path | tr -d '"')
nettype2=$(jq '.nic2.typenet2' <$path | tr -d '"')
namenet2=$(jq '.nic2.netName2' <$path | tr -d '"')
nic3=$(jq '.nic3.nic' <$path | tr -d '"')
nettype3=$(jq '.nic3.typenet3' <$path | tr -d '"')
namenet3=$(jq '.nic3.netName3' <$path | tr -d '"')
nic4=$(jq '.nic4.nic' <$path | tr -d '"')
nettype4=$(jq '.nic4.typenet4' <$path | tr -d '"')
namenet4=$(jq '.nic4.netName4' <$path | tr -d '"')
iso=$(jq '.iso' <$path | tr -d '"')
clone=$(jq '.clone' <$path | tr -d '"')
ip=$(jq '.network.ip' <$path | tr -d '"')
mode=$(jq '.edirectory.mode' <$path | tr -d '"')
hostname=$(jq '.network.hostname' <$path | tr -d '"')

certificate_file=$(jq '.sshops.certificate_file' <config.json | tr -d '"')
identity_file=$(jq '.sshops.identity_file' <config.json | tr -d '"')

echo $ip $mode

function delete_vm() {
    echo ""
    echo "Are you sure? Current progress of the new VM will be deleted (yes|no)"
    read input
    if [[ $input == "yes" ]]; then
        rm -r ~/Desktop/Bash/vms/$vm_name
        rm -r ~/.ssh/$vm_name
        vboxmanage controlvm "${vm_name}" poweroff 2>>$PWD/vboxlogs
        sleep 5
        vboxmanage unregistervm "${vm_name}" --delete-all 2>>$PWD/vboxlogs
        exit 1
    elif [[ $input == "no" ]]; then
        return 1
    fi

}

trap delete_vm SIGINT


source clonebuild.sh $path

