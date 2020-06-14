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


# server-1 to server-2
touch s1wg1.conf
touch s2wg1.conf

echo '[Interface]
# Address = 10.1.1.1/30
ListenPort = 1
PrivateKey = '"$s1_pvt" '

[Peer]
Endpoint = 192.168.122.20:10
AllowedIPs = 0.0.0.0/0
PublicKey = ' "$s2_pub" '
PersistentKeepalive = 25
' > s1wg1.conf


echo '[Interface]
# Address = 10.1.1.2/30
ListenPort = 10
PrivateKey = '"$s2_pvt" '

[Peer]
Endpoint = 192.168.122.10:1
AllowedIPs = 0.0.0.0/0
PublicKey = ' "$s1_pub" '
PersistentKeepalive = 25
' > s2wg1.conf



# client-1 to server-1
touch s1wg2.conf
touch c1wg2.conf

echo '[Interface]
# Address = 10.2.2.1/30
ListenPort = 2
PrivateKey = '"$s1_pvt" '

[Peer]
AllowedIPs = 0.0.0.0/0
PublicKey = ' "$c1_pub" '
PersistentKeepalive = 25
' > s1wg2.conf


echo '[Interface]
# Address = 10.2.2.2/30
ListenPort = 20
PrivateKey = '"$c1_pvt" '

[Peer]
Endpoint = 192.168.122.10:2
AllowedIPs = 0.0.0.0/0
PublicKey = ' "$s1_pub" '
PersistentKeepalive = 25
' > c1wg2.conf


# client-1 to server-2
touch s2wg4.conf
touch c1wg4.conf

echo '[Interface]
# Address = 10.4.4.1/30
ListenPort = 4
PrivateKey = '"$s2_pvt" '

[Peer]
AllowedIPs = 0.0.0.0/0
PublicKey = ' "$c1_pub" '
PersistentKeepalive = 25
' > s2wg4.conf


echo '[Interface]
# Address = 10.4.4.2/30
ListenPort = 40
PrivateKey = '"$c1_pvt" '

[Peer]
Endpoint = 192.168.122.20:4
AllowedIPs = 0.0.0.0/0
PublicKey = ' "$s2_pub" '
PersistentKeepalive = 25
' > c1wg4.conf



# client-2 to server-1
touch s1wg3.conf
touch c2wg3.conf

echo '[Interface]
# Address = 10.3.3.1/30
ListenPort = 3
PrivateKey = '"$s1_pvt" '

[Peer]
AllowedIPs = 0.0.0.0/0
PublicKey = ' "$c2_pub" '
PersistentKeepalive = 25
' > s1wg3.conf


echo '[Interface]
# Address = 10.3.3.2/30
ListenPort = 30
PrivateKey = '"$c2_pvt" '

[Peer]
Endpoint = 192.168.122.10:3
AllowedIPs = 0.0.0.0/0
PublicKey = ' "$s1_pub" '
PersistentKeepalive = 25
' > c2wg3.conf



# client-2 to server-2
touch s2wg5.conf
touch c2wg5.conf

echo '[Interface]
# Address = 10.5.5.1/30
ListenPort = 5
PrivateKey = '"$s2_pvt" '

[Peer]
AllowedIPs = 0.0.0.0/0
PublicKey = ' "$c2_pub" '
PersistentKeepalive = 25
' > s2wg5.conf


echo '[Interface]
# Address = 10.5.5.2/30
ListenPort = 50
PrivateKey = '"$c2_pvt" '

[Peer]
Endpoint = 192.168.122.20:5
AllowedIPs = 0.0.0.0/0
PublicKey = ' "$s2_pub" '
PersistentKeepalive = 25
' > c2wg5.conf

scp s1* maged@192.168.122.10:
scp s2* maged@192.168.122.20:
scp c1* maged@192.168.150.100:
scp c2* maged@192.168.250.200:
