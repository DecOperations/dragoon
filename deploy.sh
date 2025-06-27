#!/bin/bash

# Dragoon - Kali Linux Deployment Center
# Main deployment script

set -e

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="${SCRIPT_DIR}/config"
DEFAULT_CONFIG="${CONFIG_DIR}/default.conf"
DOCKER_DIR="${SCRIPT_DIR}/docker"

# Load default configuration
if [[ -f "${DEFAULT_CONFIG}" ]]; then
    source "${DEFAULT_CONFIG}"
else
    echo "Default configuration file not found. Creating..."
    mkdir -p "${CONFIG_DIR}"
    touch "${DEFAULT_CONFIG}"
fi

# Default values
KALI_VERSION=${KALI_VERSION:-"latest"}
CONTAINER_NAME=${CONTAINER_NAME:-"dragoon-kali"}
HOST_PORT=${HOST_PORT:-"2222"}
GUEST_PORT=${GUEST_PORT:-"22"}
DATA_DIR=${DATA_DIR:-"${SCRIPT_DIR}/data"}
ENABLE_GUI=${ENABLE_GUI:-"false"}
ADDITIONAL_TOOLS=${ADDITIONAL_TOOLS:-"aircrack-ng dirb sqlmap wireshark"}
NETWORK_MODE=${NETWORK_MODE:-""}
NETWORK_NAME=${NETWORK_NAME:-""}

# Create directories if they don't exist
mkdir -p "${DATA_DIR}"
mkdir -p "${DOCKER_DIR}"

# Help function
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -v, --version        Specify Kali version (default: latest)"
    echo "  -n, --name           Container name (default: dragoon-kali)"
    echo "  -p, --port           Host port mapping for SSH (default: 2222)"
    echo "  -g, --gui            Enable GUI mode (default: false)"
    echo "  -c, --config         Specify a custom config file"
    echo "  -d, --data-dir       Specify a custom data directory"
    echo "  -t, --tools          Specify additional tools to install (space-separated list in quotes)"
    echo ""
    echo "Examples:"
    echo "  $0 --version 2023.1 --port 8022 --gui"
    echo "  $0 --config custom.conf"
    echo "  $0 --tools \"aircrack-ng dirb sqlmap\""
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
            show_help
            exit 0
        ;;
        -v|--version)
            KALI_VERSION="$2"
            shift
            shift
        ;;
        -n|--name)
            CONTAINER_NAME="$2"
            shift
            shift
        ;;
        -p|--port)
            HOST_PORT="$2"
            shift
            shift
        ;;
        -g|--gui)
            ENABLE_GUI="true"
            shift
        ;;
        -c|--config)
            if [[ -f "$2" ]]; then
                source "$2"
            else
                echo "Error: Config file $2 not found"
                exit 1
            fi
            shift
            shift
        ;;
        -d|--data-dir)
            DATA_DIR="$2"
            mkdir -p "${DATA_DIR}"
            shift
            shift
        ;;
        -t|--tools)
            ADDITIONAL_TOOLS="$2"
            shift
            shift
        ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
        ;;
    esac
done

echo "=== Dragoon - Kali Linux Deployment ==="
echo "Version: ${KALI_VERSION}"
echo "Container name: ${CONTAINER_NAME}"
echo "Port mapping: ${HOST_PORT}:${GUEST_PORT}"
echo "Data directory: ${DATA_DIR}"
echo "GUI enabled: ${ENABLE_GUI}"
echo "Additional tools: ${ADDITIONAL_TOOLS}"
echo "======================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Create the Docker Compose file
create_docker_compose() {
  cat > "${DOCKER_DIR}/docker-compose.yml" << EOF
version: '3'

services:
  kali:
    image: kalilinux/kali-rolling:${KALI_VERSION}
    container_name: ${CONTAINER_NAME}
    hostname: kali
    restart: unless-stopped
    volumes:
      - "${DATA_DIR}:/data"
      - "${SCRIPT_DIR}/scripts:/scripts"
    ports:
      - "${HOST_PORT}:${GUEST_PORT}"
    environment:
      - ADDITIONAL_TOOLS="${ADDITIONAL_TOOLS}"
EOF
    
    if [[ "${ENABLE_GUI}" == "true" ]]; then
    cat >> "${DOCKER_DIR}/docker-compose.yml" << EOF
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix
EOF
    fi
    
  cat >> "${DOCKER_DIR}/docker-compose.yml" << EOF

    command: bash -c '/scripts/init.sh'
EOF
    
    # Add network configuration if specified
    if [[ -n "${NETWORK_MODE}" ]]; then
    cat >> "${DOCKER_DIR}/docker-compose.yml" << EOF
    network_mode: ${NETWORK_MODE}
EOF
        elif [[ -n "${NETWORK_NAME}" ]]; then
    cat >> "${DOCKER_DIR}/docker-compose.yml" << EOF
    networks:
      - ${NETWORK_NAME}
EOF
    fi
    
    # Add networks section if a custom network is specified
    if [[ -z "${NETWORK_MODE}" && -n "${NETWORK_NAME}" ]]; then
    cat >> "${DOCKER_DIR}/docker-compose.yml" << EOF

networks:
  ${NETWORK_NAME}:
    external: true
EOF
    fi
}

# Create initialization script
create_init_script() {
    mkdir -p "${SCRIPT_DIR}/scripts"
  cat > "${SCRIPT_DIR}/scripts/init.sh" << 'EOF'
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
    EOF
    
    chmod +x "${SCRIPT_DIR}/scripts/init.sh"
}

# Generate the Docker Compose file and init script
create_docker_compose
create_init_script

echo "Starting Kali Linux container..."
docker-compose -f "${DOCKER_DIR}/docker-compose.yml" up -d

echo "Kali Linux container is running!"
echo "SSH access: ssh -p ${HOST_PORT} root@localhost (password: kali)"
echo "Note: Please change the default password for security reasons."

# Provide information on how to access the container
echo ""
echo "Access Methods:"
echo "1. SSH: ssh -p ${HOST_PORT} root@localhost (password: kali)"
echo "2. Docker Exec: docker exec -it ${CONTAINER_NAME} /bin/bash"

exit 0