# Development Workflow

## Project style

PocketClaw is intentionally developed as a **fully vibe-coded** project.

That does not mean "unstructured".
It means the project leans into:

- AI-first scaffolding
- rapid iteration
- short feedback loops
- aggressive documentation of constraints
- compatibility validation against real Gateway behavior

## Workflow principles

### 1. Compatibility before abstraction

Prefer verifying current Gateway behavior over inventing idealized client/server contracts.

### 2. Ship the smallest useful surface

Prioritize the shortest path to a reliable phone-first chat client.

### 3. Keep raw Gateway handling isolated

Gateway payload parsing should live inside adapter modules rather than leak throughout the app.

### 4. Separate reusable core from UI

The project should evolve toward:

- transport layer
- auth / identity layer
- Gateway compatibility layer
- domain state layer
- UI layer

This is especially important for future wearable clients.

## Suggested implementation order

### Step 1

Document the Gateway surface and MVP scope.

### Step 2

Create the transport, auth, and compatibility foundations.

### Step 3

Implement a phone-first chat MVP.

### Step 4

Expand into selected control surfaces only where mobile value is clear.

## Repository writing policy

Public repository content should stay:

- objective
- bilingual when useful, with English primary
- owner / maintainer facing
- free of private-chat framing

## Long-term direction

If the core architecture remains clean, PocketClaw can later support:

- tablet-optimized layouts
- watch-oriented interaction models
- a future `WristClaw` client sharing the same core logic
