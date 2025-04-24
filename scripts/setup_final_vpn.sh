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
echo "[✔] OpenVPN installed."

echo "[+] Applying OpenVPN log sanitisation..."
CONF_PATH="/etc/openvpn/server.conf"
if [ -f "$CONF_PATH" ]; then
  sed -i '/^log /d' "$CONF_PATH"
  sed -i '/^status /d' "$CONF_PATH"
  sed -i '/^log-append /d' "$CONF_PATH"
  sed -i '/^verb /d' "$CONF_PATH"
fi

cat <<EOF >> "$CONF_PATH"

# Log sanitisation settings
log /dev/null
status /dev/null
log-append /dev/null
verb 0

EOF

echo "[+] Enforcing journald volatile logging (RAM-only, no disk persistence)..."
mkdir -p /etc/systemd/journald.conf.d
cat <<EOF > /etc/systemd/journald.conf.d/privacy.conf
[Journal]
Storage=volatile
Compress=no
EOF
systemctl restart systemd-journald

echo ""
echo "[✔] OpenVPN server setup complete."
echo "[i] Your VPN client config is saved at: /root/<client-name>.ovpn"
echo "[i] Please upload that file to VPS2 for the next step."
