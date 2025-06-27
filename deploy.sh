/data"
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

# Publish to boxes.wtf registry if requested
if [[ "${PUBLISH_TO_REGISTRY}" == "true" ]]; then
    echo ""
    echo "Publishing to boxes.wtf registry..."
    
    # Build publish command
    PUBLISH_CMD="${SCRIPT_DIR}/scripts/publish.sh"
    
    if [[ -n "${BOX_NAME}" ]]; then
        PUBLISH_CMD="${PUBLISH_CMD} --name \"${BOX_NAME}\""
    fi
    
    if [[ -n "${BOX_VERSION}" ]]; then
        PUBLISH_CMD="${PUBLISH_CMD} --version \"${BOX_VERSION}\""
    fi
    
    if [[ -n "${BOX_DESCRIPTION}" ]]; then
        PUBLISH_CMD="${PUBLISH_CMD} --description \"${BOX_DESCRIPTION}\""
    fi
    
    if [[ -n "${BOX_CATEGORY}" ]]; then
        PUBLISH_CMD="${PUBLISH_CMD} --category \"${BOX_CATEGORY}\""
    fi
    
    if [[ -n "${BOX_TAGS}" ]]; then
        PUBLISH_CMD="${PUBLISH_CMD} --tags \"${BOX_TAGS}\""
    fi
    
    if [[ -n "${BOXES_WTF_API_KEY}" ]]; then
        PUBLISH_CMD="${PUBLISH_CMD} --api-key \"${BOXES_WTF_API_KEY}\""
    fi
    
    # Make the publish script executable
    chmod +x "${SCRIPT_DIR}/scripts/publish.sh"
    
    # Execute the publish command
    eval $PUBLISH_CMD
    
    if [[ $? -ne 0 ]]; then
        echo "Failed to publish to boxes.wtf registry."
        echo "You can try publishing later using: ${SCRIPT_DIR}/scripts/publish.sh"
    fi
fi

# Create Dockerfile for registry if needed
if [[ "${PUBLISH_TO_REGISTRY}" == "true" ]]; then
    echo "Checking Dockerfile for registry publishing..."
    
    # Ensure docker directory exists
    mkdir -p "${DOCKER_DIR}"
    
    # Create Dockerfile if it doesn't exist
    if [[ ! -f "${DOCKER_DIR}/Dockerfile" ]]; then
        echo "Creating Dockerfile for registry publishing..."
        cat > "${DOCKER_DIR}/Dockerfile" << 'EOF'
FROM kalilinux/kali-rolling:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV HEALTH_PORT=80

# Update system and install essential packages
RUN apt-get update && \
    apt-get install -y \
    openssh-server \
    metasploit-framework \
    nmap \
    curl \
    wget \
    python3-pip \
    python3 \
    git \
    bc \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure SSH
RUN mkdir -p /var/run/sshd && \
    echo 'root:kali' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Setup the data directory
RUN mkdir -p /data && \
    chmod 755 /data && \
    chown root:root /data

# Copy the scripts
COPY scripts/init.sh /scripts/init.sh
COPY health-check.sh /scripts/health-check.sh
COPY health-server.py /scripts/health-server.py
RUN chmod +x /scripts/init.sh /scripts/health-check.sh /scripts/health-server.py

# Create a welcome message
RUN echo ' ____\n\
|  _ \\ _ __ __ _  __ _  ___   ___  _ __\n\
| | | | __/ _` |/ _` |/ _ \\ / _ \\| \'_ \\\n\
| |_| | | | (_| | (_| | (_) | (_) | | | |\n\
|____/|_|  \\__,_|\\__, |\\___/ \\___/|_| |_|\n\
                 |___/\n\
\n\
Kali Linux Deployment Center\n\
\n\
Welcome to your Kali Linux instance!\n\
All tools are ready to use.\n\
\n\
For support, visit: https://github.com/yourusername/dragoon\n\
' > /etc/motd

# Create healthcheck directory
RUN mkdir -p /healthcheck

# Expose ports
EXPOSE 22 80

# Set the entrypoint to the init script
ENTRYPOINT ["/scripts/init.sh"]
EOF
    fi
    
    # Create init.sh script for the Dockerfile if it doesn't exist
    if [[ ! -f "${DOCKER_DIR}/init.sh" ]]; then
        echo "Creating initialization script for registry publishing..."
        mkdir -p "${DOCKER_DIR}"
        cat > "${DOCKER_DIR}/init.sh" << 'EOF'
