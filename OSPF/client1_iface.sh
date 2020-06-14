#!/bin/bash

set -e

sh -c 'echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf'
sh -c 'echo "net.ipv4.conf.all.proxy_arp = 1" >> /etc/sysctl.conf'
sysctl -p /etc/sysctl.conf


ip link add c1wg2 type wireguard
ip link set c1wg2 up
ip addr add 10.2.2.2/30 dev c1wg2
wg setconf c1wg2 c1wg2.conf


ip link add c1wg4 type wireguard
ip link set c1wg4 up
ip addr add 10.4.4.2/30 dev c1wg4
wg setconf c1wg4 c1wg4.conf