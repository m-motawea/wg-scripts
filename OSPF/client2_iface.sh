#!/bin/bash

set -e

sh -c 'echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf'
sh -c 'echo "net.ipv4.conf.all.proxy_arp = 1" >> /etc/sysctl.conf'
sysctl -p /etc/sysctl.conf

ip link add c2wg3 type wireguard
ip link set c2wg3 up
ip addr add 10.3.3.2/30 dev c2wg3
wg setconf c2wg3 c2wg3.conf


ip link add c2wg5 type wireguard
ip link set c2wg5 up
ip addr add 10.5.5.2/30 dev c2wg5
wg setconf c2wg5 c2wg5.conf