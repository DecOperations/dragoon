#!/bin/bash

# Dragoon - Kali Linux Initialization Script

set -e

echo "[+] Initializing Kali Linux..."

# Update system
echo "[+] Updating package lists..."
apt-get update

# Install essential tools
echo "[+] Installing essential tools..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
openssh-server \
metasploit-framework \
nmap \
curl \
wget \
python3-pip \
git

# Install additional tools if specified in the environment
if [[ -n "${ADDITIONAL_TOOLS}" ]]; then
    echo "[+] Installing additional tools: ${ADDITIONAL_TOOLS}"
    DEBIAN_FRONTEND=noninteractive apt-get install -y ${ADDITIONAL_TOOLS}
fi

# Configure SSH
echo "[+] Configuring SSH..."
mkdir -p /var/run/sshd
echo 'root:kali' | chpasswd
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Set up data directory permissions
if [[ -d "/data" ]]; then
    echo "[+] Setting up data directory..."
    chmod 755 /data
    chown root:root /data
fi

# Start SSH service
echo "[+] Starting SSH service..."
service ssh start

echo "[+] Initialization complete!"

# Create a welcome message
cat > /etc/motd << 'EOF'
 ____
|  _ \ _ __ __ _  __ _  ___   ___  _ __
| | | | '__/ _` |/ _` |/ _ \ / _ \| '_ \
| |_| | | | (_| | (_| | (_) | (_) | | | |
|____/|_|  \__,_|\__, |\___/ \___/|_| |_|
                 |___/

Kali Linux Deployment Center

Welcome to your Kali Linux instance!
All tools are ready to use.

For support, visit: https://github.com/yourusername/dragoon

EOF

# Keep the container running
tail -f /dev/null