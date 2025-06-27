# Dragoon - Kali Linux Deployment Center User Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Quick Start](#quick-start)
4. [Configuration](#configuration)
5. [Advanced Usage](#advanced-usage)
6. [Accessing Your Kali Instance](#accessing-your-kali-instance)
7. [Customizing Your Environment](#customizing-your-environment)
8. [Troubleshooting](#troubleshooting)

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

### Getting Help

If you encounter any issues not covered in this guide, please open an issue on the GitHub repository or contact the maintainers for assistance.
