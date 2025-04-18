#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo -e "\n=== VPS 2 :: Tor Exit Node Setup ==="

echo "[+] Updating system and installing required packages..."
apt update -qq
apt dist-upgrade -y -qq
apt install -y -qq curl gnupg2 apt-transport-https lsb-release tor net-tools iptables-persistent psmisc

echo "[+] Adding the official Tor repository..."
TOR_GPG_KEY_URL="https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc"
curl -fsSL "$TOR_GPG_KEY_URL" | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org $(lsb_release -cs) main" \
  | tee /etc/apt/sources.list.d/tor.list > /dev/null

echo "[+] Installing Tor and verifying version..."
apt update -qq
apt install -y -qq tor deb.torproject.org-keyring
tor --version

echo ""
read -rp "[?] Enter a Nickname for your Tor Exit Node: " NODE_NAME
read -rsp "[?] Set password for ControlPort (will be hashed): " USER_PASS
echo ""
HASHED_PASS=$(tor --hash-password "$USER_PASS" | tail -n 1)
echo "[+] Hashed password generated."

echo "[+] Cleaning up default torrc..."
rm -f /etc/tor/torrc

echo "[+] Writing new torrc configuration..."
cat <<EOF > /etc/tor/torrc
# === Identity ===
Nickname $NODE_NAME
ORPort 9001
ExitRelay 1
SocksPort 0
ControlPort 9051
HashedControlPassword $HASHED_PASS

# === Exit Policy: Allow SSH + Common Web Ports Only ===
ExitPolicy reject *:25
ExitPolicy reject *:119
ExitPolicy reject *:135-139
ExitPolicy reject *:445
ExitPolicy reject *:563
ExitPolicy reject *:1214
ExitPolicy reject *:4661-4666
ExitPolicy reject *:6346-6429
ExitPolicy reject *:6699
ExitPolicy reject *:6881-6999
ExitPolicy accept *:*

# === Security ===
CookieAuthentication 1
CookieAuthFileGroupReadable 1
DisableDebuggerAttachment 1

# === Network Behaviour ===
ClientUseIPv4 1
ClientUseIPv6 0
FetchUselessDescriptors 0
EOF

echo ""
echo "[✔] Configuration complete."
echo "[i] Starting Tor in foreground..."
echo "[i] You can monitor logs with: tail -f /var/log/tor/notices.log"
echo ""

# Start Tor in foreground for verification
sleep 2
exec tor -f /etc/tor/torrc
