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
