#!/bin/bash

# Dragoon - boxes.wtf Registry Publishing Script

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="${PARENT_DIR}/config"
DEFAULT_CONFIG="${CONFIG_DIR}/default.conf"
DOCKER_DIR="${PARENT_DIR}/docker"
BUILD_DIR="${PARENT_DIR}/build"
TEMPLATE_CONFIG="${CONFIG_DIR}/boxes-template.yaml"

# Load default configuration
if [[ -f "${DEFAULT_CONFIG}" ]]; then
    source "${DEFAULT_CONFIG}"
else
    echo "Default configuration file not found."
    exit 1
fi

# Override with command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --name)
            BOX_NAME="$2"
            shift
            shift
        ;;
        --version)
            BOX_VERSION="$2"
            shift
            shift
        ;;
        --description)
            BOX_DESCRIPTION="$2"
            shift
            shift
        ;;
        --category)
            BOX_CATEGORY="$2"
            shift
            shift
        ;;
        --tags)
            BOX_TAGS="$2"
            shift
            shift
        ;;
        --api-key)
            BOXES_WTF_API_KEY="$2"
            shift
            shift
        ;;
        --template)
            USE_FULL_TEMPLATE="true"
            shift
        ;;
        *)
            echo "Unknown option: $1"
            exit 1
        ;;
    esac
done

# Ensure required variables are set
if [[ -z "${BOX_NAME}" ]]; then
    echo "Error: Box name is required"
    exit 1
fi

if [[ -z "${BOXES_WTF_API_KEY}" && -z "${BOXES_WTF_API_KEY_FILE}" ]]; then
    echo "Error: API key is required. Set BOXES_WTF_API_KEY or BOXES_WTF_API_KEY_FILE in config or provide --api-key"
    exit 1
fi

# Get API key from file if specified
if [[ -z "${BOXES_WTF_API_KEY}" && -n "${BOXES_WTF_API_KEY_FILE}" ]]; then
    if [[ -f "${BOXES_WTF_API_KEY_FILE}" ]]; then
        BOXES_WTF_API_KEY=$(cat "${BOXES_WTF_API_KEY_FILE}")
    else
        echo "Error: API key file not found: ${BOXES_WTF_API_KEY_FILE}"
        exit 1
    fi
fi

# Check if Dockerfile exists
if [[ ! -f "${DOCKER_DIR}/Dockerfile" ]]; then
    echo "Error: Dockerfile not found at ${DOCKER_DIR}/Dockerfile"
    exit 1
fi

# Check for health check files
if [[ ! -f "${DOCKER_DIR}/health-check.sh" ]]; then
    echo "Error: Health check script not found at ${DOCKER_DIR}/health-check.sh"
    exit 1
fi

if [[ ! -f "${DOCKER_DIR}/health-server.py" ]]; then
    echo "Error: Health check server not found at ${DOCKER_DIR}/health-server.py"
    exit 1
fi

# Create build directory if it doesn't exist
mkdir -p "${BUILD_DIR}"

# Copy necessary files to the build directory
echo "Preparing build directory..."
cp "${DOCKER_DIR}/Dockerfile" "${BUILD_DIR}/"
mkdir -p "${BUILD_DIR}/scripts"
cp "${DOCKER_DIR}/init.sh" "${BUILD_DIR}/scripts/"
cp "${DOCKER_DIR}/health-check.sh" "${BUILD_DIR}/"
cp "${DOCKER_DIR}/health-server.py" "${BUILD_DIR}/"
chmod +x "${BUILD_DIR}/scripts/init.sh"
chmod +x "${BUILD_DIR}/health-check.sh"
chmod +x "${BUILD_DIR}/health-server.py"

# Generate a Dockerfile with the specified Kali version
if [[ "${KALI_VERSION}" != "latest" ]]; then
    sed -i "s/FROM kalilinux\/kali-rolling:latest/FROM kalilinux\/kali-rolling:${KALI_VERSION}/" "${BUILD_DIR}/Dockerfile"
fi

# Prepare boxes.config.yaml file
echo "Generating boxes.config.yaml file..."

