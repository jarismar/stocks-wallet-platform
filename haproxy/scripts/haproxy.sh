#!/bin/bash

# HAProxy Control Script
# Manages start/stop of HAProxy reverse proxy for local development

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/config/haproxy.cfg"
SSL_DIR="${PROJECT_ROOT}/ssl"
SSL_CERT="${SSL_DIR}/haproxy.pem"
PIDFILE="/tmp/haproxy.pid"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
print_error() {
    echo -e "${RED}✗ Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if HAProxy is installed
check_haproxy_installed() {
    if ! command -v haproxy &> /dev/null; then
        print_error "HAProxy is not installed. Please install it first:"
        echo "  macOS: brew install haproxy"
        echo "  Linux: sudo apt-get install haproxy (Ubuntu/Debian)"
        exit 1
    fi
}

# Check if SSL certificate exists
check_ssl_certificate() {
    if [[ ! -f "${SSL_CERT}" ]]; then
        print_error "SSL certificate not found at: ${SSL_CERT}"
        echo "Generate it using: $0 setup"
        exit 1
    fi
}

# Check if configuration file exists
check_config() {
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        print_error "HAProxy configuration not found at: ${CONFIG_FILE}"
        exit 1
    fi
}

# Generate self-signed SSL certificate
setup_ssl_certificate() {
    print_info "Generating self-signed SSL certificate..."
    
    mkdir -p "${SSL_DIR}"
    
    # Generate private key and certificate
    openssl req -x509 -newkey rsa:2048 -keyout "${SSL_CERT}" -out "${SSL_CERT}" \
        -days 365 -nodes \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=stocks-wallet-dev.jaristra.com" 2>/dev/null || {
        print_error "Failed to generate SSL certificate"
        exit 1
    }
    
    print_success "SSL certificate generated at: ${SSL_CERT}"
    echo "Certificate details:"
    openssl x509 -in "${SSL_CERT}" -text -noout | grep -E "Subject:|Not Before|Not After"
}

# Start HAProxy
start_haproxy() {
    check_haproxy_installed
    check_config
    check_ssl_certificate
    
    # Check if already running
    if [[ -f "${PIDFILE}" ]] && kill -0 "$(cat ${PIDFILE})" 2>/dev/null; then
        print_info "HAProxy is already running (PID: $(cat ${PIDFILE}))"
        return 0
    fi
    
    print_info "Starting HAProxy..."
    
    # Start HAProxy with configuration
    haproxy -f "${CONFIG_FILE}" -p "${PIDFILE}" || {
        print_error "Failed to start HAProxy"
        exit 1
    }
    
    sleep 1
    
    if [[ -f "${PIDFILE}" ]] && kill -0 "$(cat ${PIDFILE})" 2>/dev/null; then
        print_success "HAProxy started successfully (PID: $(cat ${PIDFILE}))"
        print_info "Listening on:"
        echo "  HTTPS: https://stocks-wallet-dev.jaristra.com:443"
    else
        print_error "HAProxy failed to start. Check configuration."
        exit 1
    fi
}

# Stop HAProxy
stop_haproxy() {
    if [[ ! -f "${PIDFILE}" ]]; then
        print_info "HAProxy is not running"
        return 0
    fi
    
    local pid=$(cat "${PIDFILE}")
    
    if ! kill -0 "${pid}" 2>/dev/null; then
        print_info "HAProxy is not running (stale PID file)"
        rm -f "${PIDFILE}"
        return 0
    fi
    
    print_info "Stopping HAProxy (PID: ${pid})..."
    
    kill "${pid}" || {
        print_error "Failed to stop HAProxy"
        exit 1
    }
    
    # Wait for graceful shutdown
    local count=0
    while kill -0 "${pid}" 2>/dev/null && [[ ${count} -lt 10 ]]; do
        sleep 0.5
        ((count++))
    done
    
    # Force kill if necessary
    if kill -0 "${pid}" 2>/dev/null; then
        kill -9 "${pid}" || true
    fi
    
    rm -f "${PIDFILE}"
    print_success "HAProxy stopped"
}

# Show status
show_status() {
    if [[ -f "${PIDFILE}" ]] && kill -0 "$(cat ${PIDFILE})" 2>/dev/null; then
        local pid=$(cat "${PIDFILE}")
        print_success "HAProxy is running (PID: ${pid})"
        echo ""
        echo "Service endpoints:"
        echo "  Frontend: https://stocks-wallet-dev.jaristra.com"
        echo ""
        echo "Backend routes:"
        echo "  /sw/public/* → 0.0.0.0:3000"
        echo "  /sw/auth/*  → 0.0.0.0:4000"
        echo "  /sw/api/*   → 0.0.0.0:4001"
        echo "  /sw/*       → 0.0.0.0:3001"
        echo "  Other paths → 404"
    else
        print_info "HAProxy is not running"
    fi
}

# Show usage
show_usage() {
    cat << EOF
HAProxy Control Script

Usage: $0 [command]

Commands:
    start       Start HAProxy reverse proxy
    stop        Stop HAProxy reverse proxy
    restart     Restart HAProxy reverse proxy
    status      Show HAProxy status
    setup       Generate SSL certificate for local development
    help        Show this help message

Examples:
    # Initial setup (one-time)
    $0 setup

    # Start the service
    $0 start

    # Check status
    $0 status

    # Stop the service
    $0 stop

Environment:
    Config file: ${CONFIG_FILE}
    SSL certificate: ${SSL_CERT}
    PID file: ${PIDFILE}

EOF
}

# Main command handler
main() {
    local command="${1:-help}"
    
    case "${command}" in
        start)
            start_haproxy
            ;;
        stop)
            stop_haproxy
            ;;
        restart)
            stop_haproxy
            start_haproxy
            ;;
        status)
            show_status
            ;;
        setup)
            setup_ssl_certificate
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: ${command}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
