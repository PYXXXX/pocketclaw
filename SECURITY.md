# Security Policy

PocketClaw is still an **active prototype**.
This file explains the current security reporting expectations for the repository as it exists today.

## Supported versions

PocketClaw does not currently maintain multiple supported release lines.
In practice, security fixes should be considered against the latest repository state on `main` and the newest tagged release when one exists.

## What to report

Please report issues such as:

- accidental exposure of secrets or credentials
- unsafe handling of device tokens, passwords, or local credential storage
- security-sensitive flaws in connect, auth, pairing, or session flows
- workflow, release, or repository behavior that could expose private data

## How to report today

This repository does **not yet advertise a dedicated private security reporting channel**.

Until a private path is documented, please follow these rules:

1. **Do not post secrets** in public issues or pull requests.
2. **Do not post live tokens, passwords, private endpoints, internal hostnames, or private logs.**
3. If the issue can be described safely in sanitized form, open a public issue with only the minimum necessary detail.
4. If the issue cannot be described safely without exposing sensitive material, do **not** publish the details in a public issue.

## Public issue guidance

If you open a public issue for a security-relevant problem:

- keep the report minimal and sanitized
- focus on affected area, impact, and safe reproduction boundaries
- avoid copy-pasting raw credentials, environment files, or private infrastructure details

A good public report usually names the affected area, for example:

- `pocketclaw/app/pocketclaw_app`
- `pocketclaw/packages/gateway_adapter`
- `.github/workflows/`
- credential or token handling in documented flows

## Scope notes

PocketClaw is intentionally scoped as a **mobile-first OpenClaw client**.
Please do not assume that a valid security report automatically implies:

- adding a new backend service
- inventing new Gateway protocol behavior
- broad architecture rewrites unrelated to the actual flaw

## Disclosure expectations

Because the project is still evolving quickly:

- fixes may land first on the latest active branch state
- documentation may be updated alongside the fix when needed
- supported-version guarantees are conservative until the release model stabilizes
