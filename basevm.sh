#!/usr/bin/bash

# Extract VM parameters from JSON file using jq and remove quotes using tr
vm_name=$(jq '.vm_name' <$1 | tr -d '"')
ostype=$(jq '.os_type' <$1 | tr -d '"')
memory=$(jq '.memory' <$1 | tr -d '"')
cpu=$(jq '.cpu' <$1 | tr -d '"')
hdsize=$(jq '.hdsize' <$1 | tr -d '"')
nic1=$(jq '.nic1.nic' <$1 | tr -d '"')
nettype1=$(jq '.nic1.typenet1' <$1 | tr -d '"')
namenet1=$(jq '.nic1.netName1' <$1 | tr -d '"')
nic2=$(jq '.nic2.nic' <$1 | tr -d '"')
nettype2=$(jq '.nic2.typenet2' <$1 | tr -d '"')
namenet2=$(jq '.nic2.netName2' <$1 | tr -d '"')
nic3=$(jq '.nic3.nic' <$1 | tr -d '"')
nettype3=$(jq '.nic3.typenet3' <$1 | tr -d '"')
namenet3=$(jq '.nic3.netName3' <$1 | tr -d '"')
nic4=$(jq '.nic4.nic' <$1 | tr -d '"')
nettype4=$(jq '.nic4.typenet4' <$1 | tr -d '"')
namenet4=$(jq '.nic4.netName4' <$1 | tr -d '"')


# Function to delete VM and associated progress
function delete_vm() {
    echo ""
    echo "Are you sure? Current progress of the new VM will be deleted (yes|no)"
    read input
    if [[ $input == "yes" ]]; then
        rm -r vms/$vm_name
        vboxmanage controlvm "${vm_name}" poweroff 2>>$PWD/vboxlogs
        sleep 5
        vboxmanage unregistervm "${vm_name}" --delete-all 2>>$PWD/vboxlogs
        exit 1
    elif [[ $input == "no" ]]; then
        return 1
    fi
}

# Trap SIGINT (Ctrl+C) to invoke delete_vm function
trap delete_vm SIGINT

# Create a new VM using VBoxManage
VBoxManage createvm --name "${vm_name}" --ostype ${ostype} --register
VBoxManage modifyvm "${vm_name}" --memory "${memory}"
VBoxManage modifyvm "${vm_name}" --cpuhotplug on
VBoxManage modifyvm "${vm_name}" --cpus "${cpu}"
vboxmanage modifyvm "${vm_name}" --graphicscontroller VMSVGA
vboxmanage modifyvm "${vm_name}" --vrde off

# Modify NIC settings if NIC1 is specified
if [ -n "${nic1}" ]; then
    VBoxManage modifyvm "${vm_name}" --nic1 "${nic1}"
    VBoxManage modifyvm "${vm_name}" "--${nettype1}" "${namenet1}"
fi

# Modify NIC settings if NIC2 is specified
if [ -n "${nic2}" ]; then
    VBoxManage modifyvm "${vm_name}" --nic2 "${nic2}"
    VBoxManage modifyvm "${vm_name}" "--${nettype2}" "${namenet2}"
fi

# Modify NIC settings if NIC3 is specified
if [ -n "${nic3}" ]; then
    VBoxManage modifyvm "${vm_name}" --nic3 "${nic3}"
    VBoxManage modifyvm "${vm_name}" "--${nettype3}" "${namenet3}"
fi

# Modify NIC settings if NIC4 is specified
if [ -n "${nic4}" ]; then
    VBoxManage modifyvm "${vm_name}" --nic4 "${nic4}"
    VBoxManage modifyvm "${vm_name}" "--${nettype4}" "${namenet4}"
fi

#Calling the MAC addresses file
source getmac.sh ${vm_name}

# Create a new virtual hard disk and attach it to the VM
VBoxManage createhd --filename VirtualBox\ VMs/"${vm_name}"/"${vm_name}".vdi --size ${hdsize} --format VDI
VBoxManage storagectl "${vm_name}" --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storageattach "${vm_name}" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium VirtualBox\ VMs/"${vm_name}"/"${vm_name}".vdi
VBoxManage storagectl "${vm_name}" --name "IDE Controller" --add ide --controller PIIX4
VBoxManage modifyvm "${vm_name}" --boot1 disk --boot2 net --boot3 none --boot4 none
vboxmanage modifyvm "${vm_name}" --usbehci on --usbohci on --usbxhci on



# Start the VM and wait for it to boot
VBoxManage startvm "${vm_name}" --type=headless

#retriving the mac address
current_dir=$(pwd)
Macaddress=$(jq '.NIC1.MAC' <$current_dir/vms/"${vm_name}"/network.json | tr -d '"')
Attachment=$(jq '.NIC1.Attachment' <$current_dir/vms/"${vm_name}"/network.json | tr -d '"')

# Monitor the VM state until it is powered off
echo "Setting up the system & Installing Packages........"
duration=$((5))
interval=3  # in minutes
for ((i=0; i<duration; i++)); do
    percentage=$((i * 10))
    echo -n " $percentage%"
    for ((j=0; j<interval; j++)); do
        echo -n "."
        sleep 60
    done
    echo -n "."
done
i=5
while true; do
    VM_STATE=$(VBoxManage showvminfo "$vm_name" --machinereadable | grep "VMState=" | cut -d'"' -f2)
    if [ "$VM_STATE" = "running" ]; then
        duration1=$((10))
        interval1=1
        if ((i < 10)); then
            for ((i=5; i<duration1; i++)); do
                percentage=$((i * 10))
                echo -n " $percentage%"
                for ((j=0; j<interval1; j++)); do
                    echo -n "."
                    sleep 60
                done
                echo -n "."
            done
        else
            sleep 60
            echo -n "."
        fi
    else
        echo "100%"
        echo "VM has Powered OFF......Taking snapshot........."
        VBoxManage snapshot ${vm_name} take cloning --description="base clone"
        break
    fi
done

#updating the config.json file
tmp=$(mktemp)
jq --arg name "$vm_name" '.clone.name = $name' config.json > "$tmp" && mv "$tmp" config.json

