---
type: task
schema_version: '3'
status: open/ready
created: '2026-05-26'
impact: medium
complexity: small
tags:
- ci
- github-actions
related: []
---
# Unify the pinned pnpm version across all CI workflows

## Goal

The three GitHub Actions workflows pin three different (and all stale) pnpm
versions, and none match the version the project declares for itself.
`ci.yml` installs pnpm `10.24.0`; `build-check.yml` and `release.yml` install
`10.28.2`; the root `package.json` declares `pnpm: ^10.33.4`. A pnpm version
that differs from local development can resolve a different dependency tree or
honor different lockfile semantics, so CI can pass (or fail) for reasons that
don't reproduce locally. This task makes the pnpm version a single, consistent
value everywhere it is installed.

## Today

| Location | Role today |
|---|---|
| `.github/workflows/ci.yml` | `pnpm/action-setup@v4` pinned to `version: 10.24.0` |
| `.github/workflows/build-check.yml` | `pnpm/action-setup@v4` pinned to `version: 10.28.2` |
| `.github/workflows/release.yml` | `pnpm/action-setup@v4` pinned to `version: 10.28.2` |
| `package.json` | declares `"pnpm": "^10.33.4"` under `dependencies` |

## Proposed

All three workflows install the same pnpm version, and that version is
consistent with what `package.json` declares. Two viable shapes (decision for
review — see Approach):

- **A (simple pin):** set `version:` to one shared literal (e.g. `10.33.4`) in
  all three `pnpm/action-setup@v4` steps.
- **B (single source of truth):** add a `packageManager` field to
  `package.json` and drop the explicit `version:` from `pnpm/action-setup`,
  letting the action read the version from `packageManager`. This removes the
  per-workflow literal entirely so future bumps happen in one place.

## Approach

1. Decide between approach A (literal pin in each workflow) and approach B
   (`packageManager` field + version-less `pnpm/action-setup`). Recommendation:
   **B**, because it collapses the version declarations to one place and the
   repo already centralizes the pnpm constraint in `package.json`.
2. If B: add `"packageManager": "pnpm@10.33.4"` to `package.json`, then remove
   the `with: version:` block from the `pnpm/action-setup@v4` step in all three
   workflows. If A: set `version: 10.33.4` in all three steps and skip the
   `package.json` change.
3. Push the branch and confirm all three workflows install the same pnpm
   version in their logs.

## Files to touch

| Location | Kind | Change |
|---|---|---|
| `.github/workflows/ci.yml` | modify | unify pnpm version (literal `10.33.4`, or remove `version:` under approach B) |
| `.github/workflows/build-check.yml` | modify | unify pnpm version to match |
| `.github/workflows/release.yml` | modify | unify pnpm version to match |
| `package.json` | modify | (approach B only) add `packageManager: pnpm@10.33.4` field |

## Acceptance criteria

- [ ] AC-1: The pnpm version installed by `pnpm/action-setup@v4` is identical across `ci.yml`, `build-check.yml`, and `release.yml`.
- [ ] AC-2: That version satisfies the `^10.33.4` constraint declared in `package.json` (i.e. `>= 10.33.4, < 11`).
- [ ] AC-3: All three workflows pass on the branch with the unified version.

## Out of scope

- Upgrading the pnpm major/minor beyond what `package.json` already requires.
- Changing the Node version setup (`actions/setup-node`), which is a separate concern.

## Dependencies

- none

## Discovery context

Surfaced while summarizing the project's CI workflows on 2026-05-26: the pnpm
pins were noticed to disagree across the three workflow files and with
`package.json`'s declared `^10.33.4`.
