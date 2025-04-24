#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo -e "\n=== VPS2 :: Final VPN Layer – Post-Tor Routing Setup ==="

read -rp "[?] Enter path to your VPS3 client config (e.g. /root/vps3client.ovpn): " OVPN_PATH

echo "[+] Installing OpenVPN client and DNS protection tools..."
apt install -y -qq openvpn openvpn-systemd-resolved iptables-persistent net-tools psmisc

echo "[+] Inserting DNS leak protection hooks (before 'verb 3')..."
sed -i '/verb 3/i \
script-security 2\n\
up /etc/openvpn/update-systemd-resolved\n\
down /etc/openvpn/update-systemd-resolved\n\
down-pre\n\
dhcp-option DOMAIN-ROUTE\n' "$OVPN_PATH"

# Network discovery
echo -e "\n=== NETWORK CONFIGURATION ==="
VPS2_IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -Ev '^(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)' | head -n 1)
GATEWAY=$(ip route | awk '/^default/ && $5=="eth0" {print $3}')
NETWORK_CIDR=$(ip route show dev eth0 | awk '{print $1}' | grep '/' | grep -v '^10\.' | head -n 1)

echo "[✔] VPS2 IP: $VPS2_IP"
echo "[✔] Gateway: $GATEWAY"
echo "[✔] Network CIDR: $NETWORK_CIDR"

# Apply routing rules silently
echo "[+] Applying routing rules via table 128..."
ip rule add from "$VPS2_IP" table 128 2>/dev/null || echo "[i] Rule already exists."
ip route add table 128 "$NETWORK_CIDR" dev eth0 2>/dev/null || echo "[i] Network route already exists."
ip route add table 128 default via "$GATEWAY" dev eth0 2>/dev/null || echo "[i] Default route already exists."

# Launch OpenVPN
echo -e "\n[i] Connecting to final VPN server (VPS3)..."
sleep 2
exec openvpn --config "$OVPN_PATH"
