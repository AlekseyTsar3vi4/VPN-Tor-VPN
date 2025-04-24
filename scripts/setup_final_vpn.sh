#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo -e "\n=== VPS 3 :: Final VPN Server Setup ==="

echo "[+] Updating system packages..."
apt update -qq
apt dist-upgrade -y -qq

echo "[+] Downloading OpenVPN Road Warrior script (manual interaction required)..."
wget -q https://git.io/vpn -O openvpn-install.sh
chmod +x openvpn-install.sh
./openvpn-install.sh

echo ""
echo "[✔] OpenVPN server setup complete."
echo "[i] After finishing the script, your VPN client config is saved at: /root/<client-name>.ovpn"
echo "[i] Please upload that file to VPS2 for the next step."
