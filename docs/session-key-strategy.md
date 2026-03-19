# Session Key Strategy

PocketClaw uses client-controlled `sessionKey` values to create and switch conversations.

## Why

This avoids dependence on new Gateway-side session creation APIs.

## Approach

- generate predictable client-side keys
- persist local session metadata on device
- allow quick switching between active conversations
- keep the strategy compatible with current Gateway semantics
