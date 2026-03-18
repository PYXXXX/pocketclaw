# Official Android App Reference Notes

## Purpose

This document captures what PocketClaw should learn from the official OpenClaw Android app without turning PocketClaw into a clone.

Reference target:

- `openclaw/openclaw/apps/android`

PocketClaw remains a separate client project with its own architecture and product direction.
The goal here is to reuse proven patterns where they align with PocketClaw's compatibility-first mobile scope.

## Why this matters

The official Android app is now a strong reference implementation for:

- Gateway onboarding
- connection and pairing flows
- local credential persistence
- device identity and device-token reuse
- chat streaming UX on a phone-sized client

This reduces guesswork for PocketClaw.

## Confirmed relevant signals

From `apps/android/README.md` and related source layout, the official Android app already treats the following as first-class concerns:

- encrypted persistence for gateway setup and auth state
- setup-code and manual connection flows
- onboarding-specific permission handling
- streaming chat support
- security hardening and safer defaults

This validates PocketClaw's current direction rather than replacing it.

## Files worth studying first

### Security and local state

- `app/src/main/java/ai/openclaw/app/SecurePrefs.kt`
- `app/src/main/java/ai/openclaw/app/gateway/DeviceIdentityStore.kt`
- `app/src/main/java/ai/openclaw/app/gateway/DeviceAuthStore.kt`
- `app/src/test/java/ai/openclaw/app/SecurePrefsTest.kt`

### Connection and Gateway behavior

- `app/src/main/java/ai/openclaw/app/gateway/GatewaySession.kt`
- `app/src/main/java/ai/openclaw/app/gateway/GatewayProtocol.kt`
- `app/src/main/java/ai/openclaw/app/ui/ConnectTabScreen.kt`
- `app/src/main/java/ai/openclaw/app/ui/GatewayConfigResolver.kt`
- `app/src/main/java/ai/openclaw/app/ui/OnboardingFlow.kt`

### Chat behavior and UI decomposition

- `app/src/main/java/ai/openclaw/app/chat/ChatController.kt`
- `app/src/main/java/ai/openclaw/app/ui/chat/ChatComposer.kt`
- `app/src/main/java/ai/openclaw/app/ui/chat/ChatMessageListCard.kt`
- `app/src/main/java/ai/openclaw/app/ui/chat/ChatSheetContent.kt`

## Direct takeaways for PocketClaw

### 1. Encrypted local persistence is mandatory

This is no longer a speculative improvement.
The official Android app already treats encrypted setup/auth persistence as baseline behavior.

Implication for PocketClaw:

- persist Gateway profile securely
- persist device identity securely
- persist device token securely
- keep non-sensitive local session metadata separate from secrets when practical

### 2. Device identity and device-token reuse belong in the first-wave architecture

The official app separates device identity from reusable auth token storage.
PocketClaw should keep the same conceptual split even if the implementation differs because of Flutter.

### 3. Onboarding and connect flow deserve explicit structure

The official app has a dedicated onboarding and connect surface instead of burying connection logic inside settings.
PocketClaw should follow that product lesson even if the UI is simpler in early builds.

### 4. PocketClaw should borrow behavior, not copy the whole product scope

The official Android app also serves as a node/device runtime and includes capabilities beyond PocketClaw's initial chat-first MVP.
PocketClaw should not let that broaden the MVP prematurely.

PocketClaw remains focused on:

- compatibility with the existing Gateway surface
- chat-first mobile usage
- client-side multi-session control via `sessionKey`
- lightweight mobile-friendly controls only where they clearly add value

## Current PocketClaw alignment

PocketClaw already aligns with the official Android app in these areas:

- compatibility-first design
- no Gateway changes required
- secure persistence for Gateway profile and auth material
- device identity and device-token persistence

PocketClaw still needs follow-up work in these areas:

- richer client-side session metadata beyond draft + title
- onboarding structure
- setup-code/manual-connect UX shaping
- stronger local validation and CI coverage once Flutter/Dart toolchain is available

## Borrow carefully

PocketClaw should copy patterns only when they match its constraints:

- yes: persistence model, auth boundaries, reconnect expectations, onboarding lessons
- maybe: specific field names and migration patterns
- no: wholesale duplication of node-runtime features into the chat MVP

## Next reference pass

The next detailed code-reading pass should focus on:

1. `SecurePrefs.kt`
2. `DeviceIdentityStore.kt`
3. `DeviceAuthStore.kt`
4. `ConnectTabScreen.kt`
5. `GatewaySession.kt`
6. `ChatController.kt`

That pass should produce a concrete PocketClaw implementation checklist rather than a general comparison memo.
