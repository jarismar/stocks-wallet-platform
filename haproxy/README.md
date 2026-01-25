# Stocks Wallet HAProxy Module

HAProxy reverse proxy for local development with HTTPS termination and intelligent path-based routing.

## Overview

![Database](docs/arch_haproxy_rev_proxy.png)

This HAProxy setup provides:
- **HTTPS termination** on port 443 with TLS/SSL support
- **Path-based routing** to multiple backend services
- **Self-signed certificate** generation for local development
- **Simple bash control script** to start/stop the service

## Quick Start

### Prerequisites

- HAProxy installed (`brew install haproxy` on macOS)
- OpenSSL installed (usually included with macOS/Linux)
- Backend services running on ports 3000, 3001, 4000, and 4001

### Initial Setup

1. **Run the setup script (one-time):**
```bash
./scripts/setup.sh
```
   
This will:
- Verify HAProxy installation
- Generate a self-signed SSL certificate
- Configure your `/etc/hosts` file with the development domain

### Start the Service

```bash
./scripts/haproxy.sh start
```

Expected output:
```
ℹ Starting HAProxy...
✓ HAProxy started successfully (PID: 12345)
ℹ Listening on:
  HTTPS: https://stocks-wallet-dev.jaristra.com:443
```

### Check Status

```bash
./scripts/haproxy.sh status
```

### Stop the Service

```bash
./scripts/haproxy.sh stop
```

## Configuration

### Service Endpoints

| Path Pattern | Backend Port | Service |
|---|---|---|
| `/sw/public/*` | 3000 | Public Frontend |
| `/sw/auth/*` | 4000 | Authentication Service |
| `/sw/api/*` | 4001 | API Service |
| `/sw/*` | 3001 | Main Application |
| All other paths | - | 404 Response |

### Hostname

- **Development domain:** `stocks-wallet-dev.jaristra.com`
- **Access URL:** `https://stocks-wallet-dev.jaristra.com`

The hostname is automatically added to your `/etc/hosts` file during setup.

## SSL/TLS Certificate

### Self-Signed Certificate

The setup script generates a self-signed certificate valid for 365 days:

```bash
./scripts/haproxy.sh setup
```

**Location:** `ssl/haproxy.pem`

### Manual Certificate Generation

If you need to regenerate the certificate:

```bash
openssl req -x509 -newkey rsa:2048 -keyout ssl/haproxy.pem -out ssl/haproxy.pem \
  -days 365 -nodes \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=stocks-wallet-dev.jaristra.com"
```

### Certificate in Browser/System

Since the certificate is self-signed, you'll see security warnings in your browser.

**Option 1: Add to macOS Keychain**
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain \
  haproxy/ssl/haproxy.pem
```

**Option 2: Accept warning in your browser**
- Chrome: Click "Proceed to stocks-wallet-dev.jaristra.com (unsafe)"
- Firefox: Click "Add Exception"
- Safari: Choose to trust the certificate when prompted

## Troubleshooting

### HAProxy won't start

**Error:** "Address already in use"
```bash
# Check what's using port 443
lsof -i :443

# Kill the process if needed
kill -9 <PID>
```

**Error:** "SSL certificate not found"
```bash
# Generate the certificate
./scripts/haproxy.sh setup
```

### Backend connection issues

Check that your backend services are running:
```bash
# Check if ports are listening
lsof -i :3000
lsof -i :3001
lsof -i :4000
lsof -i :4001
```

### Certificate warnings in browser

This is expected with self-signed certificates. See "SSL/TLS Certificate" section above for solutions.

### View HAProxy logs

HAProxy outputs logs to stdout. If running in background, check the system logs or redirect output to a file:

```bash
# Modify haproxy.sh to add:
# haproxy -f "${CONFIG_FILE}" -p "${PIDFILE}" >> haproxy.log 2>&1 &
```

### Restart HAProxy

Useful when backend services change or configuration is updated:
```bash
./scripts/haproxy.sh restart
```

### Validate configuration without starting

```bash
haproxy -f config/haproxy.cfg -c
```

## References

- [HAProxy Official Documentation](https://www.haproxy.org/)
- [HAProxy Configuration Manual](https://cbonte.github.io/haproxy-dconv/)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
