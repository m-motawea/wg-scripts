#!/bin/bash

ns_array=(peer1 peer2)
if_array=(p1 p2 net1 net2)


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
rm -f peer1_private_key
rm -f peer2_private_key
rm -f peer1_publickey
rm -f peer2_publickey
echo "keys removed."

sudo sh -c 'echo "" > /etc/sysctl.conf'