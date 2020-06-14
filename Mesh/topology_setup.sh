#!/bin/bash

set -e

sh -c 'echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf'
sh -c 'echo "net.ipv4.conf.all.proxy_arp = 1" >> /etc/sysctl.conf'
sysctl -p /etc/sysctl.conf


# creating namespaces
ip netns add router
ip netns add nat-1
ip netns add nat-2
ip netns add server-1
ip netns add server-2
ip netns add client-1
ip netns add client-2


# creating router links
ip link add rn1 type veth peer name n1
ip link add rn2 type veth peer name n2
ip link add rs1 type veth peer name s1
ip link add rs2 type veth peer name s2

ip link set netns router rn1
ip link set netns router rn2
ip link set netns router rs1
ip link set netns router rs2
ip link set netns server-1 s1
ip link set netns server-2 s2
ip link set netns nat-1 n1
ip link set netns nat-2 n2


# creating nat-1 links
ip link add nc1 type veth peer name c1
ip link set netns nat-1 nc1
ip link set netns client-1 c1

# creating nat-2 links
ip link add nc2 type veth peer name c2
ip link set netns nat-2 nc2
ip link set netns client-2 c2

# configuring ip addresses
# client-1 ip config
ip -n client-1 addr add 10.10.10.2/24 dev c1
ip -n client-1 link set c1 up

# nat-1 ip config
ip -n nat-1 addr add 10.10.10.1/24 dev nc1
ip -n nat-1 addr add 20.0.0.100/24 dev n1
ip -n nat-1 link set nc1 up
ip -n nat-1 link set n1 up

# client-2 ip config
ip -n client-2 addr add 10.10.10.2/24 dev c2
ip -n client-2 link set c2 up

# nat-2 ip config
ip -n nat-2 addr add 10.10.10.1/24 dev nc2
ip -n nat-2 addr add 30.0.0.200/24 dev n2
ip -n nat-2 link set nc2 up
ip -n nat-2 link set n2 up

# router ip config
ip -n router addr add 20.0.0.1/24 dev rn1
ip -n router addr add 30.0.0.1/24 dev rn2
ip -n router addr add 90.80.10.1/24 dev rs1
ip -n router addr add 90.80.20.1/24 dev rs2
ip -n router link set rn1 up
ip -n router link set rn2 up
ip -n router link set rs1 up
ip -n router link set rs2 up

# server-1 ip config
ip -n server-1 addr add 90.80.10.100/24 dev s1
ip -n server-1 link set s1 up

# server-2 ip config
ip -n server-2 addr add 90.80.20.200/24 dev s2
ip -n server-2 link set s2 up


# nat-1 setup
sudo ip netns exec nat-1 bash -c 'printf 1 > /proc/sys/net/ipv4/ip_forward'
sudo ip netns exec nat-1 bash -c 'printf 2 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout'
sudo ip netns exec nat-1 bash -c 'printf 2 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout_stream'
sudo ip netns exec nat-1 iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -d 0.0.0.0/0 -j SNAT --to 20.0.0.100

# nat-1 setup
sudo ip netns exec nat-2 bash -c 'printf 1 > /proc/sys/net/ipv4/ip_forward'
sudo ip netns exec nat-2 bash -c 'printf 2 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout'
sudo ip netns exec nat-2 bash -c 'printf 2 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout_stream'
sudo ip netns exec nat-2 iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -d 0.0.0.0/0 -j SNAT --to 30.0.0.200


# routing config
# server-1 routing config
ip -n server-1 route add default via 90.80.10.1

# server-2 routing config
ip -n server-2 route add default via 90.80.20.1

# nat-1 routing config
ip -n nat-1 route add default via 20.0.0.1

# nat-2 routing config
ip -n nat-2 route add default via 30.0.0.1

# client-1 routing config
ip -n client-1 route add default via 10.10.10.1

# client-2 routing config
ip -n client-2 route add default via 10.10.10.1

