# Changelog

All notable repository-facing changes to PocketClaw should be documented in this file.

This project is still pre-1.0 and in active prototype mode, so entries may be grouped into practical maintenance slices instead of strict release-by-release detail.

## Unreleased

### Added

- contribution and collaboration entry points: `CONTRIBUTING.md`, PR template, issue templates, `SUPPORT.md`, `SECURITY.md`, and `CODE_OF_CONDUCT.md`
- repository-facing documentation indexes for `docs/` and `docs/zh-CN/`
- repository-facing CI/CD guide in `docs/ci-cd.md` and `docs/zh-CN/ci-cd.md`
- implementation-facing workspace guides in `pocketclaw/README.md` and `pocketclaw/README.zh-CN.md`

### Changed

- root `README.md` and `README.zh-CN.md` now more clearly describe the repository surface versus the `pocketclaw/` workspace
- broken Star History image embed was replaced with a stable GitHub stars badge plus a Star History link
- GitHub issue creation flow now routes contributors through docs, support, security, and conduct entry points
- root docs surface was cleaned up to remove unrelated deployment notes

## Release notes policy

- GitHub Releases may use auto-generated release notes from the workflow for tagged Android builds.
- This changelog is the curated human-readable summary of notable repository and release-facing changes.
- Minor wording-only edits do not always need their own changelog entry unless they change contributor expectations or project positioning.
