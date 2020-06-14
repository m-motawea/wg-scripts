set -e

sudo sh -c 'echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf'
sudo sh -c 'echo "net.ipv4.conf.all.proxy_arp = 1" >> /etc/sysctl.conf'
sudo sysctl -p /etc/sysctl.conf

sudo ip netns add peer1
sudo ip netns add peer2

sudo ip link add dev p1 type veth peer name p2
sudo ip link set netns peer1 p1
sudo ip link set netns peer2 p2

sudo ip netns exec peer1 ip addr add 10.10.10.1/24 dev p1
sudo ip netns exec peer1 ip link set p1 up

sudo ip netns exec peer2 ip addr add 10.10.10.2/24 dev p2
sudo ip netns exec peer2 ip link set p2 up

sudo ip netns exec peer1 ip link add dev wg1 type wireguard
sudo ip netns exec peer1 ip addr add 20.20.20.100/24 dev wg1
sudo ip netns exec peer1 ip link set wg1 up

sudo ip netns exec peer2 ip link add dev wg2 type wireguard
sudo ip netns exec peer2 ip addr add 20.20.20.200/24 dev wg2
sudo ip netns exec peer2 ip link set wg2 up

umask 077
wg genkey > peer1_private_key
wg genkey > peer2_private_key
wg pubkey < peer1_private_key > peer1_publickey
wg pubkey < peer2_private_key > peer2_publickey

peer1_pvt=$( cat peer1_private_key )
peer2_pvt=$( cat peer2_private_key )
peer1_pub=$( cat peer1_publickey )
peer2_pub=$( cat peer2_publickey )

sed -i "/PrivateKey = */c\PrivateKey = $peer1_pvt" wg1.conf
sed -i "/PrivateKey = */c\PrivateKey = $peer2_pvt" wg2.conf
sed -i "/PublicKey = */c\PublicKey = $peer2_pub" wg1.conf
sed -i "/PublicKey = */c\PublicKey = $peer1_pub" wg2.conf


sudo ip netns exec peer1 wg setconf wg1 wg1.conf
sudo ip netns exec peer2 wg setconf wg2 wg2.conf

sudo ip netns exec peer1 ip link add dev net1 type dummy
sudo ip netns exec peer1 ip addr add 30.30.30.1/24 dev net1
sudo ip netns exec peer1 ip link set net1 up

sudo ip netns exec peer2 ip link add dev net2 type dummy
sudo ip netns exec peer2 ip addr add 40.40.40.1/24 dev net2
sudo ip netns exec peer2 ip link set net2 up

sudo ip netns exec peer1 ip route add 40.40.40.0/24 via 20.20.20.200 dev wg1
sudo ip netns exec peer2 ip route add 30.30.30.0/24 via 20.20.20.100 dev wg2