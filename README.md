# 🚀 Nockchain Multi-Node Quickstart

<div align="center">

![Nockchain Logo](https://img.shields.io/badge/Nockchain-Multi--Node-blue?style=for-the-badge&logo=ethereum&logoColor=white)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20%7C%2022.04-orange?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Rust](https://img.shields.io/badge/Rust-Latest-red?style=for-the-badge&logo=rust&logoColor=white)](https://www.rust-lang.org/)

**Easily run multiple Nockchain miners on one server!**

[Quick Start](#-quick-start) •
[Installation](#-installation) •
[Configuration](#-configuration) •
[Troubleshooting](#-troubleshooting) •
[FAQ](#-faq)

</div>

---

## 📋 Table of Contents

- [✨ Features](#-features)
- [⚡ Quick Start](#-quick-start)
- [📋 Prerequisites](#-prerequisites)
- [🔧 Installation](#-installation)
- [⚙️ Configuration](#️-configuration)
- [🚀 Running Multiple Miners](#-running-multiple-miners)
- [📊 Monitoring](#-monitoring)
- [🛠️ Troubleshooting](#️-troubleshooting)
- [❓ FAQ](#-faq)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

## ✨ Features

- 🏃‍♂️ **One-Click Setup** - Automated script for multiple miner deployment
- 📊 **Resource Management** - Intelligent RAM allocation per instance
- 🔧 **Auto Configuration** - Automatic port and directory management
- 📺 **Screen Sessions** - Each miner runs in its own screen session
- 🔍 **Easy Monitoring** - Built-in commands for status checking
- 🛡️ **Firewall Ready** - Automatic UFW port configuration

## ⚡ Quick Start

```bash
# Clone this repository
git clone https://github.com/ashishki/nockchain-multinode-quickstart.git
cd nockchain-multinode-quickstart

# Make script executable
chmod +x setup_nockchain_multi.sh

# Run the setup
./setup_nockchain_multi.sh
```

## 📋 Prerequisites

<table>
<tr>
<td align="center">
<img src="https://img.shields.io/badge/OS-Ubuntu%2020.04%2F22.04-orange?style=flat-square&logo=ubuntu" alt="Ubuntu">
<br><strong>Ubuntu 20.04/22.04</strong>
</td>
<td align="center">
<img src="https://img.shields.io/badge/RAM-18GB%20per%20miner-blue?style=flat-square&logo=memory" alt="RAM">
<br><strong>~18GB RAM per miner</strong>
</td>
<td align="center">
<img src="https://img.shields.io/badge/Network-UDP%20Ports-green?style=flat-square&logo=network-wired" alt="Network">
<br><strong>Open UDP ports</strong>
</td>
</tr>
</table>

> ⚠️ **Memory Warning**: Each miner will consume up to 17-20GB RAM as blocks sync!

## 🔧 Installation

### Step 1: Clone & Build Official Nockchain

```bash
# Clone the official repository
git clone https://github.com/zorp-corp/nockchain.git
cd nockchain
```

### Step 2: Install Rust & Dependencies

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
rustup update

# Install system dependencies
sudo apt update && sudo apt install -y \
    build-essential \
    clang \
    llvm-dev \
    libclang-dev \
    screen \
    ufw \
    make
```

### Step 3: Compile Nockchain

```bash
# Install and build components
make install-hoonc
export PATH="$HOME/.cargo/bin:$PATH"

make build

make install-nockchain-wallet
make install-nockchain
export PATH="$HOME/.cargo/bin:$PATH"
```

## ⚙️ Configuration

### Generate Mining Keys

```bash
# Generate your miner keypair
nockchain-wallet keygen

# Export keys for backup
nockchain-wallet export-keys
```

> 💾 **Important**: Save your public key and backup your `keys.export` file!

### System Optimization

```bash
# Prevent serf panics
sudo sysctl -w vm.overcommit_memory=1
echo 'vm.overcommit_memory=1' | sudo tee -a /etc/sysctl.conf
```

## 🚀 Running Multiple Miners

### Download Setup Script

Place the `setup_nockchain_multi.sh` script in your built nockchain folder:

```
nockchain/
├── setup_nockchain_multi.sh  ← Place here
├── .env_example
├── target/release/nockchain
└── ...
```

### Run the Script

```bash
chmod +x setup_nockchain_multi.sh
./setup_nockchain_multi.sh
```

The script will prompt you for:
- 🔢 **Number of miners** (consider your RAM limits)
- 🔑 **Your public key** (from keygen step)
- 🌐 **Starting UDP port** (e.g., 2001)
- 📡 **Bind IP address** (public IP if behind NAT)

### Script Output

```
🚀 Setting up 3 Nockchain miners...
📁 Creating directories...
⚙️  Configuring miners...
🔥 Starting miners...
✅ All miners started successfully!

🔍 Check status with: screen -ls
📊 Monitor miner: screen -r miner_1
```

## 📊 Monitoring

### Check Running Miners

```bash
# List all screen sessions
screen -ls

# Attach to a specific miner
screen -r miner_1

# Detach from screen (inside session)
Ctrl+A, then D
```

### Check Wallet Balance

```bash
nockchain-wallet --nockchain-socket .socket/nockchain1.sock \
    list-notes-by-pubkey -p <your_pubkey>
```

### Monitor System Resources

```bash
# Check RAM usage
free -h

# Check CPU usage
htop

# Check open ports
sudo ss -ulpn | grep nockchain
```

![System Monitor](images/top_htop.png)

### Mining Status Indicators

Look for these log messages:
```
✅ [%mining-on ...] - Mining is active
✅ block ... added to validated blocks at ... - Block found!
🔗 Connected to peer ... - Network connection established
```

## 🛠️ Troubleshooting

<details>
<summary><strong>🔌 Peer Connection Issues</strong></summary>

- Verify ports are open: `sudo ufw status`
- Check NAT/router port forwarding
- Validate bind IP/port configuration
- Ensure no port conflicts between miners
</details>

<details>
<summary><strong>🚫 Node Won't Start</strong></summary>

```bash
# Kill stuck processes
ps aux | grep nockchain
sudo kill <pid>

# Clean up stale files
rm -rf .data.nockchain .socket/*
```
</details>

<details>
<summary><strong>⛏️ Mining Not Working</strong></summary>

- Verify correct pubkey in configuration
- Ensure `--mine` flag is set
- Check system resources (RAM/CPU)
- Wait for sync completion (may take time)
</details>

<details>
<summary><strong>💾 High Memory Usage</strong></summary>

- Normal behavior as blockchain syncs
- Monitor with `free -h` and `htop`
- Reduce miner count if insufficient RAM
- Consider swap file for temporary relief
</details>

For more detailed troubleshooting, see [troubleshooting.md](troubleshooting.md).

## ❓ FAQ

<details>
<summary><strong>How many miners can I run?</strong></summary>

Depends on your RAM: `Available RAM ÷ 18GB = Max miners`

Example: 64GB RAM = ~3 miners maximum
</details>

<details>
<summary><strong>Can I use the same pubkey for all miners?</strong></summary>

Yes! The latest repository allows multiple miners with the same public key.
</details>

<details>
<summary><strong>How do I stop all miners?</strong></summary>

```bash
# Stop specific miner
screen -S miner_1 -X quit

# Stop all miners
for i in {1..5}; do screen -S miner_$i -X quit 2>/dev/null; done
```
</details>

<details>
<summary><strong>How do I reset everything?</strong></summary>

```bash
# Remove all node directories
rm -rf node*

# Kill any remaining processes
pkill -f nockchain
```
</details>

<details>
<summary><strong>Port forwarding for NAT/Proxmox?</strong></summary>

Forward UDP ports: `external_port → VM_IP:internal_port`

Example: `2001 → 192.168.1.100:2001`
</details>

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**⭐ Star this repository if it helped you!**

Made with ❤️ by [YOURNAME](https://github.com/YOURNAME)

[Official Nockchain Repository](https://github.com/zorp-corp/nockchain) | [Report Issues](https://github.com/YOURNAME/nockchain-multinode-quickstart/issues)

</div>