# 🛡️ VPN → Tor Exit → VPN Chain: Multi-Hop Anonymity System

This project was developed as part of a **Final Year Project (FYP)** in Cybersecurity, aiming to implement and test a resilient multi-hop traffic obfuscation model combining VPN and Tor in a layered privacy chain.

It leverages:
- A self-hosted Tor exit node
- OpenVPN server-client tunnels
- Transparent routing and DNS redirection
- Policy-based routing (Linux advanced routing table)
- DNS and WebRTC leak protection

---

## 🔁 Architecture Diagram

![vpn-tor-vpn-chain](https://github.com/user-attachments/assets/ff9cfd75-095e-4ad2-94df-497d8733a30d)

**Traffic Flow Explanation:**

1.  **Your PC:** Connects to VPS 1 using an OpenVPN client configuration.
2.  **VPS 1 (Entry VPN Server):** Receives traffic via OpenVPN, then transparently routes it into the Tor network, directing it specifically towards your self-hosted Tor exit node (VPS 2).
3.  **VPS 2 (Tor Exit Node):** Traffic exits the Tor network here. This VPS then immediately connects as an OpenVPN *client* to VPS 3.
4.  **VPS 3 (Final VPN Server):** Receives traffic from VPS 2 via OpenVPN and sends it to the final internet destination. Your public IP appears as VPS 3's IP address.

This design offers **multi-layered anonymity** and mitigates correlation attacks, metadata leaks, and single point-of-failure risks often seen in simpler proxy models.

---

## 🧪 Testing Environment

The setup was tested on **DigitalOcean** using three VPS instances running **Ubuntu 22.04 LTS**. All configurations were deployed and verified manually and through automation scripts.

> ⚠️ **Important:** While DigitalOcean is suitable for testing, it is not recommended for real-world privacy-critical deployments.

---

## 🛡️ Real-World Deployment Considerations

To harden this system against surveillance and jurisdictional overreach:

### 🌍 Use Privacy-Friendly Jurisdictions

Deploy VPS servers in countries with **strong privacy laws** that are:
- **Outside the Five Eyes, Nine Eyes, and Fourteen Eyes alliances**
- Not known for mandatory data retention laws
- Not cooperating with mass surveillance programmes

**Example provider:**
🔗 [https://1984.hosting/](https://1984.hosting/) — based in Iceland, known for strong privacy policies

---

### 🔐 Maintain Proper Operational Security (OpSec)

To maintain anonymity and reduce traceability:
- Never use your **real name, phone number, or payment details**
- Use **burner email addresses** (e.g. [SimpleLogin](https://simplelogin.io), [AnonAddy](https://anonaddy.com))
- Purchase VPS servers with **privacy-preserving cryptocurrencies** such as:
  - Monero (XMR) — ideal for anonymous payments
  - Bitcoin via privacy mixers (if Monero is not accepted)
- Use **hardened devices** or virtual machines for configuration
- Avoid login from personal or previously linked IP addresses
- Segment and isolate each VPS for single-purpose usage

---

## 📦 Project Structure

```
vpn-tor-vpn-chain/
├── README.md
├── scripts/
│   ├── setup_entry_vpn.sh    # VPS1
│   ├── setup_exit_node.sh    # VPS2 (Tor Exit)
│   ├── post_tor_to_vpn.sh    # VPS2 → VPS3
│   └── setup_final_vpn.sh    # VPS3
└── configs/
└── example.ovpn              # VPN client config (template)
```

---

## 🛠️ Setup Instructions

### 🖥️ Step 1 - VPS2 — Configure Tor Exit Node
```
scripts/setup_exit_node.sh
```
##### What this does:

- Installs and configures Tor
- Asks you to set a nickname and control port password
- Configures it as a full Tor exit relay (not just a proxy)
- Exit policy: allows web and SSH, blocks abuse ports
- Uploads to metrics.torproject.org

##### Important!
##### 🕓 Wait ~ 120 minutes for the node to appear online (you should be able to find you node here: [Relay Search](https://metrics.torproject.org/rs.html#) and marked as:

![image](https://github.com/user-attachments/assets/991da134-4cee-4455-aef7-5b0fec09404b)


### 🌐 Step 2 - VPS1 — Entry VPN Server with Tor Routing 
```
scripts/setup_entry_vpn.sh
```
##### This script:

- Installs OpenVPN
💡 During setup, you will be prompted by an interactive OpenVPN installer. **Please make sure to:**
  - Select TCP when asked for the protocol
  - Choose port 1194 for OpenVPN
  - Select system default resolver for DNS (not Google or Cloudflare)
  - When prompted, enter a filename for the .ovpn client config (e.g. vpn1client.ovpn)
- Uses /etc/openvpn/server.conf
- Routes VPN traffic to:
  - Tor's TransPort → for TCP redirection
  - Tor's DNSPort → for DNS queries
- Adds torrc entries:
  - When prompted, enter a nickname or IP address of you Exit Node created in the previous step. 
```
VirtualAddrNetwork 10.192.0.0/10
AutomapHostsOnResolve 1
DNSPort 10.8.0.1:53530
TransPort 10.8.0.1:9040
ExitNodes <nickname or IP address of the exit node>
StrictNodes 1 <this explicitly tells to use only exit node specified in <ExitNodes> entry>
```
- Output: A .ovpn client config file will be generated.

##### Important!
##### 📥 Download it to your local PC and use it to connect!

### 🔒 Step 3 - VPS3 — Final VPN Server
```
bash scripts/setup_final_vpn.sh
```
##### This sets up:

- OpenVPN Server. During setup, you will be prompted by an interactive OpenVPN installer (Same as on VPS1).

##### Please make sure to:
  - Select TCP when asked for the protocol
  - Choose port 1194 for OpenVPN
  - Select system default resolver for DNS (not Google or Cloudflare)
  - When prompted, enter a filename for the .ovpn client config (e.g. vpn1client.ovpn)
- Generates a client .ovpn file

##### Important!
##### 📤 Upload the .ovpn config to VPS2 (e.g. via scp, winscp or nano paste)

### 🔁 Step 4 - VPS2 — Route Tor Exit Traffic into Final VPN

Open a new Terminal session and run:
```
bash scripts/post_tor_to_vpn.sh
```
##### What this does:

- Installs OpenVPN client + systemd DNS hooks
- Injects DNS leak protection into the .ovpn before verb 3
- Detects:
  - Public IP (eth0)
  - Default gateway
  - Network CIDR
- Shows the current routing table
- Prompts you:
Does this match your address schema based on the routing table? [y/N]
  - ✅ If yes → Applies ip rule and ip route entries to table 128
  - ❌ If no → Exits cleanly for manual intervention
- Starts OpenVPN client and forwards all Tor exit traffic to final VPN (VPS3)
---
### 🔍 Testing the Chain

#### ✅ What to Expect?

#### IP of VPS3
https://browserleaks.com/ip

##### No WebRTC/DNS leaks
https://dnsleaktest.com

### 📜 License
MIT — free to study, fork, adapt, and deploy.
Created as part of a Cyber Security Final Year Project — designed for both research and real-world deployment use.
