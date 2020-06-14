#!/bin/bash

set -e

sh -c 'echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf'
sh -c 'echo "net.ipv4.conf.all.proxy_arp = 1" >> /etc/sysctl.conf'
sysctl -p /etc/sysctl.conf

ip link add s2wg1 type wireguard
ip link set s2wg1 up
ip addr add 10.1.1.2/30 dev s2wg1
wg setconf s2wg1 s2wg1.conf


ip link add s2wg4 type wireguard
ip link set s2wg4 up
ip addr add 10.4.4.1/30 dev s2wg4
wg setconf s2wg4 s2wg4.conf


ip link add s2wg5 type wireguard
ip link set s2wg5 up
ip addr add 10.5.5.1/30 dev s2wg5
wg setconf s2wg5 s2wg5.conf
