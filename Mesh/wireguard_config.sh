#!/bin/bash

set -e

# setting up keys

umask 077
wg genkey > server1_privatekey
wg genkey > server2_privatekey
wg genkey > client1_privatekey
wg genkey > client2_privatekey
wg pubkey < server1_privatekey > server1_publickey
wg pubkey < server2_privatekey > server2_publickey
wg pubkey < client1_privatekey > client1_publickey
wg pubkey < client2_privatekey > client2_publickey
s1_pvt=$( cat server1_privatekey )
s2_pvt=$( cat server2_privatekey )
c1_pvt=$( cat client1_privatekey )
c2_pvt=$( cat client2_privatekey )
s1_pub=$( cat server1_publickey )
s2_pub=$( cat server2_publickey )
c1_pub=$( cat client1_publickey )
c2_pub=$( cat client2_publickey )


# server-1 config
ip netns exec server-1 ip link add wg1 type wireguard
ip netns exec server-1 ip addr add 192.168.1.1/24 dev wg1
ip netns exec server-1 ip link set wg1 up

touch  wg1.conf
echo '[Interface]
ListenPort = 1
PrivateKey = '"$s1_pvt" '

[Peer]
Endpoint = 90.80.20.200:2
AllowedIPs = 192.168.1.2/32
PublicKey = ' "$s2_pub" '
PersistentKeepalive = 25

[Peer]
AllowedIPs = 20.0.0.0/24,192.168.1.100/32
PublicKey = ' "$c1_pub" '
PersistentKeepalive = 25

[Peer]
AllowedIPs = 30.0.0.0/24,192.168.1.200/32
PublicKey = ' "$c2_pub" '
PersistentKeepalive = 25
' > wg1.conf

ip netns exec server-1 wg setconf wg1 wg1.conf


# server-2 config
ip netns exec server-2 ip link add wg2 type wireguard
ip netns exec server-2 ip addr add 192.168.1.2/24 dev wg2
ip netns exec server-2 ip link set wg2 up

touch  wg2.conf
echo '[Interface]
ListenPort = 2
PrivateKey = '"$s2_pvt"'

[Peer]
Endpoint = 90.80.10.100:1
AllowedIPs = 192.168.1.1/32
PublicKey = '"$s1_pub"'
PersistentKeepalive = 25

[Peer]
AllowedIPs = 20.0.0.0/24,192.168.1.100/32
PublicKey = '"$c1_pub"'
PersistentKeepalive = 25

[Peer]
AllowedIPs = 30.0.0.0/24,192.168.1.200/32
PublicKey = '"$c2_pub"'
PersistentKeepalive = 25
' > wg2.conf

ip netns exec server-2 wg setconf wg2 wg2.conf


# client-1 config
ip netns exec client-1 ip link add wg100 type wireguard
ip netns exec client-1 ip addr add 192.168.1.100 dev wg100
ip netns exec client-1 ip link set wg100 up

touch wg100.conf
echo '[Interface]
ListenPort = 100
PrivateKey = '"$c1_pvt"' 

[Peer]
Endpoint = 90.80.10.100:1
AllowedIPs = 30.0.0.0/24,192.168.1.1/32,192.168.1.200/32
PublicKey = '"$s1_pub"'
PersistentKeepalive = 25

[Peer]
Endpoint = 90.80.20.200:2
AllowedIPs = 30.0.0.0/24,192.168.1.2/32,192.168.1.200/32
PublicKey = '"$s2_pub"'
PersistentKeepalive = 25
' > wg100.conf

ip netns exec client-1 wg setconf wg100 wg100.conf



# client-2 config
ip netns exec client-2 ip link add wg200 type wireguard
ip netns exec client-2 ip addr add 192.168.1.200 dev wg200
ip netns exec client-2 ip link set wg200 up

touch wg200.conf
echo '[Interface]
ListenPort = 200
PrivateKey = '"$c2_pvt"'

[Peer]
Endpoint = 90.80.10.100:1
AllowedIPs = 20.0.0.0/24,192.168.1.1/32,192.168.1.100/32
PublicKey = '"$s1_pub"'
PersistentKeepalive = 25

[Peer]
Endpoint = 90.80.20.200:2
AllowedIPs = 20.0.0.0/24,192.168.1.2/32,192.168.1.100/32
PublicKey = '"$s2_pub"'
PersistentKeepalive = 25
' > wg200.conf

ip netns exec client-2 wg setconf wg200 wg200.conf

# vpn routing
#ip -n client-1 route add 192.168.1.0/24 dev wg100
#ip -n client-2 route add 192.168.1.0/24 dev wg200

ip -n client-1 route add 192.168.1.1/32 dev wg100
ip -n client-1 route add 192.168.1.2/32 dev wg100

ip -n client-2 route add 192.168.1.1/32 dev wg200
ip -n client-2 route add 192.168.1.2/32 dev wg200

ip -n client-1 route add 192.168.1.200/32 nexthop via 192.168.1.1 weight 1 nexthop via 192.168.1.2 weight 1
ip -n client-2 route add 192.168.1.100/32 nexthop via 192.168.1.1 weight 1 nexthop via 192.168.1.2 weight 1
