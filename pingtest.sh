#!/usr/bin/bash

echo "Autoinst file is configuring your system.....!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "Setting up the IP Address !!!!!!!!!!!!"
while ! ping $ip &> pingLogs || ! grep -q "Received = 4" pingLogs; do
  sleep 5
done

echo "IP Address set-up done."
echo "Setting up E-directory "
while ! ldapsearch -x -H ldap://$ip -s base -b "" "objectclass=*" 2>&1 | grep -q "result: 0 Success";do
  sleep 25
done
echo "E-directory setup done."
sleep 10
