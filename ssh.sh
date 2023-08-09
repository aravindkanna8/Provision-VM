#!/usr/bin/bash
vm_name=$(jq '.vm_name' <$1 | tr -d '"')
cluster=$(jq '.cluster.cluster' <$1 | tr -d '"')
pass=$(jq '.sshops.passphrase' <config.json | tr -d '"')
# username=$(jq '.user1.username' <user.json | tr -d '"')

dir="/home/mobaxterm/.ssh/ca-keys"

if [ -d "$dir" ]; then
    echo ""
    echo "User CA keys already set"
else
    echo "generating user-ca keys......."
    mkdir ~/.ssh/ca-keys
    ssh-keygen -t ed25519 -f ~/.ssh/ca-keys/ca-auth -C 'ca-auth' -P "$pass" > /dev/null
    echo ""
    echo "Adding the ca-key to ssh agent"
    ssh-add ~/.ssh/ca-keys/ca-auth 
    echo ""
fi

readarray -t array <<< "$(jq -r '.[] | @json' "user.json")"
for item in "${array[@]}"; do
    username=$(echo "$item" | jq -r '.username')
    # password=$(echo "$item" | jq -r '.password')
    dir1="/home/mobaxterm/.ssh/$username"
    if [ -d "$dir1" ]; then
        echo ""
        echo "$username keys are already set"
    else
        mkdir ~/.ssh/$username
        ssh-keygen -t ed25519 -f ~/.ssh/$username/$username-key -C 'user-keys' -P "$pass" > /dev/null
        echo ""
        echo "Adding the user key to ssh agent"
        ssh-add ~/.ssh/$username/$username-key 
        echo " "

        echo "Signing the $username key with the ca key"
        ssh-keygen -s ~/.ssh/ca-keys/ca-auth -I 'user-certify' -n $username -V +1w ~/.ssh/$username/$username-key.pub

        tmp=$(mktemp)
        jq --arg path "/home/mobaxterm/.ssh/ca-keys/ca-auth.pub" '.sshops.ca_key_path = $path' config.json > "$tmp" && mv "$tmp" config.json
        jq --arg name "ca-auth.pub" '.sshops.ca_key_name = $name' config.json > "$tmp" && mv "$tmp" config.json
        jq --arg cert "/home/mobaxterm/.ssh/$username/$username-key-cert.pub" '.sshops.certificate_file = $cert' config.json > "$tmp" && mv "$tmp" config.json
        jq --arg id "/home/mobaxterm/.ssh/$username/$username-key" '.sshops.identity_file = $id' config.json > "$tmp" && mv "$tmp" config.json
    fi
done

if [[ $cluster == True ]]; then
    dir2="/home/mobaxterm/.ssh/root"
    if [ -d "$dir2" ]; then
        echo ""
        echo "root keys are already set"
    else
        mkdir ~/.ssh/root
        ssh-keygen -t ed25519 -f ~/.ssh/root/root-key -C 'root-keys' -P "$pass" > /dev/null
        echo ""
        echo "Adding the root user key to ssh agent"
        ssh-add ~/.ssh/root/root-key 
        echo " "

        echo "Signing the root key with the ca key"
        ssh-keygen -s ~/.ssh/ca-keys/ca-auth -I 'root-certify' -n root -V +12h ~/.ssh/root/root-key.pub
    fi
fi