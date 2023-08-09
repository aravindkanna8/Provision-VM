#!/bin/bash
VM_NAME=$1

mac_aadr=$(jq '.NIC1.MAC' <vms/$VM_NAME/network.json | tr -d '"')
ip=$(jq '.network.ip' <vms/$VM_NAME/$VM_NAME.json | tr -d '"')

extract_network_part() {
  local ip=$1
  network_part=$(echo "$ip" | cut -d'.' -f1-3)
  echo "$network_part"
}

network=$(extract_network_part "$ip")
for host in {1..254}; do
    ip_address="$network.$host"
    ping -n 1 -w 1 "$ip_address" >/dev/null 2>&1
done

desired_mac_address=$(echo "$mac_aadr" | tr '[:upper:]' '[:lower:]')
formatted_mac_address=$(echo "$desired_mac_address" | sed -E 's/(..)/\1-/g; s/-$//')

initial_ip=$(arp -a | grep -i "$formatted_mac_address" | awk '{print $1}' | tr -d '()')

echo "$initial_ip" > vms/$VM_NAME/ip_address.txt
