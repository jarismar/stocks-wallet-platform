#!/bin/bash

# HAProxy Setup Script
# One-time setup for local development environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HAPROXY_SCRIPT="${SCRIPT_DIR}/haproxy.sh"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}HAProxy Local Development Setup${NC}"
echo "=================================="
echo ""

# Step 1: Check HAProxy installation
echo "Step 1: Checking HAProxy installation..."
if command -v haproxy &> /dev/null; then
    echo -e "${GREEN}✓ HAProxy is installed$(NC)"
    haproxy -v | head -n 1
else
    echo -e "${YELLOW}⚠ HAProxy is not installed${NC}"
    echo ""
    echo "Installation instructions:"
    echo "  macOS (with Homebrew):"
    echo "    brew install haproxy"
    echo ""
    echo "  Ubuntu/Debian:"
    echo "    sudo apt-get update"
    echo "    sudo apt-get install haproxy"
    echo ""
    echo "  Other systems: See https://www.haproxy.org/"
    exit 1
fi

echo ""

# Step 2: Check configuration file
echo "Step 2: Checking HAProxy configuration..."
CONFIG_FILE="${PROJECT_ROOT}/config/haproxy.cfg"
if [[ -f "${CONFIG_FILE}" ]]; then
    echo -e "${GREEN}✓ Configuration file found${NC}"
    echo "  Location: ${CONFIG_FILE}"
else
    echo -e "${YELLOW}⚠ Configuration file not found${NC}"
    echo "  Expected location: ${CONFIG_FILE}"
    exit 1
fi

echo ""

# Step 3: Generate SSL certificate
echo "Step 3: Setting up SSL certificate..."
SSL_DIR="${PROJECT_ROOT}/ssl"
SSL_CERT="${SSL_DIR}/haproxy.pem"

if [[ -f "${SSL_CERT}" ]]; then
    echo -e "${YELLOW}⚠ SSL certificate already exists${NC}"
    read -p "Do you want to regenerate it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping certificate regeneration"
        echo ""
    else
        "${HAPROXY_SCRIPT}" setup
        echo ""
    fi
else
    "${HAPROXY_SCRIPT}" setup
    echo ""
fi

# Step 4: Configure /etc/hosts
echo "Step 4: Checking /etc/hosts configuration..."
HOSTNAME="stocks-wallet-dev.jaristra.com"

if grep -q "${HOSTNAME}" /etc/hosts 2>/dev/null; then
    echo -e "${GREEN}✓ Hostname is already configured in /etc/hosts${NC}"
else
    echo -e "${YELLOW}⚠ Hostname is not configured in /etc/hosts${NC}"
    echo ""
    echo "To add it manually, run:"
    echo "  echo '127.0.0.1 ${HOSTNAME}' | sudo tee -a /etc/hosts"
    echo ""
    read -p "Add it now? (requires sudo) (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "127.0.0.1 ${HOSTNAME}" | sudo tee -a /etc/hosts > /dev/null
        echo -e "${GREEN}✓ Hostname added to /etc/hosts${NC}"
    fi
fi

echo ""

# Step 5: Summary
echo -e "${GREEN}Setup Complete!${NC}"
echo ""
echo "Quick start:"
echo "  1. Start HAProxy:  ./scripts/haproxy.sh start"
echo "  2. Check status:   ./scripts/haproxy.sh status"
echo "  3. Stop HAProxy:   ./scripts/haproxy.sh stop"
echo ""
echo "Backend services must be running on:"
echo "  - Port 3000: Public frontend"
echo "  - Port 4000: Authentication service"
echo "  - Port 4001: API service"
echo "  - Port 3001: Main application"
echo ""
echo "Access your application at:"
echo "  https://${HOSTNAME}"
echo ""
echo "Note: You may see SSL certificate warnings since it's self-signed."
echo "Add the certificate to your system keychain or browser to avoid warnings."
