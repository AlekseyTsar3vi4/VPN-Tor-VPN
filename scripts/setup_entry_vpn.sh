#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo -e "\n=== VPS 1 :: VPN Entry Node Setup ===\n"

# System Updates
echo "[+] Updating system packages..."
apt update -qq && apt dist-upgrade -y -qq

# Install OpenVPN using Road Warrior script
echo "[+] Installing OpenVPN (Road Warrior script)..."
wget -q https://git.io/vpn -O openvpn-install.sh
chmod +x openvpn-install.sh
./openvpn-install.sh

echo "[✔] OpenVPN installed successfully."

# OpenVPN log sanitisation
CONF_PATH="/etc/openvpn/server.conf"
if [ -f "$CONF_PATH" ]; then
  echo "[+] Applying OpenVPN log sanitisation..."
  sed -i '/^log\|^status\|^log-append\|^verb/d' "$CONF_PATH"
  cat <<EOF >> "$CONF_PATH"

# Log sanitisation
log /dev/null
status /dev/null
log-append /dev/null
verb 0
EOF
else
  echo "[!] Warning: OpenVPN config not found at $CONF_PATH"
fi

# RAM-only logging for journald
echo "[+] Enforcing journald RAM-only logging..."
mkdir -p /etc/systemd/journald.conf.d
cat <<EOF > /etc/systemd/journald.conf.d/privacy.conf
[Journal]
Storage=volatile
Compress=no
EOF
systemctl restart systemd-journald

# Install Tor + iptables-persistent
echo "[+] Installing Tor and iptables-persistent..."
apt install -y -qq tor iptables-persistent

# Reset torrc
echo "[+] Resetting torrc..."
rm -f /etc/tor/torrc

# Input Tor exit info
read -rp "[?] Enter Nickname or IP of your Tor Exit Node (e.g. SecretExitNode or 123.45.67.89): " TOR_EXIT

# Write torrc configuration
echo "[+] Writing Tor configuration..."
cat <<EOF > /etc/tor/torrc
VirtualAddrNetwork 10.192.0.0/10
AutomapHostsOnResolve 1
DNSPort 10.8.0.1:53530
TransPort 10.8.0.1:9040
ExitNodes $TOR_EXIT
StrictNodes 1
EOF

# IPTables rules
echo "[+] Configuring iptables to redirect VPN traffic through Tor..."
IPT=/sbin/iptables
OVPN_IF="tun0"

$IPT -A INPUT -i $OVPN_IF -s 10.8.0.0/24 -m state --state NEW -j ACCEPT
$IPT -t nat -A PREROUTING -i $OVPN_IF -p udp --dport 53 -s 10.8.0.0/24 -j DNAT --to 10.8.0.1:53530
$IPT -t nat -A PREROUTING -i $OVPN_IF -p tcp -s 10.8.0.0/24 -j DNAT --to 10.8.0.1:9040
$IPT -t nat -A PREROUTING -i $OVPN_IF -p udp -s 10.8.0.0/24 -j DNAT --to 10.8.0.1:9040

echo "[+] Saving iptables rules..."
iptables-save > /etc/iptables/rules.v4

# Start Tor service and verify
echo "[+] Starting Tor service..."
systemctl enable tor --now

echo "[✔] Tor service status:"
systemctl --no-pager status tor | grep -E 'Active:|Main PID:|CPU:|Loaded:'

# Final note
echo -e "\n[i] Setup complete! Your .ovpn config file is usually at /root/<your-client-name>.ovpn"
echo "[i] Connect from your PC using that file: [PC] → VPN (VPS1) → Tor Exit (VPS2)"
