# Next Steps

## Immediate engineering priorities

1. Define local connect-flow state and onboarding completion state
2. Shape a real onboarding and connect flow
3. Tighten Gateway compatibility against the official Android reference
4. Polish the mobile app shell and destination handoff
5. Add session title editing and other chat-first polish

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
- compact destination navigation
- chat timeline surface

## Release operations

- rely on GitHub Actions for validation
- rely on GitHub Actions for Android release artifacts
- keep local workflow lightweight unless a stronger machine is available
