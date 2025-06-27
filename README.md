# Dragoon - Kali Linux Deployment Center

A deployment center tool for quickly provisioning and running the latest Kali Linux distribution.

## Overview

Dragoon allows you to deploy and run the latest Kali Linux distribution on any compatible system. It automates the process of fetching, configuring, and running Kali, making it simple to set up penetration testing environments.

## Features

- Automated Kali Linux deployment using Docker
- Customizable configuration and tool selection
- Support for GUI applications
- Persistent data storage
- SSH access for remote management
- Integration with boxes.wtf registry for easy sharing and reuse

## Requirements

- Docker
- Git
- Bash

## Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/dragoon.git
cd dragoon

# Run the deployment script
./deploy.sh

# To deploy and publish to boxes.wtf registry
./deploy.sh --publish --api-key "your-api-key"
```

## Components

- `deploy.sh`: Main deployment script
- `config/`: Configuration files for different deployment scenarios
- `scripts/`: Helper scripts for various deployment tasks
- `docker/`: Docker-related files for containerized deployment

## Registry Integration

Dragoon now supports publishing your environments to the boxes.wtf registry, allowing you to:

- Share your custom environments with others
- Deploy identical environments across multiple systems
- Create marketplace deployments

See the [User Guide](USER_GUIDE.md) for detailed instructions on publishing to the registry.

## License

[MIT License](LICENSE)
