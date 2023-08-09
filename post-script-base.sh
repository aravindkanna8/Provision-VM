#!/bin/bash

# Set the desired VM names
vm_name=$(jq '.vm_name' <$1 | tr -d '"')
https_ca_file_path="vms/${vm_name}/ca.pem"


# # Define the script file name
script_file="vmssh.sh"
https_ca_file_content=$(<${https_ca_file_path})

script_content="#!/bin/bash\n\necho '"$https_ca_file_content"' | tee "/root/ca.pem" \n\nchmod 644 /root/ca.pem\n\n"

script_content=$(echo "$script_content" | iconv -c -t UTF-8)
# Create the new script file
echo -e "${script_content}" > "vms/${vm_name}/${script_file}"

# Make the script file executable
chmod +x "vms/${vm_name}/${script_file}"