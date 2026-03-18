# MVP Scope

## Goal

Deliver a phone-first native client that makes existing OpenClaw Gateway chat practical without a browser.

## In scope

### Connectivity

- Gateway URL management
- OS-backed encrypted local persistence for connection settings
- token / password bootstrap
- device pairing flow
- reconnect and basic connection state reporting

### Chat

- load history via `chat.history`
- send text via `chat.send`
- abort via `chat.abort`
- render streaming assistant output
- render tool call activity from Gateway events
- basic slash-command parity where client-side support is practical

### Sessions

- switch between existing sessions
- create client-defined sessions through new `sessionKey` values
- preserve per-session drafts and local titles

### Session controls

- model selection
- thinking level
- fast mode
- verbose mode

### Media

- image sending

### UI

- phone-first layout
- adaptive handling for different DPI classes and narrow screens

## Out of scope

- Gateway feature development
- archive restore support
- deep config editing
- full dashboard parity on day one
- watch-first UX

## Success criteria

PocketClaw MVP is successful if a user can:

1. connect to an existing Gateway
2. pair once on a new device
3. switch sessions
4. create a new client-defined session
5. chat reliably with streaming output
6. stop a running response
7. send an image
8. adjust basic session behavior without opening the browser
