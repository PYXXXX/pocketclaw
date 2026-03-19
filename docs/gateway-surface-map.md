# Gateway Surface Map

PocketClaw wraps the currently relevant Gateway surface behind an internal adapter.

## Current focus areas

- `chat.history`
- `chat.send`
- `chat.abort`
- `sessions.patch`
- model/session related listing and selection flows
- identity/auth related bootstrap calls

## Goal

Keep raw payload handling out of the UI layer and centralize compatibility decisions.
