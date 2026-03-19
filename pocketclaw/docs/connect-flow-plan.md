# Connect Flow Plan

## Objective

Move PocketClaw from a placeholder configuration card toward a real mobile connection flow that is compatible with today's OpenClaw Gateway behavior.

This plan is informed by the official OpenClaw Android app, but it remains scoped for PocketClaw's chat-first mobile MVP.

## Product goal

A user should be able to open PocketClaw on a phone and understand, with minimal friction:

1. how to point the app at a Gateway
2. how to authenticate or pair
3. whether reconnect will work next time
4. when they are ready to enter chat

## Core constraints

- no Gateway changes
- no custom backend
- no hidden storage hacks
- no assumption that setup-code semantics will expand
- keep the first working flow compatible with the existing Gateway surface

## Proposed structure

### Step 1 — Welcome

Purpose:

- explain what PocketClaw is
- set expectation that it connects to an existing Gateway
- direct the user into connection setup

### Step 2 — Choose connection method

Initial options:

- manual connect
- setup code (future-facing if available to the client path)

PocketClaw should treat manual connect as the baseline flow that must always work.

### Step 3 — Authentication / pairing

Depending on the Gateway and chosen method, the app may use:

- token
- password
- device-auth challenge signing
- cached device token after approval

The app should make these states understandable rather than exposing raw protocol details.

### Step 4 — Ready to chat

When the Gateway profile is known and the device can reconnect reliably, the app should transition into the normal chat shell.

## State model

PocketClaw should treat connection flow as explicit app state instead of just a set of text fields.

Suggested states:

- `welcome`
- `chooseMethod`
- `manualConfig`
- `authPending`
- `pairingPending`
- `ready`
- `error`

This is product state, not a replacement for the lower-level Gateway connection phases.

## Persistence expectations

### Secure storage

Keep in OS-backed secure storage:

- Gateway URL / token / password where applicable
- device identity
- device token

### Local non-secret storage

Keep in normal local persistence:

- last selected session
- local session registry
- per-session drafts
- onboarding completion state
- non-sensitive connect UI choices

## User-visible status surfaces

The connect flow should answer these questions clearly:

- which Gateway am I targeting?
- am I disconnected, connecting, paired, or blocked?
- do I need to approve this device elsewhere?
- is reconnect likely to work next time?

## What to borrow from the official Android app

Good reference areas:

- dedicated connect tab / connect surface
- explicit onboarding stages
- separation between secure auth state and ordinary local prefs
- clearer distinction between bootstrap credentials and reusable device auth

## What not to over-copy

PocketClaw should avoid pulling in the full node-runtime product scope just because the official Android app contains it.

For PocketClaw MVP, the connect flow only needs to serve the chat-first client journey.

## Implementation order

1. define a local connect-flow state model
2. split the current Gateway configuration card into a dedicated connection surface
3. add onboarding completion state
4. support clearer pairing-pending and reconnect-ready messaging
5. transition into the chat shell only after connection setup is in a usable state

## Done criteria for this phase

This phase is done when a first-time user can:

1. open PocketClaw
2. understand that it connects to an existing Gateway
3. complete manual connection setup
4. see whether pairing or approval is still required
5. return later and reconnect without re-entering everything
6. enter the chat UI without feeling like they are still inside a debug screen
