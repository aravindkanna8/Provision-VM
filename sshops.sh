#!/usr/bin/bash

ip=$(jq '.network.ip' <$2 | tr -d '"')
mode=$(jq '.edirectory.mode' <$2 | tr -d '"')
autoinst_path=$(jq '.sshops.autoinst_path' <config.json | tr -d '"')
root_pswd=$(jq '.clone.root_pswd' <config.json | tr -d '"')
ca_key_name=$(jq '.sshops.ca_key_name' <config.json | tr -d '"')


sshpass -p $root_pswd ssh root@$ip "chmod 644 /etc/ssh/$ca_key_name"
sshpass -p $root_pswd ssh root@$ip "sed -i -e '\$aTrustedUserCAKeys /etc/ssh/$ca_key_name' /etc/ssh/sshd_config"
sshpass -p $root_pswd ssh root@$ip "sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication "yes"/' /etc/ssh/sshd_config"
sshpass -p $root_pswd ssh root@$ip "sed -i 's/#PasswordAuthentication.*/PasswordAuthentication "no"/' /etc/ssh/sshd_config"
sshpass -p $root_pswd ssh root@$ip "sed -i 's/#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication "no"/' /etc/ssh/sshd_config"

sshpass -p $root_pswd ssh root@$ip "systemctl restart sshd"
