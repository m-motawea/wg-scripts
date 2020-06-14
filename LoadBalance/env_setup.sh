#!/bin/bash

set -e

sh -c 'echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf'
sh -c 'echo "net.ipv4.conf.all.proxy_arp = 1" >> /etc/sysctl.conf'
sysctl -p /etc/sysctl.conf

ip netns add h1
ip netns add h2

ip link add l1-h1 type veth peer name l1-h2
ip link add l2-h1 type veth peer name l2-h2


ip link set netns h1 l1-h1
ip link set netns h1 l2-h1
ip link set netns h2 l1-h2
ip link set netns h2 l2-h2


ip -n h1 addr add 10.10.10.1/24 dev l1-h1
ip -n h1 link set l1-h1 up

ip -n h1 addr add 20.20.20.1/24 dev l2-h1
ip -n h1 link set l2-h1 up


ip -n h2 addr add 10.10.10.2/24 dev l1-h2
ip -n h2 link set l1-h2 up

ip -n h2 addr add 20.20.20.2/24 dev l2-h2
ip -n h2 link set l2-h2 up



# wireguard config
ip -n h1 link add wg1 type wireguard
ip -n h1 addr add 192.168.1.1/24 dev wg1
ip -n h1 link set wg1 up

ip -n h1 link add wg10 type wireguard
ip -n h1 addr add 192.168.10.1/24 dev wg10
ip -n h1 link set wg10 up

ip -n h2 link add wg1 type wireguard
ip -n h2 addr add 192.168.1.2/24 dev wg1
ip -n h2 link set wg1 up

ip -n h2 link add wg10 type wireguard
ip -n h2 addr add 192.168.10.2/24 dev wg10
ip -n h2 link set wg10 up


umask 077
wg genkey > host1_privatekey
wg genkey > host2_privatekey
wg pubkey < host1_privatekey > host1_publickey
wg pubkey < host2_privatekey > host2_publickey
h1_pvt=$( cat host1_privatekey )
h2_pvt=$( cat host2_privatekey )
h1_pub=$( cat host1_publickey )
h2_pub=$( cat host2_publickey )

touch  h1-wg1.conf
echo '[Interface]
ListenPort = 1
PrivateKey = '"$h1_pvt" '

[Peer]
Endpoint = 10.10.10.2:2
AllowedIPs = 192.168.1.0/24,192.168.10.0/24
PublicKey = ' "$h2_pub" '
PersistentKeepalive = 25
' > h1-wg1.conf



touch  h1-wg10.conf
echo '[Interface]
ListenPort = 10
PrivateKey = '"$h1_pvt" '

[Peer]
Endpoint = 20.20.20.2:20
AllowedIPs = 192.168.1.0/24,192.168.10.0/24
PublicKey = ' "$h2_pub" '
PersistentKeepalive = 25
' > h1-wg10.conf



touch  h2-wg1.conf
echo '[Interface]
ListenPort = 2
PrivateKey = '"$h2_pvt" '

[Peer]
Endpoint = 10.10.10.1:1
AllowedIPs = 192.168.1.0/24,192.168.10.0/24
PublicKey = ' "$h1_pub" '
PersistentKeepalive = 25
' > h2-wg1.conf



touch  h2-wg10.conf
echo '[Interface]
ListenPort = 20
PrivateKey = '"$h2_pvt" '

[Peer]
Endpoint = 20.20.20.1:10
AllowedIPs = 192.168.1.0/24,192.168.10.0/24
PublicKey = ' "$h1_pub" '
PersistentKeepalive = 25
' > h2-wg10.conf


ip netns exec h1 wg setconf wg1 h1-wg1.conf
ip netns exec h1 wg setconf wg10 h1-wg10.conf

ip netns exec h2 wg setconf wg1 h2-wg1.conf
ip netns exec h2 wg setconf wg10 h2-wg10.conf


ip -n h1 route del 192.168.1.0/24 dev wg1
ip -n h1 route del 192.168.10.0/24 dev wg10
ip -n h2 route del 192.168.1.0/24 dev wg1
ip -n h2 route del 192.168.10.0/24 dev wg10
ip -n h1 route add 192.168.1.2/32 dev wg1
ip -n h1 route add 192.168.10.2/32 dev wg10
ip -n h2 route add 192.168.1.1/32 dev wg1
ip -n h2 route add 192.168.10.1/32 dev wg10

ip -n h1 route add 192.168.1.0/24 nexthop via 192.168.1.2 weight 1 nexthop via 192.168.10.2 weight 1
ip -n h2 route add 192.168.1.0/24 nexthop via 192.168.1.1 weight 1 nexthop via 192.168.10.1 weight 1 


# host1 dummy ips
ip -n h1 link add net1 type dummy
ip -n h1 link add net10 type dummy
ip -n h1 addr add 192.168.1.5/24 dev net1
ip -n h1 addr add 192.168.1.10/24 dev net10
ip -n h1 link set net1 up
ip -n h1 link set net10 up