#!/bin/bash

# Dragoon - Kali Linux Initialization Script for Dockerfile

set -e

echo "[+] Initializing Kali Linux..."

# Install additional tools if specified in the environment
if [[ -n "${ADDITIONAL_TOOLS}" ]]; then
    echo "[+] Installing additional tools: ${ADDITIONAL_TOOLS}"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y ${ADDITIONAL_TOOLS}
    apt-get clean
    rm -rf /var/lib/apt/lists/*
fi

# Start SSH service
echo "[+] Starting SSH service..."
service ssh start

# Start health check server
echo "[+] Starting health check server..."
python3 /scripts/health-server.py &
echo $! > /var/run/health-server.pid

echo "[+] Initialization complete!"
echo "[+] Services running:"
echo "    - SSH server on port 22"
echo "    - Health check server on port ${HEALTH_PORT:-80} (endpoint: /health)"

# Keep the container running
tail -f /dev/null
EOF
        chmod +x "${DOCKER_DIR}/init.sh"
    fi
    
    # Create health check script if it doesn't exist
    if [[ ! -f "${DOCKER_DIR}/health-check.sh" ]]; then
        echo "Creating health check script for registry publishing..."
        cat > "${DOCKER_DIR}/health-check.sh" << 'EOF'
#!/bin/bash

# Health check script for Kali Linux container
# This script is mounted at /scripts/health-check.sh and serves as a health check endpoint

# Check if services are running
SSH_STATUS=$(service ssh status | grep -c "running")
SYSTEM_LOAD=$(uptime | awk '{print $10}' | tr -d ',')
MEMORY_FREE=$(free -m | awk 'NR==2{print $4}')
DISK_FREE=$(df -h / | awk 'NR==2{print $4}' | tr -d 'G')

# Verify SSH is running
if [ "$SSH_STATUS" -lt 1 ]; then
  echo "HTTP/1.1 503 Service Unavailable"
  echo "Content-Type: application/json"
  echo ""
  echo '{"status":"error","message":"SSH service is not running"}'
  exit 1
fi

# Verify system load is acceptable
if (( $(echo "$SYSTEM_LOAD > 5.0" | bc -l) )); then
  echo "HTTP/1.1 503 Service Unavailable"
  echo "Content-Type: application/json"
  echo ""
  echo '{"status":"error","message":"System load is too high: '"$SYSTEM_LOAD"'"}'
  exit 1
fi

# Verify memory is sufficient
if [ "$MEMORY_FREE" -lt 100 ]; then
  echo "HTTP/1.1 503 Service Unavailable"
  echo "Content-Type: application/json"
  echo ""
  echo '{"status":"error","message":"Free memory too low: '"$MEMORY_FREE"'MB"}'
  exit 1
fi

# Verify disk space is sufficient
if (( $(echo "$DISK_FREE < 1.0" | bc -l) )); then
  echo "HTTP/1.1 503 Service Unavailable"
  echo "Content-Type: application/json"
  echo ""
  echo '{"status":"error","message":"Free disk space too low: '"$DISK_FREE"'GB"}'
  exit 1
fi

# Return healthy status
echo "HTTP/1.1 200 OK"
echo "Content-Type: application/json"
echo ""
echo '{"status":"ok","message":"All systems operational","details":{"ssh":"running","load":"'"$SYSTEM_LOAD"'","memory_free_mb":"'"$MEMORY_FREE"'","disk_free_gb":"'"$DISK_FREE"'"}}'
exit 0
EOF
        chmod +x "${DOCKER_DIR}/health-check.sh"
    fi
    
    # Create health server script if it doesn't exist
    if [[ ! -f "${DOCKER_DIR}/health-server.py" ]]; then
        echo "Creating health check server for registry publishing..."
        cat > "${DOCKER_DIR}/health-server.py" << 'EOF'
#!/usr/bin/env python3

import http.server
import socketserver
import subprocess
import os
import sys
import signal
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    stream=sys.stdout
)
logger = logging.getLogger('health-server')

# Default port for the health check server
PORT = 80
HEALTH_CHECK_SCRIPT = "/scripts/health-check.sh"

class HealthCheckHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            logger.info("Health check requested")
            self.execute_health_check()
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'{"status":"error","message":"Not found"}')

    def execute_health_check(self):
        try:
            if not os.path.isfile(HEALTH_CHECK_SCRIPT):
                logger.error(f"Health check script not found at {HEALTH_CHECK_SCRIPT}")
                self.send_response(500)
                self.end_headers()
                self.wfile.write(b'{"status":"error","message":"Health check script not found"}')
                return

            # Make sure the script is executable
            os.chmod(HEALTH_CHECK_SCRIPT, 0o755)
            
            # Execute the health check script
            result = subprocess.run(
                [HEALTH_CHECK_SCRIPT], 
                capture_output=True, 
                text=True
            )
            
            # Parse the output from the health check script
            output = result.stdout
            lines = output.strip().split('\n')
            
            # Get the status line and extract the status code
            status_line = lines[0]
            status_code = int(status_line.split(' ')[1])
            
            # Set the response status code based on the script output
            self.send_response(status_code)
            
            # Parse headers from the script output
            header_end_idx = 0
            for i, line in enumerate(lines[1:], 1):
                if not line.strip():
                    header_end_idx = i
                    break
                    
                if ':' in line:
                    key, value = line.split(':', 1)
                    self.send_header(key.strip(), value.strip())
            
            self.end_headers()
            
            # Send the body from the script output
            body = '\n'.join(lines[header_end_idx+1:])
            self.wfile.write(body.encode('utf-8'))
            
            logger.info(f"Health check completed with status code {status_code}")
        except Exception as e:
            logger.error(f"Error executing health check: {e}")
            self.send_response(500)
            self.end_headers()
            self.wfile.write(f'{{"status":"error","message":"Internal server error: {str(e)}"}}'.encode('utf-8'))

    def log_message(self, format, *args):
        # Override to use our logger instead
        logger.info("%s - - [%s] %s" % (self.client_address[0], self.log_date_time_string(), format % args))

def run_server():
    try:
        port = int(os.environ.get('HEALTH_PORT', PORT))
        with socketserver.TCPServer(("", port), HealthCheckHandler) as httpd:
            logger.info(f"Health check server started on port {port}")
            httpd.serve_forever()
    except KeyboardInterrupt:
        logger.info("Server stopped by keyboard interrupt")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Error starting server: {e}")
        sys.exit(1)

def signal_handler(sig, frame):
    logger.info("Received termination signal, shutting down...")
    sys.exit(0)

if __name__ == "__main__":
    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Run the server
    run_server()
EOF
        chmod +x "${DOCKER_DIR}/health-server.py"
    fi
    
    # Ensure boxes.config.yaml exists in the root
    if [[ ! -f "${SCRIPT_DIR}/boxes.config.yaml" ]]; then
        echo "Creating boxes.config.yaml file in the repository root..."
        cat > "${SCRIPT_DIR}/boxes.config.yaml" << EOF
# Dragoon - boxes.wtf Registry Configuration

metadata:
  name: "dragoon-kali"
  version: "1.0.0"
  description: "Kali Linux environment powered by Dragoon for security testing and penetration testing"
  category: "security-tools"
  tags: ["kali", "security", "penetration-testing", "hacking", "cybersecurity"]
  
container:
  dockerfile: "./docker/Dockerfile"
  resources:
    cpu: "1"
    memory: "1Gi"
    storage: "10Gi"
  environment:
    KALI_VERSION: "latest"
    ADDITIONAL_TOOLS: "aircrack-ng dirb sqlmap wireshark"
    ENABLE_GUI: "false"
  build:
    commands:
      - "chmod +x /scripts/init.sh /scripts/health-check.sh /scripts/health-server.py"
    
networking:
  ports:
    - name: "ssh"
      port: 22
      protocol: "TCP"
      public: true
      load_balancer:
        enabled: true
        algorithm: "round_robin"
    - name: "http"
      port: 80
      protocol: "HTTP"
      public: false
      
  health:
    path: "/health"
    port: 80
    interval: "30s"
    timeout: "5s"
    retries: 3
    
deployment:
  replicas:
    min: 1
    max: 3
    target_cpu: 70
  strategy: "rolling"
  rolling:
    max_unavailable: 1
    max_surge: 1
    
security:
  user:
    run_as_non_root: false
  
  vulnerability_scanning:
    enabled: true
    severity_threshold: "high"
EOF
    fi
fi

exit 0