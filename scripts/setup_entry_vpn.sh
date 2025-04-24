#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo -e "\n=== VPS 1 :: VPN Entry Node Setup ==="

echo "[+] Updating system packages..."
apt update -qq
apt dist-upgrade -y -qq

echo "[+] Installing OpenVPN via Road Warrior script (manual interaction required)..."
wget -q https://git.io/vpn -O openvpn-install.sh
chmod +x openvpn-install.sh
./openvpn-install.sh

echo ""
echo "[✔] OpenVPN installed."

echo ""
echo "[+] Installing Tor and iptables-persistent for redirection..."
apt install -y -qq tor iptables-persistent

echo "[+] Cleaning up default torrc..."
rm -f /etc/tor/torrc

read -rp "[?] Enter the Nickname or IP of your Tor Exit Node (e.g. SecretExitNode or 123.45.67.89): " TOR_EXIT

echo "[+] Writing torrc configuration..."
cat <<EOF > /etc/tor/torrc

VirtualAddrNetwork 10.192.0.0/10
AutomapHostsOnResolve 1
DNSPort 10.8.0.1:53530
TransPort 10.8.0.1:9040
ExitNodes $TOR_EXIT
StrictNodes 1
EOF

echo "[+] Setting up iptables to redirect VPN traffic through Tor..."
IPT=/sbin/iptables
OVPN=tun0

$IPT -A INPUT -i $OVPN -s 10.8.0.0/24 -m state --state NEW -j ACCEPT
$IPT -t nat -A PREROUTING -i $OVPN -p udp --dport 53 -s 10.8.0.0/24 -j DNAT --to 10.8.0.1:53530
$IPT -t nat -A PREROUTING -i $OVPN -p tcp -s 10.8.0.0/24 -j DNAT --to 10.8.0.1:9040
$IPT -t nat -A PREROUTING -i $OVPN -p udp -s 10.8.0.0/24 -j DNAT --to 10.8.0.1:9040

echo "[+] Saving iptables rules..."
iptables-save > /etc/iptables/rules.v4

echo "[+] Almost done... Enabling and starting Tor..."
systemctl restart tor@default

echo ""
echo "[i] Done!!! Your .ovpn file is usually saved at: /root/<your-client-name>.ovpn. Please download that file to your local machine"
echo "[i] Connect from your PC using that OpenVPN config file"
echo "[✔] VPS1 Setup Complete. After connecting, Your traffic should now route: [PC] → VPN (VPS1) → Tor Exit (VPS2)"
