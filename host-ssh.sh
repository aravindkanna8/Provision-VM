# ip=$(jq '.network.ip' <$1 | tr -d '"')
root_pswd=$(jq '.clone.root_pswd' <config.json | tr -d '"')
passphrase=$(jq '.sshops.passphrase' <config.json | tr -d '"')
ssh_path=$(jq '.sshops.ssh_path' <config.json | tr -d '"')

vm_name=$(jq '.vm_name' <$1 | tr -d '"')
host=$(jq '.network.hostname' <$1 | tr -d '"')
ip=$(jq '.network.ip' <$1 | tr -d '"')

dir="$ssh_path/host-ca"

if [ -d "$dir" ]; then
    echo ""
    echo "host CA keys already set"
else
    echo "generating Host-ca keys......"
    mkdir ~/.ssh/host-ca
    ssh-keygen -t ed25519 -f ~/.ssh/host-ca/host-auth -C 'host-auth' -P "$passphrase" > /dev/null
    echo ""
    echo "Adding the host-ca-key to ssh agent"
    ssh-add ~/.ssh/host-ca/host-auth 
    echo ""
fi

mkdir $ssh_path/$vm_name
echo "Generating Host keys..........."
ssh-keygen -t ed25519 -f $ssh_path/$vm_name/$vm_name -q -P "" -C "root@$host" > /dev/null
echo ""
echo "Signing the host certificate using host ca key"
ssh-keygen -s ~/.ssh/host-ca/host-auth -I 'host-certify' -n $ip -V +12w -h $ssh_path/$vm_name/$vm_name.pub

echo "@cert-authority * $(cat "/home/mobaxterm/.ssh/host-ca/host-auth.pub" | tr '\n' ' ')" > ~/.ssh/known_hosts
