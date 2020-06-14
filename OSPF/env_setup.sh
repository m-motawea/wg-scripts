#!/bin/bash

set -e

sh -c 'echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf'
sh -c 'echo "net.ipv4.conf.all.proxy_arp = 1" >> /etc/sysctl.conf'
sysctl -p /etc/sysctl.conf


# create nat-1 namespace
ip netns add nat-1
ip link add nb1 type veth peer name n1br-n1
ip link set netns nat-1 nb1
brctl addif virbr1 n1br-n1
ip link set n1br-n1 up
ip -n nat-1 link set nb1 up
ip -n nat-1 addr add 192.168.150.10/24 dev nb1


# connect nat-1 to default network
ip link add nn1 type veth peer name dbr-n1
ip link set netns nat-1 nn1
ip -n nat-1 link set nn1 up
ip -n nat-1 addr add 192.168.122.100/24 dev nn1
brctl addif virbr0 dbr-n1
ip link set dbr-n1 up


# create nat-2 namespace
ip netns add nat-2
ip link add nb2 type veth peer name n2br-n2
ip link set netns nat-2 nb2
brctl addif virbr2 n2br-n2
ip link set n2br-n2 up
ip -n nat-2 link set nb2 up
ip -n nat-2 addr add 192.168.250.10/24 dev nb2


# connect nat-2 to default network
ip link add nn2 type veth peer name dbr-n2
ip link set netns nat-2 nn2
ip -n nat-2 link set nn2 up
ip -n nat-2 addr add 192.168.122.200/24 dev nn2
brctl addif virbr0 dbr-n1
ip link set dbr-n1 up


# configuring nat-1
ip -n nat-1 route add default via 192.168.122.1 dev nn1
ip netns exec nat-1 bash -c 'printf 1 > /proc/sys/net/ipv4/ip_forward'
ip netns exec nat-1 bash -c 'printf 2 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout'
ip netns exec nat-1 bash -c 'printf 2 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout_stream'
ip netns exec nat-1 iptables -t nat -A POSTROUTING -s 192.168.150.0/24 -d 0.0.0.0/0 -j SNAT --to 192.168.122.100


# configuring nat-2
ip -n nat-2 route add default via 192.168.122.1 dev nn2
ip netns exec nat-2 bash -c 'printf 1 > /proc/sys/net/ipv4/ip_forward'
ip netns exec nat-2 bash -c 'printf 2 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout'
ip netns exec nat-2 bash -c 'printf 2 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout_stream'
ip netns exec nat-2 iptables -t nat -A POSTROUTING -s 192.168.250.0/24 -d 0.0.0.0/0 -j SNAT --to 192.168.122.200
