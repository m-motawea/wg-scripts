#!/bin/bash

ns_array=(router server client-1 client-2)
if_array=(sr cr1 cr2)


echo "cleaning network namespaces..."
for ns in ${ns_array[@]}
do
  echo "deleting namespace ${ns}..."
  sudo ip netns del ${ns}
  echo "${ns} namespace deleted."
done
echo "finished cleaning network namespaces."


echo "cleaning ifaces..."
for iface in ${if_array[@]}
do
  echo "deleteing iface ${iface}..."
  sudo ip link delete ${iface}
  echo "iface ${iface} deleted."
done
echo "finished cleaning ifaces."

echo "removing keys..."
rm -f server_private_key
rm -f client1_private_key
rm -f client2_private_key
rm -f server_publickey
rm -f client1_publickey
rm -f client2_publickey
echo "keys removed."

sudo sh -c 'echo "" > /etc/sysctl.conf'