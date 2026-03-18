# Next Steps

## Immediate engineering priorities

1. Define Gateway handshake models
2. Define chat event and tool event models
3. Build a minimal Gateway client abstraction
4. Add session-key generation and local session registry
5. Replace the placeholder app home with a real app shell

## Suggested implementation order

### A. Transport

- request envelope
- response envelope
- event envelope
- connect challenge handling
- connect request shape

### B. Core domain

- session key utilities
- session registry
- chat timeline item model
- tool stream item model

### C. App shell

- home scaffold
- session switcher entry
- connection status surface
- placeholder chat timeline view

## Release operations

- rely on GitHub Actions for validation
- rely on GitHub Actions for Android release artifacts
- keep local workflow lightweight unless a stronger machine is available
