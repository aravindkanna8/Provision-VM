#!/bin/bash

# Set the desired VM name
vm_name=$(jq '.vm_name' <$1 | tr -d '"')
cluster=$(jq '.cluster.cluster' <$1 | tr -d '"')
cluster_mode=$(jq '.cluster.cluster_mode' <$1 | tr -d '"')

website_path=$(cat "vms/vms.txt")
website=$(echo "$website_path" | sed 's/^▒▒//')
websitepart=$(echo "$website" | sed 's#\(http[s]*://[^:]*\).*#\1#')


generate_random_number() {
    min=10000000
    max=99999999

    # Generate a random number within the specified range
    range=$((max - min + 1))
    random_number=$((RANDOM % range + min))
    
    echo "$random_number"
}

save_to_file() {
    random_number="$2"
    file="secret_num.txt"
    touch vms/$vm_name/$file
    # Save the number to the file
    echo "$random_number" > "vms/$vm_name/$file"
}

random_number=$(generate_random_number)
save_to_file "$vm_name" "$random_number"


# Define the script file name
script_file="vmssh.sh"

if [[ $cluster == "True" && $cluster_mode == "new" ]]; then
    cluster_part='nlvm init sdb format=gpt shared --no-prompt\nnlvm init sdc format=gpt shared --no-prompt'
else
    cluster_part=""
fi

# Generate the script content with the updated VM name

script_content="#!/bin/bash\n\n${cluster_part}\ncurl -i -H \"X-Value: ${random_number}\" --cacert ~/ca.pem ${websitepart}:6443/send-file/${vm_name}\nsed -i \"\$ a\\HostKey /etc/ssh/${vm_name}\" /etc/ssh/sshd_config\nsed -i \"\$ a\\HostCertificate /etc/ssh/${vm_name}-cert.pub\" /etc/ssh/sshd_config\nchmod o-r,g-r \"/etc/ssh/${vm_name}\"\nchmod 644 /etc/ssh/ca-auth.pub\nsed -i '\$ a\\TrustedUserCAKeys /etc/ssh/ca-auth.pub' /etc/ssh/sshd_config\nsed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication "yes"/' /etc/ssh/sshd_config\nsed -i 's/#PasswordAuthentication.*/PasswordAuthentication "no"/' /etc/ssh/sshd_config\nsed -i 's/#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication "no"/' /etc/ssh/sshd_config\nsystemctl restart sshd\n"

script_content=$(echo "$script_content" | iconv -c -t UTF-8)
# Create the new script file
echo -e "${script_content}" > "vms/${vm_name}/${script_file}"

# Make the script file executable
chmod +x "vms/${vm_name}/${script_file}"