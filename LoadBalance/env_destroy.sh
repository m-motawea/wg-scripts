#!/bin/bash

ns_array=(h1 h2)
if_array=(l1-h1 l2-h1)


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
rm -f host1_privatekey
rm -f host2_privatekey
rm -f host1_publickey
rm -f host2_publickey
echo "keys removed."

echo "removing wg config.."
rm -f wg*
echo "wg config removed"

sudo sh -c 'echo "" > /etc/sysctl.conf'