if [[ "${USE_FULL_TEMPLATE}" == "true" && -f "${TEMPLATE_CONFIG}" ]]; then
    echo "Using full template configuration..."
    cp "${TEMPLATE_CONFIG}" "${BUILD_DIR}/boxes.config.yaml"
    
    # Update template values
    sed -i "s/\"dragoon-kali\"/\"${BOX_NAME//\//\\/}\"/" "${BUILD_DIR}/boxes.config.yaml"
    sed -i "s/\"1\.0\.0\"/\"${BOX_VERSION:-1.0.0}\"/" "${BUILD_DIR}/boxes.config.yaml"
    sed -i "s/\"Kali Linux environment powered by Dragoon\"/\"${BOX_DESCRIPTION:-Kali Linux environment powered by Dragoon}\"/" "${BUILD_DIR}/boxes.config.yaml"
    sed -i "s/\"security-tools\"/\"${BOX_CATEGORY:-security-tools}\"/" "${BUILD_DIR}/boxes.config.yaml"
    
    # If tags are specified, update them
    if [[ -n "${BOX_TAGS}" ]]; then
        # Convert comma-separated list to array syntax
        FORMATTED_TAGS=$(echo "${BOX_TAGS}" | tr ',' '\n' | sed 's/^/  - "/' | sed 's/$/"/' | tr '\n' ' ')
        sed -i "s/\[\"kali\", \"security\", \"penetration-testing\"\]/${FORMATTED_TAGS}/" "${BUILD_DIR}/boxes.config.yaml"
    fi
else
    # Create a simpler boxes.config.yaml
    cat > "${BUILD_DIR}/boxes.config.yaml" << EOF
metadata:
  name: "${BOX_NAME}"
  version: "${BOX_VERSION:-1.0.0}"
  description: "${BOX_DESCRIPTION:-Kali Linux environment powered by Dragoon}"
  category: "${BOX_CATEGORY:-security-tools}"
  tags: [${BOX_TAGS:-"kali", "security", "penetration-testing"}]

container:
  dockerfile: "./Dockerfile"
  resources:
    cpu: "${CONTAINER_CPU:-1}"
    memory: "${CONTAINER_MEMORY:-1Gi}"
    storage: "${CONTAINER_STORAGE:-10Gi}"
  environment:
    KALI_VERSION: "${KALI_VERSION}"
    ADDITIONAL_TOOLS: "${ADDITIONAL_TOOLS}"
    ENABLE_GUI: "${ENABLE_GUI}"

networking:
  ports:
    - name: "ssh"
      port: ${GUEST_PORT}
      protocol: "TCP"
      public: true
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

security:
  user:
    run_as_non_root: false
EOF
fi

echo "boxes.config.yaml file created."
# Copy the generated config back to the parent directory for reference
cp "${BUILD_DIR}/boxes.config.yaml" "${PARENT_DIR}/"

# Validate the config
echo "Validating configuration..."
if ! command -v curl &> /dev/null; then
    echo "Error: curl is required for publishing"
    exit 1
fi

# Generate unique box identifier if not provided
if [[ -z "${BOX_ID}" ]]; then
    BOX_ID="${BOX_NAME// /-}-$(date +%s)"
    BOX_ID=$(echo "$BOX_ID" | tr '[:upper:]' '[:lower:]')
fi

echo "Publishing to boxes.wtf registry..."
echo "Box ID: ${BOX_ID}"
echo "Name: ${BOX_NAME}"
echo "Version: ${BOX_VERSION:-1.0.0}"

# Create tarball of the build directory
echo "Creating tarball of the build files..."
TAR_FILE="${BUILD_DIR}/dragoon-${BOX_ID}.tar.gz"
cd "${BUILD_DIR}" && tar -czf "${TAR_FILE}" Dockerfile scripts health-check.sh health-server.py boxes.config.yaml
cd "${PARENT_DIR}"

# Publish to boxes.wtf registry
echo "Uploading to boxes.wtf registry..."
PUBLISH_RESULT=$(curl -s -X POST \
    -H "Authorization: Bearer ${BOXES_WTF_API_KEY}" \
    -H "Content-Type: multipart/form-data" \
    -F "id=${BOX_ID}" \
    -F "name=${BOX_NAME}" \
    -F "version=${BOX_VERSION:-1.0.0}" \
    -F "build_archive=@${TAR_FILE}" \
"${BOXES_WTF_API_URL:-https://api.boxes.wtf}/publish")

# Check result
if [[ $? -eq 0 && $(echo "$PUBLISH_RESULT" | grep -c "success") -gt 0 ]]; then
    echo "✅ Successfully published to boxes.wtf registry!"
    echo "Your box is now available at: https://boxes.wtf/box/${BOX_ID}"
else
    echo "❌ Failed to publish to boxes.wtf registry"
    echo "Error: $PUBLISH_RESULT"
    exit 1
fi

# Clean up build directory
echo "Cleaning up build files..."
rm -rf "${BUILD_DIR}"