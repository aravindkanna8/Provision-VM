#!/bin/bash
sudo zypper refresh
sudo zypper install jq

current_dir=$(pwd)
oes_iso_url=$(jq '.iso_url' <server-config.json | tr -d '"')
basevm_xml_url=$(jq '.basevm_autoyast_url' <server-config.json | tr -d '"')
ntp_allowed_ip=$(jq '.ntp_allowed_ip' <server-config.json | tr -d '"')
server_ip=$(jq '.server_ip' <server-config.json | tr -d '"')
range=$(jq '.dhcp_range' <server-config.json | tr -d '"')  
name=$(hostname)
eth_line=$(ip -4 addr show | awk "/inet $server_ip/ {print $NF}")
eth=$(echo${eth_line} | awk '{print $NF}')

wget --no-check-certificate $basevm_xml_url -o /root/BaseVM.xml

dest_folder="/root/"
# Destination path to save the downloaded ISO file
part=$(echo "$oes_iso_url" | awk -F"/" '{print $8}')
destination_path="$dest_folder$part"
dest_folder=$(echo "$oes_iso_url" | awk -F"/" '{print $8}' | awk -F"." '{print $1}')

#Create the mount point directory if it doesn't exist
sudo mkdir -p /srv/install
sudo mkdir -p /srv/$dest_folder
 
# Check if the ISO file already exists
if [ -f "$destination_path" ]; then
    echo "ISO file already exists. Skipping download."
    tmp=$(mktemp)
else
    # Download the ISO file using curl
    echo "Installing the iso file from the url = $oes_iso_url"
    curl -o "$destination_path" "$oes_iso_url"

    # Check if the download was successful
    if [ $? -eq 0 ]; then
        echo "ISO file downloaded successfully."
        #Path to the ISO file
        iso_file="$destination_path"
        sudo mount -o loop $iso_file /srv/$dest_folder
        cp -r /srv/$dest_folder /srv/install
        sudo umount /srv/$dest_folder
        sudo rm -r /srv/$dest_folder
    else
        echo "Failed to download the ISO file."
        exit 1
    fi
fi

 

# Check if the ISO file is present
if [ -f "$destination_path" ]; then
    # Extract the file name from the destination path
    iso_filename=$(basename "$destination_path")
    # Check if the ISO file size is non-zero
    if [ -s "$destination_path" ]; then
        echo "OES ISO installation is completed. ISO file: $iso_filename"
    else
        echo "OES ISO installation is not completed. ISO file: $iso_filename is empty."
    fi
else
    echo "OES ISO installation is not completed. ISO file does not exist."
fi

# Install required packages
zypper install -y nfs-kernel-server tftp dhcp-server


# NTP server configuration
echo ""
echo 'Configuring NTP Server ...'
sed -i -e "\$aallow  $ntp_allowed_ip" /etc/chrony.conf
sudo firewall-cmd --add-service=ntp --permanent
sudo firewall-cmd --reload

#restart ntp
sudo systemctl restart chronyd
echo 'NTP Server configured...'
sleep 2

#SLP SETUP
echo 'Configuring SLP Server ...'
sudo systemctl start slpd
sudo systemctl enable slpd
sudo systemctl restart slpd
echo 'SLP Server configured...'
sleep 2

#setup nfs server
echo 'Configuring NFS Server ...'
sudo sed -i '$ a /srv/install *(ro,root_squash,sync)' /etc/exports
systemctl enable nfsserver
sudo firewall-cmd --add-service=nfs --permanent
sudo firewall-cmd --reload
systemctl start nfsserver
systemctl restart nfsserver

#Announcing the NFS server via OpenSLP
sudo tee "/etc/slp.reg.d/install.suse.nfs.reg" > /dev/null <<EOL
# Register the NFS Installation Server
service:install.suse:nfs://\$HOSTNAME/$dest_folder,en,65535
description=NFS Repository
EOL

systemctl start slpd
echo 'NFS Server configured...'
sleep 2

#DHCP configuration:
echo 'Configuring DHCP Server ...'
cat << EOF | sudo tee "/etc/dhcpd.conf" > /dev/null
option domain-name "$name";
option domain-name-servers $server_ip;
option routers 192.168.56.1;
option ntp-servers $server_ip;
default-lease-time 3600;
ddns-update-style none;
option arch code 93 = unsigned integer 16; # RFC4578
subnet 192.168.56.0 netmask 255.255.255.0 {
  next-server $server_ip;
  range $range;
  default-lease-time 3600;
  max-lease-time 4600;
 if option arch = 00:07 or option arch = 00:09 {
   filename "/EFI/x86/grub.efi";
 }
 else if option arch = 00:0b {
   filename "/EFI/aarch64/bootaa64.efi";
 }
 else  {
   filename "pxelinux.0";
 }
}
EOF

sed -i "s/DHCPD_INTERFACE=.*/DHCPD_INTERFACE=\"$eth\"/" /etc/sysconfig/dhcpd

sudo firewall-cmd --add-service=dhcp --permanent
sudo firewall-cmd --reload

systemctl enable dhcpd
systemctl restart dhcpd
echo 'DHCP Server configured...'
sleep 2


#TFTP configuration
echo 'Configuring TFTP Server ...'
sudo systemctl enable tftp.socket
sudo systemctl restart tftp.socket

mkdir -p /srv/tftpboot
mkdir -p /srv/tftpboot/pxelinux.cfg
cp /usr/share/syslinux/pxelinux.0 /srv/tftpboot

# Content for the PXE config file
echo 'Configuring PXE Server ...'
pxe_content="
default install
prompt   1
timeout  30

# Install 
label install
  kernel linux
  append initrd=initrd splash=silent vga=0x314 showopts install=nfs://$server_ip/srv/install/$dest_folder
"

# Write the content to the PXE config file
echo "$pxe_content" | sudo tee "/srv/tftpboot/pxelinux.cfg/default" > /dev/null
echo 'TFTP Server configured...'
sleep 2

cp /srv/install/$dest_folder/boot/x86_64/loader/linux /srv/tftpboot
cp /srv/install/$dest_folder/boot/x86_64/loader/initrd /srv/tftpboot
cp  BaseVM.xml /srv/install/$dest_folder/autoinst.xml
sudo firewall-cmd --add-service=tftp --permanent
sudo firewall-cmd --reload


sudo systemctl restart tftp.socket
sudo systemctl restart tftp
echo 'TFTP Server configured...'
sleep 2


