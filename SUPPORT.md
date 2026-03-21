# Support

If you need help with PocketClaw, start with the lightest useful path first.

## 1. Read the key docs

For most questions, these are the fastest entry points:

- [`README.md`](./README.md) — project overview and current positioning
- [`docs/README.md`](./docs/README.md) — documentation map
- [`docs/compatibility.md`](./docs/compatibility.md) — compatibility boundaries with the current OpenClaw Gateway
- [`docs/mvp-scope.md`](./docs/mvp-scope.md) — what the current MVP is and is not trying to do
- [`docs/ci-cd.md`](./docs/ci-cd.md) — what GitHub Actions currently validates
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — how to propose changes that fit the repo

## 2. Choose the right issue type

If the docs did not answer your question, open an issue using the closest matching template:

- **Bug report** — for reproducible breakage in the app, packages, docs, or repository workflows
- **Docs or repo maintenance** — for README clarity, docs drift, naming cleanup, and repository-surface improvements
- **Feature proposal** — for focused ideas that still fit PocketClaw’s current scope

## 3. Include the right context

A useful support request usually includes:

- what you were trying to do
- what you expected to happen
- what happened instead
- which area is affected (`docs/`, `.github/`, `pocketclaw/app/`, `pocketclaw/packages/`, etc.)
- any relevant screenshots, logs, workflow links, or device/toolchain details

## Scope reminder

PocketClaw is intentionally narrow in scope.

Please do not assume by default that support requests imply:

- a new backend service
- new Gateway protocol behavior
- large architecture rewrites
- product directions outside the current mobile-first client focus

## When to use issues vs pull requests

- Open an **issue** when you found a problem, inconsistency, or focused proposal and want to discuss it first.
- Open a **pull request** when you already have a small, concrete change ready to review.

## Security

For sensitive security issues, avoid posting secrets, tokens, private endpoints, or internal credentials in public issues.

If the repository later adds a dedicated security reporting path, use that instead of a public bug report.
