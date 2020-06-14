#!/bin/bash

set -e

sh -c 'echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf'
sh -c 'echo "net.ipv4.conf.all.proxy_arp = 1" >> /etc/sysctl.conf'
sysctl -p /etc/sysctl.conf

ip link add s1wg1 type wireguard
ip link set s1wg1 up
ip addr add 10.1.1.1/30 dev s1wg1
wg setconf s1wg1 s1wg1.conf


ip link add s1wg2 type wireguard
ip link set s1wg2 up
ip addr add 10.2.2.1/30 dev s1wg2
wg setconf s1wg2 s1wg2.conf


ip link add s1wg3 type wireguard
ip link set s1wg3 up
ip addr add 10.3.3.1/30 dev s1wg3
wg setconf s1wg3 s1wg3.conf
