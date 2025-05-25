# 🛠️ Nockchain Multi-Node Troubleshooting Guide

<div align="center">

![Troubleshooting](https://img.shields.io/badge/Status-Troubleshooting-red?style=for-the-badge&logo=tools&logoColor=white)
[![Back to README](https://img.shields.io/badge/Back%20to-README-blue?style=for-the-badge)](README.md)

**Complete guide for solving common Nockchain multi-node issues**

</div>

---

## 📋 Table of Contents

- [🔍 Quick Diagnostics](#-quick-diagnostics)
- [🔌 Network Issues](#-network-issues)
- [💾 Memory Issues](#-memory-issues)
- [🔄 Process Management](#-process-management)
- [⛏️ Mining Issues](#️-mining-issues)
- [🔧 Configuration Problems](#-configuration-problems)
- [📊 Monitoring & Debugging](#-monitoring--debugging)
- [🚨 Emergency Procedures](#-emergency-procedures)
- [📞 Getting Help](#-getting-help)

## 🔍 Quick Diagnostics

Run these commands first to get an overview of your system:

```bash
# System resource check
echo "=== SYSTEM RESOURCES ==="
free -h
echo ""
df -h
echo ""

# Process check
echo "=== NOCKCHAIN PROCESSES ==="
ps aux | grep nockchain
echo ""

# Network check
echo "=== NETWORK STATUS ==="
sudo ss -ulpn | grep -E "(200[0-9]|2010)"
echo ""

# Screen sessions
echo "=== SCREEN SESSIONS ==="
screen -ls
```

## 🔌 Network Issues

### ❌ Problem: Miners can't connect to peers

**Symptoms:**
- No peer connections in logs
- Mining status shows "disconnected"
- Timeout errors

**Solutions:**

1. **Check firewall status:**
   ```bash
   sudo ufw status
   
   # If inactive, enable it
   sudo ufw enable
   
   # Open required ports (example for 3 miners starting from port 2001)
   sudo ufw allow 2001:2003/udp
   sudo ufw reload
   ```

2. **Verify port availability:**
   ```bash
   # Check if ports are actually open
   sudo ss -ulpn | grep :2001
   
   # Test port connectivity (from another machine)
   nc -u -v YOUR_SERVER_IP 2001
   ```

3. **Check NAT/Router configuration:**
   - Forward UDP ports: `external_port → VM_IP:internal_port`
   - Example: `2001 → 192.168.1.100:2001`

### ❌ Problem: Port already in use

**Error message:** `Address already in use (os error 98)`

**Solution:**
```bash
# Find what's using the port
sudo ss -ulpn | grep :2001
sudo lsof -i :2001

# Kill the process if it's a stuck miner
sudo kill -9 <PID>

# Or kill all nockchain processes
sudo pkill -f nockchain
```

### ❌ Problem: Binding to wrong interface

**Symptoms:**
- Miner starts but no external connections
- Works locally but not from outside

**Solution:**
```bash
# Check your IP addresses
ip addr show

# Common bind configurations:
# For local testing: --bind /ip4/127.0.0.1/udp/2001/quic-v1
# For LAN access: --bind /ip4/192.168.1.100/udp/2001/quic-v1  
# For public access: --bind /ip4/YOUR_PUBLIC_IP/udp/2001/quic-v1
# For all interfaces: --bind /ip4/0.0.0.0/udp/2001/quic-v1
```

## 💾 Memory Issues

### ❌ Problem: System runs out of memory

**Symptoms:**
- Miners crash unexpectedly
- System becomes unresponsive
- OOM (Out of Memory) errors in logs
- `killed` messages in screen sessions

**Solutions:**

1. **Calculate safe miner count:**
   ```bash
   # Check total RAM
   total_ram_gb=$(free -g | awk '/^Mem:/{print $2}')
   max_miners=$((total_ram_gb / 18))
   echo "Total RAM: ${total_ram_gb}GB"
   echo "Maximum safe miners: ${max_miners}"
   ```

2. **Monitor memory usage:**
   ```bash
   # Real-time memory monitoring
   watch -n 1 'free -h'
   
   # Check memory per process
   ps aux --sort=-%mem | head -10
   
   # Check swap usage
   swapon --show
   ```

3. **Add swap space (temporary relief):**
   ```bash
   # Create 16GB swap file
   sudo fallocate -l 16G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   
   # Make permanent
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   
   # Verify
   free -h
   ```

4. **Optimize memory settings:**
   ```bash
   # Prevent overcommit issues
   sudo sysctl -w vm.overcommit_memory=1
   sudo sysctl -w vm.swappiness=10
   
   # Make permanent
   echo 'vm.overcommit_memory=1' | sudo tee -a /etc/sysctl.conf
   echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
   ```

### ❌ Problem: Memory leak in miners

**Symptoms:**
- Memory usage keeps growing
- Performance degrades over time

**Solution:**
```bash
# Restart miners periodically (cron job)
cat > restart_miners.sh << 'EOF'
#!/bin/bash
for i in {1..3}; do
    screen -S miner_$i -X quit
    sleep 5
    cd node$i && screen -dmS miner_$i bash -c "RUST_LOG=info ../target/release/nockchain --config .env; exec bash"
done
EOF

chmod +x restart_miners.sh

# Add to crontab (restart every 6 hours)
(crontab -l; echo "0 */6 * * * /path/to/restart_miners.sh") | crontab -
```

## 🔄 Process Management

### ❌ Problem: Miners stuck or not responding

**Symptoms:**
- Screen session exists but miner not working
- No new log messages
- High CPU usage but no progress

**Solutions:**

1. **Graceful restart:**
   ```bash
   # Stop specific miner
   screen -S miner_1 -X quit
   
   # Clean up files
   cd node1
   rm -rf .data.nockchain .socket/
   
   # Restart
   screen -dmS miner_1 bash -c "RUST_LOG=info ../target/release/nockchain --config .env; exec bash"
   ```

2. **Force kill if needed:**
   ```bash
   # Find the process
   ps aux | grep "nockchain.*node1"
   
   # Kill by PID
   sudo kill -9 <PID>
   
   # Or kill by pattern
   sudo pkill -f "nockchain.*node1"
   ```

3. **Clean restart all miners:**
   ```bash
   # Stop all miners
   for i in {1..5}; do 
       screen -S miner_$i -X quit 2>/dev/null
   done
   
   # Wait and force kill if needed
   sleep 10
   sudo pkill -f nockchain
   
   # Clean up
   rm -rf node*/.data.nockchain node*/.socket/
   
   # Restart with script
   ./setup_nockchain_multi.sh
   ```

### ❌ Problem: Screen sessions disappear

**Symptoms:**
- `screen -ls` shows no sessions
- Miners were running but now gone

**Solution:**
```bash
# Check if processes are still running without screen
ps aux | grep nockchain

# If running, kill and restart properly
sudo pkill -f nockchain

# Restart with proper screen sessions
./setup_nockchain_multi.sh
```

## ⛏️ Mining Issues

### ❌ Problem: Mining not starting

**Symptoms:**
- Node syncs but doesn't mine
- No `[%mining-on ...]` messages
- Wallet shows no mining rewards

**Solutions:**

1. **Verify configuration:**
   ```bash
   # Check .env file in each node directory
   for i in {1..3}; do
       echo "=== Node $i configuration ==="
       cat node$i/.env | grep -E "(MINING_PUBKEY|MINE)"
       echo ""
   done
   ```

2. **Check mining status in logs:**
   ```bash
   # Attach to screen and look for mining messages
   screen -r miner_1
   
   # Look for these patterns:
   # ✅ [%mining-on ...] - Mining active
   # ❌ [%mining-off ...] - Mining disabled
   ```

3. **Verify wallet setup:**
   ```bash
   # Check if wallet recognizes the pubkey
   nockchain-wallet --nockchain-socket .socket/nockchain1.sock \
       list-notes-by-pubkey -p YOUR_PUBKEY
   ```

### ❌ Problem: Low mining performance

**Symptoms:**
- Mining active but few blocks found
- Lower hash rate than expected

**Solutions:**

1. **Check system resources:**
   ```bash
   # CPU usage
   htop
   
   # I/O wait
   iostat -x 1
   
   # Network bandwidth
   iftop
   ```

2. **Optimize CPU scheduling:**
   ```bash
   # Set CPU governor to performance
   sudo cpupower frequency-set -g performance
   
   # Check current governor
   cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
   ```

## 🔧 Configuration Problems

### ❌ Problem: Environment variables not loaded

**Symptoms:**
- Miner starts with default config
- Missing pubkey or other settings

**Solution:**
```bash
# Check if .env file exists and is readable
for i in {1..3}; do
    echo "=== Node $i .env file ==="
    ls -la node$i/.env
    cat node$i/.env
    echo ""
done

# Verify environment loading
cd node1
source .env
echo $MINING_PUBKEY
```

### ❌ Problem: Path issues

**Symptoms:**
- `nockchain command not found`
- Script can't find binaries

**Solution:**
```bash
# Check PATH
echo $PATH

# Add cargo bin to PATH permanently
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
which nockchain
which nockchain-wallet
```

## 📊 Monitoring & Debugging

### Comprehensive system monitoring

```bash
#!/bin/bash
# save as monitor_system.sh

while true; do
    clear
    echo "=== NOCKCHAIN MULTI-NODE MONITOR ==="
    echo "Time: $(date)"
    echo ""
    
    echo "=== MEMORY USAGE ==="
    free -h
    echo ""
    
    echo "=== DISK USAGE ==="
    df -h | grep -E "(/$|/home)"
    echo ""
    
    echo "=== ACTIVE MINERS ==="
    screen -ls | grep miner || echo "No active miners"
    echo ""
    
    echo "=== NETWORK PORTS ==="
    sudo ss -ulpn | grep -E "(200[0-9]|2010)" | wc -l
    echo "Active UDP ports: $(sudo ss -ulpn | grep -E "(200[0-9]|2010)" | wc -l)"
    echo ""
    
    echo "=== PROCESS COUNT ==="
    ps aux | grep -c nockchain
    echo "Nockchain processes: $(ps aux | grep -c nockchain)"
    echo ""
    
    echo "Press Ctrl+C to exit"
    sleep 5
done
```

### Debug logging

```bash
# Enable verbose logging for debugging
export RUST_LOG=debug

# Or even more verbose
export RUST_LOG=trace

# Check log output
screen -r miner_1
```

## 🚨 Emergency Procedures

### Nuclear option: Complete reset

```bash
#!/bin/bash
# save as emergency_reset.sh

echo "🚨 EMERGENCY RESET - This will stop all miners and clean everything!"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    echo "Stopping all screen sessions..."
    screen -wipe
    for i in {1..10}; do 
        screen -S miner_$i -X quit 2>/dev/null
    done
    
    echo "Killing all nockchain processes..."
    sudo pkill -f nockchain
    sleep 5
    sudo pkill -9 -f nockchain
    
    echo "Removing all node directories..."
    rm -rf node*
    
    echo "Cleaning up sockets..."
    rm -rf .socket/
    
    echo "Reset complete! Run setup script to start fresh."
else
    echo "Reset cancelled."
fi
```

### System recovery

```bash
# If system becomes unresponsive
sudo sysctl -w kernel.sysrq=1
echo f | sudo tee /proc/sysrq-trigger  # Force OOM killer

# Reboot if necessary
sudo reboot
```

## 📞 Getting Help

### Before asking for help, collect this information:

```bash
#!/bin/bash
# save as collect_debug_info.sh

echo "=== NOCKCHAIN DEBUG INFO ==="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo ""

echo "=== SYSTEM INFO ==="
uname -a
lsb_release -a
echo ""

echo "=== MEMORY ==="
free -h
echo ""

echo "=== DISK ==="
df -h
echo ""

echo "=== PROCESSES ==="
ps aux | grep nockchain
echo ""

echo "=== NETWORK ==="
sudo ss -ulpn | grep -E "(200[0-9]|2010)"
echo ""

echo "=== SCREEN SESSIONS ==="
screen -ls
echo ""

echo "=== RECENT ERRORS ==="
journalctl --since "1 hour ago" | grep -i error | tail -10
```

### Where to get help:

1. **Check the logs** in your screen sessions first
2. **Search existing issues** in the GitHub repository  
3. **Run the debug info collector** script above
4. **Create a new issue** with:
   - Your system specs (RAM, CPU, OS version)
   - Number of miners you're trying to run
   - Complete error messages (copy-paste, don't screenshot)
   - Steps to reproduce the problem
   - Output from the debug info script

### Common support channels:

- 🐛 **GitHub Issues**: [Create an issue](https://github.com/YOURNAME/nockchain-multinode-quickstart/issues)
- 💬 **Community Discord**: Check the official Nockchain Discord
- 📧 **Email Support**: Include debug info in your email

---

<div align="center">

**🔧 Still having issues?**

[Create an Issue](https://github.com/YOURNAME/nockchain-multinode-quickstart/issues) • [Back to README](README.md) • [Official Nockchain Repo](https://github.com/zorp-corp/nockchain)

</div>