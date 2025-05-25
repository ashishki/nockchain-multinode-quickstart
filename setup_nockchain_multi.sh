#!/bin/bash

# ==========================================================
#  Nockchain Multi-Node Quick Installer (screen+FAQ version)
#  Author: YOURNAME (https://github.com/yourgithub)
# ==========================================================

echo "========== Nockchain Multi-Node Quick Setup =========="

# --------- 1. Check and install required tools ----------
NEEDED="screen ufw sed make"
for tool in $NEEDED; do
    if ! command -v $tool &>/dev/null; then
        echo "Missing $tool. Installing..."
        sudo apt update
        sudo apt install -y $tool
    fi
done

# --------- 2. Check for .env_example ---------
if [ ! -f .env_example ]; then
    echo "ERROR: .env_example not found. Please run this script from your nockchain directory!"
    exit 1
fi

# --------- 3. Set vm.overcommit_memory=1 ---------
OCM=$(sysctl -n vm.overcommit_memory)
if [ "$OCM" != "1" ]; then
    echo "Applying sysctl fix for Nockchain ('vm.overcommit_memory=1')"
    sudo sysctl -w vm.overcommit_memory=1
    grep -q "vm.overcommit_memory" /etc/sysctl.conf || \
        echo "vm.overcommit_memory=1" | sudo tee -a /etc/sysctl.conf
fi

# --------- 4. User input (miners, pubkey, ports) ---------
read -p "How many miners do you want to launch (recommendation: RAM (GB) / 18)? " N
read -p "Paste your MINING_PUBKEY: " PUBKEY
read -p "Enter the starting UDP port [default: 2001]: " BASE_PORT
BASE_PORT=${BASE_PORT:-2001}

MY_IP=$(hostname -I | awk '{print $1}')
read -p "Detected your local IP as $MY_IP. Use this for --bind? [Y/n]: " ANS
if [[ $ANS =~ ^[Nn] ]]; then
    read -p "Enter IP to bind to (public if behind NAT): " MY_IP
fi

echo "Your nodes will be bound to $MY_IP and use ports $BASE_PORT-$((BASE_PORT + N - 1))."
read -p "Proceed with creation and open ports via ufw? [Y/n]: " PR
if [[ $PR =~ ^[Nn] ]]; then
    echo "Aborted."
    exit 1
fi

# --------- 5. Open UDP ports via ufw ---------
for i in $(seq 0 $((N-1))); do
    PORT=$((BASE_PORT + i))
    sudo ufw allow $PORT/udp
done

echo "Ports $BASE_PORT-$((BASE_PORT + N - 1)) (UDP) are opened via ufw."

# --------- 6. Check free RAM (optional) ---------
FREE_RAM=$(free -g | awk '/Mem:/{print $7}')
if (( N * 18 > FREE_RAM )); then
    echo "WARNING: You have less free RAM ($FREE_RAM GB) than recommended ($((N * 18)) GB) for $N miners!"
    read -p "Continue anyway? [y/N]: " RSP
    if [[ ! $RSP =~ ^[Yy] ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# --------- 7. Setup and launch miners (one screen per miner) ---------
echo "Setting up miners..."

for i in $(seq 1 $N); do
    NODEDIR="node$i"
    PORT=$((BASE_PORT + i - 1))
    SOCK="../.socket/nockchain${i}.sock"
    mkdir -p "$NODEDIR"
    cp .env_example "$NODEDIR/.env"
    sed -i "s|^MINING_PUBKEY=.*|MINING_PUBKEY=$PUBKEY|" "$NODEDIR/.env"
    cd "$NODEDIR"
    echo "Launching miner $i on port $PORT in screen session 'miner_$i'..."
    screen -dmS "miner_$i" bash -c "
        RUST_LOG=info ../target/release/nockchain \
        --mining-pubkey $PUBKEY \
        --mine \
        --peer /ip4/95.216.102.60/udp/3006/quic-v1 \
        --peer /ip4/65.108.123.225/udp/3006/quic-v1 \
        --peer /ip4/65.109.156.108/udp/3006/quic-v1 \
        --peer /ip4/65.21.67.175/udp/3006/quic-v1 \
        --peer /ip4/65.109.156.172/udp/3006/quic-v1 \
        --peer /ip4/34.174.22.166/udp/3006/quic-v1 \
        --peer /ip4/34.95.155.151/udp/30000/quic-v1 \
        --peer /ip4/34.18.98.38/udp/30000/quic-v1 \
        --npc-socket $SOCK \
        --bind /ip4/$MY_IP/udp/${PORT}/quic-v1"
    cd ..
done

# --------- 8. Show screen session info and usage instructions ---------
echo ""
echo "========== LAUNCH COMPLETE =========="
echo ""
echo "Your miners are running in separate 'screen' sessions named miner_1, miner_2, ..., miner_$N."
echo ""
echo "Useful screen commands:"
echo "  - List all sessions:         screen -ls"
echo "  - Attach to miner_1:         screen -r miner_1"
echo "  - Detach from a session:     Press Ctrl+A, then D"
echo "  - Kill a session:            screen -S miner_1 -X quit"
echo ""
echo "To check running nockchain processes: ps aux | grep nockchain"
echo "To check free memory:         free -h   OR   htop"
echo ""
echo "To check wallet for miner 1:"
echo "  nockchain-wallet --nockchain-socket .socket/nockchain1.sock list-notes-by-pubkey -p $PUBKEY"
echo ""
echo "If you see 'serf panic' or connection issues, ensure sysctl vm.overcommit_memory=1 is set!"
echo ""
echo "For troubleshooting and full docs, visit the official repo or your local README."
echo ""
echo "Enjoy mining!  — ashishki"