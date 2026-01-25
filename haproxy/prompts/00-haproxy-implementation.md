# Task: Implement HAProxy reverse proxy with bash control script

Create a complete HAProxy setup for local development with HTTPS termination and intelligent backend routing. This includes a HAProxy configuration file with path-based routing rules, SSL/TLS certificate handling for `stocks-wallet-dev.jaristra.com`, and a bash script to manage the service lifecycle.

- Implement an HAProxy bash script that allows to start and stop the service
- This will be used for local development
- Needs to support https on port 443
- Needs to terminate https and forward the http request to the desired backend
- The Haproxy will handle all requests from the hostname `stocks-wallet-dev.jaristra.com` 
- This is the list of backends
  - any route with the path pattern `/sw/public/*` should be forwared to 0.0.0.0:3000
  - any route with the path pattern `/sw/auth/*` should be forwarded to 0.0.0.0:4000
  - any route with the path pattern `/sw/api/*` should be forwarded to 0.0.0.0:4001
  - any route with the path pattern `/sw/*` should be forwared to 0.0.0.0:3001
  - any other route should return 404

## Key Requirements

- Hostname: `stocks-wallet-dev.jaristra.com`
- HTTPS on port 443 with termination
- Bash script to start/stop the service
- Path-based backend routing

## Workspace Structure

```
haproxy/
├── README.md (existing)
├── prompts/ (existing)
│   └── 00-haproxy-implementation.md (existing)
├── config/
│   └── haproxy.cfg (HAProxy configuration file)
├── scripts/
│   ├── haproxy.sh (start/stop script)
│   └── setup.sh (optional: one-time setup)
└── ssl/ (SSL certificates - create during setup)
    └── haproxy.pem (combined cert + key)
```

## Backend Routing Rules

- `/sw/public/*` → `0.0.0.0:3000`
- `/sw/auth/*` → `0.0.0.0:4000`
- `/sw/api/*` → `0.0.0.0:4001`
- `/sw/*` → `0.0.0.0:3001`
- All other routes → 404

## Steps
1. Create `config/haproxy.cfg` with frontend and backend definitions matching the routing rules (4 backends + 404 fallback).
  - Use prefix match for patterns like `/sw/*` patterns since that's most maintainable and efficient
2. Create `haproxy.sh` bash script with start and stop commands to manage the HAProxy process.
3. Set up SSL/TLS support by creating, add the cert file to .gitignore and documenting certificate generation and requirements (self-signed cert generation or import into keychan).
4. Update README.md with quick start instructions, ssl certificate creation, port mappings, and backend service requirements.
   - Document how to generate local self-signed certificate
