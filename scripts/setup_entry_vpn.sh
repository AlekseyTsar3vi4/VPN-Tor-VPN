#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo -e "\n=== VPS 1 :: VPN Entry Node Setup ==="

echo "[+] Updating system..."
apt update -qq
apt dist-upgrade -y -qq

echo "[+] Downloading OpenVPN install script..."
wget -q https://git.io/vpn -O openvpn-install.sh
chmod +x openvpn-install.sh

echo "[+] Predefining OpenVPN install options..."
cat <<EOF > .openvpn-install.conf
AUTO_INSTALL=y
PROTOCOL=tcp
PORT=1194
DNS=1
CLIENT=vpn1client
EOF

echo "[+] Installing OpenVPN using predefined config (TCP/1194, system DNS)..."
./openvpn-install.sh

echo "[+] OpenVPN installed successfully."
echo "[i] Client config generated at: /root/vpn1client.ovpn"
echo "[i] Please download this file to your local machine and test the VPN connection."

echo "[+] Installing Tor and iptables-persistent..."
apt install -y -qq tor iptables-persistent

echo "[+] Cleaning up default torrc..."
rm -f /etc/tor/torrc

read -rp "[?] Enter Nickname or IP of your Tor Exit Node (VPS2): " TOR_EXIT

echo "[+] Writing new torrc config to route VPN traffic through VPS2 exit..."
cat <<EOF > /etc/tor/torrc
VirtualAddrNetwork 10.192.0.0/10
AutomapHostsOnResolve 1
DNSPort 10.8.0.1:53530
TransPort 10.8.0.1:9040
ExitNodes $TOR_EXIT
StrictNodes 1
EOF

echo "[+] Configuring iptables to redirect VPN traffic to Tor..."
IPT=/sbin/iptables
OVPN=tun0

$IPT -A INPUT -i $OVPN -s 10.8.0.0/24 -m state --state NEW -j ACCEPT
$IPT -t nat -A PREROUTING -i $OVPN -p udp --dport 53 -s 10.8.0.0/24 -j DNAT --to 10.8.0.1:53530
$IPT -t nat -A PREROUTING -i $OVPN -p tcp -s 10.8.0.0/24 -j DNAT --to 10.8.0.1:9040
$IPT -t nat -A PREROUTING -i $OVPN -p udp -s 10.8.0.0/24 -j DNAT --to 10.8.0.1:9040

echo "[+] Saving firewall rules..."
iptables-save > /etc/iptables/rules.v4

echo ""
echo "[✔] VPS1 Setup Complete."
echo "[i] Start Tor manually with: tor"
echo "[i] Connect from your PC using: /root/vpn1client.ovpn file"
echo "[i] Your traffic should route: [PC] → VPN (VPS1) → TOR Exit (VPS2)"
