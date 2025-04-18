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

echo -e "\n=== 🧭 CURRENT NETWORK INFO ==="
ip -4 addr show eth0
ip route

# Detect proper public IP and CIDR
VPS2_IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -Ev '^(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)' | head -n 1)
GATEWAY=$(ip route | awk '/^default/ && $5=="eth0" {print $3}')
NETWORK_CIDR=$(ip route show dev eth0 | awk '{print $1}' | grep '/' | grep -v '^10\.' | head -n 1)

echo -e "\n=== 📝 ROUTING PREVIEW (table 128) ==="
echo "ip rule add from $VPS2_IP table 128"
echo "ip route add table 128 $NETWORK_CIDR dev eth0"
echo "ip route add table 128 default via $GATEWAY"

echo ""
read -rp "[?] Does this match your address schema based on the routing table above? [y/N]: " CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "[✔] Applying routing rules now..."
    ip rule add from "$VPS2_IP" table 128 || echo "[i] Rule already exists."
    ip route add table 128 "$NETWORK_CIDR" dev eth0 || echo "[i] Route already exists."
    ip route add table 128 default via "$GATEWAY" dev eth0 || echo "[i] Default route already exists."
    iptables-save > /etc/iptables/rules.v4
    echo "[✔] Routing table updated."
else
    echo "[!] Aborted. Please update routes manually if detection didn’t match."
    exit 1
fi

echo -e "\n[i] Launching OpenVPN client (connecting to VPS3)..."
sleep 2
exec openvpn --config "$OVPN_PATH"
