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

This guide details the steps to set up a VPN -> Tor -> VPN chain using three separate VPS instances. The scripts provided automate most of the installation and configuration process.

## Prerequisites

Before you begin, ensure you have the following:

* **Three (3) separate VPS instances**, each running **Ubuntu 22.04 LTS**:
    * **VPS1**: Will host the Entry OpenVPN Server (acting as a Tor Proxy).
    * **VPS2**: Will host the Public Tor Exit Node and run an OpenVPN client connecting to VPS3.
    * **VPS3**: Will host the Final OpenVPN Server (the final VPN exit point).
* **`wget`** installed on all three VPS instances. This is the only package you need to install manually.

### Install `wget`

Connect to **each** of your three VPS instances via SSH and run the following command:

```
sudo apt update && sudo apt install wget -y
```

Once wget is installed, you can proceed with the setup steps below. You will download and run the necessary setup scripts directly from this repository using wget.

## Setup Steps

Follow these steps in the specified order.

### 1. Configure VPS2 — Public Tor Exit Node

First, set up the Tor exit node on VPS2.

1.  SSH into VPS2.
2.  Download, make executable, and run the `setup_exit_node.sh` script:

    ```
    wget https://raw.githubusercontent.com/AlekseyTsar3vi4/VPN-Tor-VPN/main/setup_exit_node.sh -O setup_exit_node.sh
    chmod +x setup_exit_node.sh
    sudo ./setup_exit_node.sh
    ```
3.  During the script execution, you will be prompted for:
    * A **Nickname** for your Tor exit node (e.g., `MyAwesomeExit`).
    * A **Password** for the Tor ControlPort. **Make sure to save this password securely.**
4.  After the script finishes:
    * Wait approximately **60–180 minutes** for your node to integrate into the Tor network.
    * You can check if your node is visible on the Tor Metrics page: <https://metrics.torproject.org/rs.html#/> (Search for your Nickname or IP address).

### 2. Configure VPS1 — Entry VPN Server (Tor Proxy)

Next, set up the entry OpenVPN server on VPS1. This server will route traffic through the Tor network (specifically, aiming for your exit node on VPS2).

1.  SSH into VPS1.
2.  Download, make executable, and run the `setup_entry_vpn.sh` script:

    ```
    wget https://raw.githubusercontent.com/AlekseyTsar3vi4/VPN-Tor-VPN/main/setup_entry_vpn.sh -O setup_entry_vpn.sh
    chmod +x setup_entry_vpn.sh
    sudo ./setup_entry_vpn.sh
    ```
3.  During the interactive OpenVPN installer part of the script:
    * **Select protocol**: `TCP`
    * **Port**: `1194` (or your preferred port)
    * **DNS**: Use the system default resolver (or choose another option if preferred).
    * **Client name**: Enter a descriptive name for your client configuration file (e.g., `vpn1-client`). The script will automatically append `.ovpn`.
4.  After setup:
    * The script will tell you the location of the generated `.ovpn` client configuration file (e.g., `/root/vpn1-client.ovpn`).
    * Download this `.ovpn` file from VPS1 to your local computer (using `scp` or an SFTP client (e.g. WinSCP)).
    * You will use this file with an OpenVPN client (like the OpenVPN Community Client) on your local machine to connect to the VPN->Tor->VPN chain.

### 3. Configure VPS3 — Final VPN Server (Exit Point)

Now, set up the final OpenVPN server on VPS3. This is the server that your Tor exit node (VPS2) will connect to.

1.  SSH into VPS3.
2.  Download, make executable, and run the `setup_final_vpn.sh` script:

    ```
    wget https://raw.githubusercontent.com/AlekseyTsar3vi4/VPN-Tor-VPN/main/setup_final_vpn.sh -O setup_final_vpn.sh
    chmod +x setup_final_vpn.sh
    sudo ./setup_final_vpn.sh
    ```
3.  During the interactive OpenVPN installer part of the script:
    * **Select protocol**: `TCP`
    * **Port**: `1194` (or your preferred port)
    * **DNS**: Use the system default resolver.
    * **Client name**: Enter a descriptive name (e.g., `vpn3-client-for-vps2`). The script will automatically append `.ovpn`.
4.  After setup:
    * Note the location of the generated `.ovpn` client file (e.g., `/root/vpn3-client-for-vps2.ovpn`).
    * Download this `.ovpn` file from VPS3 to your local computer.
    * Upload this `.ovpn` file from your local computer to VPS2 (e.g., into the `/root/` directory using `scp` or SFTP). You will need the path to this file in the next step.

### 4. Configure VPS2 — Route Tor Exit Through Final VPN

Finally, configure VPS2 to connect to the VPN server on VPS3 and route its Tor exit traffic through that VPN connection.

1.  SSH back into VPS2.
2.  Download, make executable, and run the `post_tor_to_vpn.sh` script:

    ```
    wget https://raw.githubusercontent.com/AlekseyTsar3vi4/VPN-Tor-VPN/main/post_tor_to_vpn.sh -O post_tor_to_vpn.sh
    chmod +x post_tor_to_vpn.sh
    sudo ./post_tor_to_vpn.sh
    ```
3.  When prompted:
    * Enter the **full path** to the `.ovpn` configuration file you uploaded to VPS2 in the previous step (e.g., `/root/vpn3-client-for-vps2.ovpn`).
4.  The script will perform the following actions:
    * Patch the provided `.ovpn` file to prevent DNS leaks.
    * Display your current public IP, gateway, and network range for reference.
    * Preview the routing table changes it intends to make.
    * Ask for your confirmation before applying the routing changes and starting the OpenVPN client connection to VPS3.

Setup is now complete.
---
### 🔍 Testing the Chain

#### ✅ What to Expect?

#### IP of VPS3
https://browserleaks.com/ip

##### No WebRTC/DNS leaks
https://dnsleaktest.com

---
### 📜 License
MIT License — open for educational, research, and privacy-aware personal use.

Designed, implemented and tested as a Cybersecurity Final Year Project
Focused on advanced anonymity systems, ethical deployment, and anti-surveillance techniques.
