#!/bin/bash
vm_name=$1

readarray -t array <<< "$(jq -r '.[] | @json' "user.json")"
for item in "${array[@]}"; do
    username=$(echo "$item" | jq -r '.username')
    password=$(echo "$item" | jq -r '.password')
    name=$(echo "$item" | jq -r '.full_name')
    script_content="
    <user t=\"map\">
      <encrypted t=\"boolean\">false</encrypted>
      <fullname>$name</fullname>
      <home>/home/$username</home>
      <username>$username</username>
      <user_password>$password</user_password>
    </user>"
    # script_content=$(echo "$script_content" | iconv -c -t UTF-8)
    script_content=$(echo "$script_content")
    # Create the new script file
    echo -e "${script_content}" >> "vms/${vm_name}/user.sh"
done

# chmod +x "vms/${vm_name}/user.sh"