#!/bin/bash

# Dragoon - Environment Setup Script
# This script installs Docker and Docker Compose on different platforms

set -e

echo "=== Dragoon - Environment Setup ==="
echo "This script will install Docker and Docker Compose on your system."

# Check OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="linux"
    # Check Linux distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo "Could not determine Linux distribution"
        exit 1
    fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
else
    echo "Unsupported operating system: $OSTYPE"
    echo "Please install Docker and Docker Compose manually."
    exit 1
fi

# Install Docker and Docker Compose based on OS type
if [[ "$OS_TYPE" == "linux" ]]; then
    echo "Installing Docker on Linux ($DISTRO)..."
    
    case $DISTRO in
        ubuntu|debian|linuxmint)
            # Update package list
            sudo apt update
            
            # Install required packages
            sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg
            
            # Add Docker GPG key
            curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # Add Docker repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$DISTRO $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Update package list again
            sudo apt update
            
            # Install Docker
            sudo apt install -y docker-ce docker-ce-cli containerd.io
            
            # Add user to docker group
            sudo usermod -aG docker $USER
            
            echo "Docker installed successfully!"
        ;;
        
        fedora|centos|rhel)
            # Install required packages
            sudo dnf -y install dnf-plugins-core
            
            # Add Docker repository
            sudo dnf config-manager --add-repo https://download.docker.com/linux/$DISTRO/docker-ce.repo
            
            # Install Docker
            sudo dnf -y install docker-ce docker-ce-cli containerd.io
            
            # Start and enable Docker service
            sudo systemctl start docker
            sudo systemctl enable docker
            
            # Add user to docker group
            sudo usermod -aG docker $USER
            
            echo "Docker installed successfully!"
        ;;
        
        arch|manjaro)
            # Install Docker
            sudo pacman -Sy --noconfirm docker
            
            # Start and enable Docker service
            sudo systemctl start docker
            sudo systemctl enable docker
            
            # Add user to docker group
            sudo usermod -aG docker $USER
            
            echo "Docker installed successfully!"
        ;;
        
        *)
            echo "Unsupported Linux distribution: $DISTRO"
            echo "Please install Docker manually."
            exit 1
        ;;
    esac
    
    # Install Docker Compose
    echo "Installing Docker Compose..."
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    echo "Docker Compose installed successfully!"
    
    elif [[ "$OS_TYPE" == "macos" ]]; then
    echo "Installing Docker on macOS..."
    
    # Check if brew is installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install Docker Desktop
    brew install --cask docker
    
    # Start Docker Desktop
    open /Applications/Docker.app
    
    echo "Docker Desktop installed successfully!"
    echo "Please start Docker Desktop and follow the prompts to complete the setup."
fi

echo ""
echo "Setup complete! Please log out and log back in to apply group changes."
echo "You can now run ./deploy.sh to deploy your Kali Linux environment."

exit 0