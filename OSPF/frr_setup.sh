curl -s https://deb.frrouting.org/frr/keys.asc | sudo apt-key add -
FRRVER="frr-stable"
echo deb https://deb.frrouting.org/frr $(lsb_release -s -c) $FRRVER | tee -a /etc/apt/sources.list.d/frr.list
apt update && sudo apt install frr frr-pythontools -y 


sed -i '/zebra_options=*/c\zebra_options="-n  -A 127.0.0.1 -s 90000000"' /etc/frr/daemons
sed -i '/ospfd=no/c\ospfd=yes' /etc/frr/daemons
systemctl restart frr

