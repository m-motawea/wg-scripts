#!/bin/bash
# ┌────────────────────────────────────────┐    ┌────────────────────────────────────────────────┐     ┌────────────────────────────────────────┐
# │            client namespaces           │    │                 router namespace               │     │             server namespace           │
# │                                        │    │                                                │     │                                        │
# │  ┌─────┐             ┌─────┐           │    │    ┌──────┐              ┌──────┐              │     │  ┌─────┐            ┌─────┐            │
# │  │wg2/3│─────────────│cl1/2│───────────┼────┼────│cr1/2 │              │  sr  │──────────────┼─────┼──│  s  │────────────│ wg1 │            │
# │  ├─────┴──────────┐  ├─────┴──────────┐│    │    ├──────┴─────────┐    ├──────┴────────────┐ │     │  ├─────┴──────────┐ ├─────┴──────────┐ │
# │  │192.168.241.2/24│  │1- 20.20.20.2/24││    │    │1- 20.20.20.1/24│    │10.10.10.1/24      │ │     │  │10.10.10.2/24   │ │192.168.241.1/24│ │
# │  │192.168.241.3/24│  │2- 30.30.30.2/24││    │    │2- 30.30.30.1/24│    │SNAT:20.20.20.0/24 │ │     │  │                │ │                │ │
# │  └────────────────┘  └────────────────┘│    │    └────────────────┘    └───────────────────┘ │     │  └────────────────┘ └────────────────┘ │
# └────────────────────────────────────────┘    └────────────────────────────────────────────────┘     └────────────────────────────────────────┘

set -e

sudo sh -c 'echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf'
sudo sh -c 'echo "net.ipv4.conf.all.proxy_arp = 1" >> /etc/sysctl.conf'
sudo sysctl -p /etc/sysctl.conf

sudo ip netns add router
sudo ip netns add client-1
sudo ip netns add client-2
sudo ip netns add server


# router setup
sudo ip -n router link add dev sr type veth peer name s
sudo ip netns exec router ip link add dev cr1 type veth peer name cl1
sudo ip netns exec router ip link add dev cr2 type veth peer name cl2
sudo ip netns exec router ip link set netns server s
sudo ip netns exec router ip link set netns client-1 cl1
sudo ip netns exec router ip link set netns client-2 cl2

sudo ip netns exec router ip addr add 10.10.10.1/24 dev sr
sudo ip netns exec router ip addr add 20.20.20.1/24 dev cr1
sudo ip netns exec router ip addr add 30.30.30.1/24 dev cr2
sudo ip netns exec router ip link set sr up
sudo ip netns exec router ip link set cr1 up
sudo ip netns exec router ip link set cr2 up

# NAT setup
sudo ip netns exec router bash -c 'printf 1 > /proc/sys/net/ipv4/ip_forward'
sudo ip netns exec router bash -c 'printf 2 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout'
sudo ip netns exec router bash -c 'printf 2 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout_stream'
sudo ip netns exec router iptables -t nat -A POSTROUTING -s 20.20.20.0/24 -d 10.10.10.0/24 -j SNAT --to 10.10.10.1
sudo ip netns exec router iptables -t nat -A POSTROUTING -s 30.30.30.0/24 -d 10.10.10.0/24 -j SNAT --to 10.10.10.1


# server setup
sudo ip netns exec server ip addr add 10.10.10.2/24 dev s
sudo ip netns exec server ip link set s up
# sudo ip netns exec server route add default gw 10.10.10.1 s

# client-1 setup
sudo ip netns exec client-1 ip addr add 20.20.20.2/24 dev cl1
sudo ip netns exec client-1 ip link set cl1 up
sudo ip netns exec client-1 route add default gw 20.20.20.1 cl1

# client-2 setup
sudo ip netns exec client-2 ip addr add 30.30.30.2/24 dev cl2
sudo ip netns exec client-2 ip link set cl2 up
sudo ip netns exec client-2 route add default gw 30.30.30.1 cl2

# keys setup
umask 077
wg genkey > server_private_key
wg genkey > client1_private_key
wg genkey > client2_private_key
wg pubkey < server_private_key > server_publickey
wg pubkey < client1_private_key > client1_publickey
wg pubkey < client2_private_key > client2_publickey
s_pvt=$( cat server_private_key )
c1_pvt=$( cat client1_private_key )
c2_pvt=$( cat client2_private_key )
s_pub=$( cat server_publickey )
c1_pub=$( cat client1_publickey )
c2_pub=$( cat client2_publickey )


# wireguard server config
sudo ip netns exec server ip link add wg1 type wireguard
sudo ip netns exec server ip addr add 192.168.241.1/24 dev wg1
sudo ip netns exec server ip link set wg1 up
touch  wg1.conf
echo '[Interface]
ListenPort = 1
PrivateKey = '"$s_pvt" '

[Peer]
AllowedIPs = 192.168.241.2/32,100.16.0.0/16
PublicKey = ' "$c1_pub" '
PersistentKeepalive = 25

[Peer]
AllowedIPs = 192.168.241.3/32,100.32.0.0/16
PublicKey = ' "$c2_pub" '
PersistentKeepalive = 25
' > wg1.conf

sudo ip netns exec server wg setconf wg1 wg1.conf

# client-1 wireguard config
sudo ip netns exec client-1 ip link add wg2 type wireguard
sudo ip netns exec client-1 ip addr add 192.168.241.2/24 dev wg2
sudo ip netns exec client-1 ip link set wg2 up
sed -i "/PrivateKey = */c\PrivateKey = $c1_pvt" wg2.conf
sed -i "/PublicKey = */c\PublicKey = $s_pub" wg2.conf
sudo ip netns exec client-1 wg setconf wg2 wg2.conf

sudo ip netns exec client-1 ip route add 192.168.241.3/32 dev wg2

# client-2 wireguard config
sudo ip netns exec client-2 ip link add wg3 type wireguard
sudo ip netns exec client-2 ip addr add 192.168.241.3/24 dev wg3
sudo ip netns exec client-2 ip link set wg3 up
sed -i "/PrivateKey = */c\PrivateKey = $c2_pvt" wg3.conf
sed -i "/PublicKey = */c\PublicKey = $s_pub" wg3.conf
sudo ip netns exec client-2 wg setconf wg3 wg3.conf

sudo ip netns exec client-2 ip route add 192.168.241.2/32 dev wg3


# clients dummy network config
sudo ip netns exec client-1 ip link add net1 type dummy
sudo ip netns exec client-1 ip addr add 100.16.0.1/16 dev net1
sudo ip netns exec client-1 ip link set net1 up

sudo ip netns exec client-2 ip link add net2 type dummy
sudo ip netns exec client-2 ip addr add 100.32.0.1/16 dev net2
sudo ip netns exec client-2 ip link set net2 up

# configure routing
sudo ip netns exec server sh -c 'echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf'
sudo ip netns exec server sh -c 'echo "net.ipv4.conf.all.proxy_arp = 1" >> /etc/sysctl.conf'
sudo ip netns exec server sysctl -p /etc/sysctl.conf

sudo ip netns exec server ip route add 100.32.0.0/16 via 192.168.241.3
sudo ip netns exec server ip route add 100.16.0.0/16 via 192.168.241.2
sudo ip netns exec client-2 ip route add 100.16.0.0/16 via 192.168.241.1
sudo ip netns exec client-1 ip route add 100.32.0.0/16 via 192.168.241.1
