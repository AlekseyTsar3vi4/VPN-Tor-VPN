#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo -e "\n=== VPS 3 :: Final VPN Server Setup ===\n"

# System updates
echo "[+] Updating system packages..."
apt update -qq && apt dist-upgrade -y -qq

# Download and run OpenVPN installer
echo "[+] Installing OpenVPN (Road Warrior script)..."
wget -q https://git.io/vpn -O openvpn-install.sh
chmod +x openvpn-install.sh
./openvpn-install.sh

echo "[✔] OpenVPN installed successfully."

# Log sanitisation
CONF_PATH="/etc/openvpn/server.conf"
if [ -f "$CONF_PATH" ]; then
  echo "[+] Applying OpenVPN log sanitisation..."
  sed -i '/^log\|^status\|^log-append\|^verb/d' "$CONF_PATH"

  cat <<EOF >> "$CONF_PATH"

# Log sanitisation settings
log /dev/null
status /dev/null
log-append /dev/null
verb 0
EOF
else
  echo "[!] Warning: OpenVPN config not found at $CONF_PATH"
fi

# RAM-only journald logging
echo "[+] Enforcing RAM-only journald logging..."
mkdir -p /etc/systemd/journald.conf.d
cat <<EOF > /etc/systemd/journald.conf.d/privacy.conf
[Journal]
Storage=volatile
Compress=no
EOF
systemctl restart systemd-journald

# Enable OpenVPN service
echo "[+] Enabling OpenVPN service at boot..."
systemctl enable openvpn-server@server || echo "[!] Could not enable OpenVPN service - check service name."

# Identify most recent .ovpn file
echo ""
echo "[+] Locating latest OpenVPN client configuration..."
LATEST_OVPN=$(find /root -type f -name "*.ovpn" -printf "%T@ %p\n" 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)

if [[ -n "$LATEST_OVPN" ]]; then
  echo "[✔] Client configuration detected: $LATEST_OVPN"
  echo "[i] Please upload this file to VPS2 to connect to VPS3."
else
  echo "[!] No .ovpn file found in /root. Please check manually."
fi

echo "[✔] VPS 3 setup complete."
