#!/bin/bash

# VM_NAME="BaseVM"
# VM_NAME=$(jq '.vm_name' <$1 | tr -d '"')
VM_NAME=$1

# Get the number of NICs attached to the virtual machine
NIC_COUNT=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep -c "^nic")

# Iterate over each NIC and retrieve MAC address and interface name
json_data="{"
for ((nic=1; nic<=NIC_COUNT; nic++)); do
  MAC_ADDRESS=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep "macaddress$nic" | cut -d'"' -f2)
  INTERFACE_NAME=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep "^nic$nic=" | cut -d'"' -f2)
  Attachment=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep "hostonlyadapter$nic" | cut -d'"' -f2)

  # Add NIC data to the JSON object
  json_data+="\n  \"NIC$nic\": {\n      \"MAC\":\"$MAC_ADDRESS\",\n      \"Interface\":\"$INTERFACE_NAME\",\n      \"Attachment\":\"$Attachment\"\n },"
done

# Remove the trailing comma and close the JSON object
json_data="${json_data%,}\n}"

# Store the information in network.json
echo -e "$json_data" > vms/$VM_NAME/network.json

echo "MAC Addresses Fetched.........."
