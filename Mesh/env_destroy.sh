#!/bin/bash

ns_array=(router server-1 server-2 nat-1 nat-2 client-1 client-2)
if_array=(rn1 rn2 rs1 rs2 nc1 nc2)


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
rm -f server1_privatekey
rm -f server2_privatekey
rm -f client1_privatekey
rm -f client2_privatekey
rm -f server1_publickey
rm -f server2_publickey
rm -f client1_publickey
rm -f client2_publickey
echo "keys removed."

echo "removing wg config.."
rm -f wg*
echo "wg config removed"

sudo sh -c 'echo "" > /etc/sysctl.conf'