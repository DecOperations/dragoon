# Dragoon - Kali Linux Deployment Center User Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Quick Start](#quick-start)
4. [Configuration](#configuration)
5. [Advanced Usage](#advanced-usage)
6. [Accessing Your Kali Instance](#accessing-your-kali-instance)
7. [Customizing Your Environment](#customizing-your-environment)
8. [Publishing to boxes.wtf Registry](#publishing-to-boxeswtf-registry)
9. [Troubleshooting](#troubleshooting)

## Introduction

Dragoon is a deployment center tool that allows you to quickly set up and run the latest Kali Linux distribution on any compatible system. With Dragoon, you can easily deploy Kali Linux environments for penetration testing, security research, or learning purposes.

## Installation

### Prerequisites

- A Linux, macOS, or Windows (with WSL) system
- Basic knowledge of command-line interfaces
- Internet connection for downloading the Kali Linux image

### Automatic Installation

Run the provided setup script to automatically install all dependencies:

```bash
./setup.sh
```

This script will detect your operating system and install Docker and Docker Compose accordingly.

### Manual Installation

If the automatic installation fails, you can manually install the required components:

1. Install Docker: [Docker Installation Guide](https://docs.docker.com/get-docker/)
2. Install Docker Compose: [Docker Compose Installation Guide](https://docs.docker.com/compose/install/)
3. Ensure your user is added to the docker group: `sudo usermod -aG docker $USER`

## Quick Start

Once you have installed the prerequisites, you can deploy a Kali Linux instance with the default configuration:

```bash
./deploy.sh
```

This will:

1. Pull the latest Kali Linux Docker image
2. Create a container with SSH access enabled
3. Install essential tools and utilities
4. Set up a persistent data volume for your files

After deployment, you can access your Kali instance via SSH:

```bash
ssh -p 2222 root@localhost
```

The default password is `kali`. It is strongly recommended to change this password after your first login.

## Configuration

### Default Configuration

The default configuration is stored in `config/default.conf`. You can modify this file to change the default settings.

### Command-line Options

The `deploy.sh` script accepts several command-line options:

- `-h, --help`: Show help message
- `-v, --version`: Specify Kali version (default: latest)
- `-n, --name`: Container name (default: dragoon-kali)
- `-p, --port`: Host port mapping for SSH (default: 2222)
- `-g, --gui`: Enable GUI mode
- `-c, --config`: Specify a custom config file
- `-d, --data-dir`: Specify a custom data directory
- `-t, --tools`: Specify additional tools to install (space-separated list in quotes)

Examples:

```bash
# Deploy a specific Kali version with custom port
./deploy.sh --version 2023.1 --port 8022

# Deploy with GUI support
./deploy.sh --gui

# Deploy with custom tools
./deploy.sh --tools "aircrack-ng dirb sqlmap wireshark"

# Use a custom configuration file
./deploy.sh --config my-custom.conf
```

### Custom Configuration Files

You can create custom configuration files in the `config/` directory. A configuration file should contain the following parameters:

```bash
# Kali version (latest, 2023.1, etc.)
KALI_VERSION="latest"

# Container name
CONTAINER_NAME="dragoon-kali"

# Port mapping for SSH (host:guest)
HOST_PORT="2222"
GUEST_PORT="22"

# Data directory for persistent storage
DATA_DIR="/path/to/custom/data/dir"

# Enable GUI mode (true/false)
ENABLE_GUI="false"

# Additional tools to install (space-separated)
ADDITIONAL_TOOLS="aircrack-ng dirb sqlmap wireshark"

# Network configuration
NETWORK_MODE="host"  # or leave empty
NETWORK_NAME="custom-network"  # or leave empty
```

## Advanced Usage

### Using GUI Mode

To use Kali Linux with a graphical interface, deploy with the `--gui` flag:

```bash
./deploy.sh --gui
```

On Linux, you need to allow X11 forwarding:

```bash
xhost +local:docker
```

### Custom Network Configuration

To use a specific network mode or custom Docker network:

```bash
# Host network mode
./deploy.sh --config custom.conf  # with NETWORK_MODE="host" in the config

# Custom network
docker network create my-custom-network
./deploy.sh --config custom.conf  # with NETWORK_NAME="my-custom-network" in the config
```

### Installing Additional Tools

You can install additional tools by specifying them in the configuration file or using the `--tools` option:

```bash
./deploy.sh --tools "aircrack-ng dirb sqlmap wireshark burpsuite"
```

## Accessing Your Kali Instance

There are multiple ways to access your Kali Linux instance:

### SSH Access

```bash
ssh -p 2222 root@localhost  # replace 2222 with your custom port if modified
```

Default credentials: `root/kali`

### Docker Exec

```bash
docker exec -it dragoon-kali /bin/bash  # replace dragoon-kali with your container name if modified
```

### GUI Access (if enabled)

When GUI mode is enabled and properly configured, X11 applications will display on your host machine.

## Customizing Your Environment

### Persistent Data Storage

All data saved in the `/data` directory within the container will be preserved across container restarts and rebuilds. This directory is mounted from your host system at the location specified by `DATA_DIR` in your configuration.

### Custom Initialization

You can modify the `scripts/init.sh` script to customize the initialization process, such as installing additional software or configuring system settings.

## Publishing to boxes.wtf Registry

Dragoon now supports publishing your configured Kali Linux environment to the boxes.wtf registry, allowing you to share your customized environments with others or deploy them across multiple systems.

### The boxes.config.yaml File

The main configuration file for boxes.wtf registry integration is `boxes.config.yaml`, located in the repository root. This file follows the official boxes.wtf specification and contains all the configuration needed for the registry:

```yaml
# Dragoon - boxes.wtf Registry Configuration

metadata:
  name: "dragoon-kali"
  version: "1.0.0"
  description: "Kali Linux environment powered by Dragoon"
  category: "security-tools"
  tags: ["kali", "security", "penetration-testing"]

container:
  dockerfile: "./docker/Dockerfile"
  resources:
    cpu: "1"
    memory: "1Gi"
    storage: "10Gi"
  environment:
    KALI_VERSION: "latest"
    ADDITIONAL_TOOLS: "aircrack-ng dirb sqlmap wireshark"

networking:
  ports:
    - name: "ssh"
      port: 22
      protocol: "TCP"
      public: true
  health:
    path: "/health"
    port: 80
    interval: "30s"
    timeout: "5s"
    retries: 3
```

You can modify this file directly if you need fine-grained control over the registry configuration. For most use cases, the default configuration is sufficient and will be automatically updated with your values during deployment.

### Registry Configuration

Edit `config/default.conf` to include your registry settings:

```bash
# boxes.wtf registry settings
# API key for boxes.wtf registry
BOXES_WTF_API_KEY="your-api-key-here"
# OR use a file containing the API key
BOXES_WTF_API_KEY_FILE="/path/to/api-key-file"

# Box information
BOX_NAME="My Kali Environment"
BOX_VERSION="1.0.0"
BOX_DESCRIPTION="Customized Kali Linux environment with security tools"
BOX_CATEGORY="security-tools"
BOX_TAGS="kali,security,penetration-testing"
```

### Publishing During Deployment

To publish your environment to the registry during deployment:

```bash
./deploy.sh --publish --api-key "your-api-key"
```

You can also override the box information during deployment:

```bash
./deploy.sh --publish --box-name "My Custom Kali" --box-version "1.2.0" --api-key "your-api-key"
```

### Publishing an Existing Deployment

To publish an existing deployment:

```bash
./scripts/publish.sh --name "My Kali Box" --api-key "your-api-key"
```

To use the full template configuration from `config/boxes-template.yaml`:

```bash
./scripts/publish.sh --name "My Kali Box" --api-key "your-api-key" --template
```

Available options for the publish script:

- `--name`: Name for the box in the registry
- `--version`: Version for the box (default: 1.0.0)
- `--description`: Description for the box
- `--category`: Category for the box (default: security-tools)
- `--tags`: Comma-separated tags for the box
- `--api-key`: API key for the boxes.wtf registry
- `--template`: Use the full template configuration (more advanced settings)

### Health Checks and Advanced Features

The registry integration includes a health check endpoint at `/health` on port 80, which provides status information about your container:

- SSH service status
- System load
- Available memory
- Available disk space

This health check is automatically started when the container runs in the boxes.wtf environment.

### Customizing the Dockerfile for Registry

When publishing to the registry, Dragoon uses a special Dockerfile located at `docker/Dockerfile`. This file defines the container image that will be uploaded to the boxes.wtf registry.

You can customize this Dockerfile to include additional tools, configurations, or optimizations for your published boxes:

```bash
# Default location
docker/Dockerfile
```

The default Dockerfile includes:

1. Base Kali Linux image
2. Essential security tools
3. SSH server configuration
4. Data directory setup
5. Health check implementation
6. Initialization script

If you modify the Dockerfile, those changes will be included in all future registry publications.

### Accessing Published Boxes

After publishing, your box will be available at:

```
https://boxes.wtf/box/<box-id>
```

The box ID is generated based on the name you provided (with spaces replaced by hyphens and lowercase).

## Troubleshooting

### Common Issues

1. **Docker permission denied:**

   - Ensure your user is in the docker group: `sudo usermod -aG docker $USER`
   - Log out and log back in for the changes to take effect

2. **Port already in use:**

   - Change the port using the `--port` option: `./deploy.sh --port 8022`

3. **GUI applications don't display:**

   - Ensure X11 forwarding is enabled: `xhost +local:docker`
   - Check if the DISPLAY environment variable is set correctly

4. **Cannot connect via SSH:**

   - Verify the container is running: `docker ps`
   - Check if SSH service is running: `docker exec -it dragoon-kali service ssh status`

5. **Registry publishing fails:**
   - Ensure your API key is correct
   - Check your internet connection
   - Verify that the boxes.wtf API is accessible
   - Check if your Dockerfile contains any syntax errors

### Getting Help

If you encounter any issues not covered in this guide, please open an issue on the GitHub repository or contact the maintainers for assistance.
