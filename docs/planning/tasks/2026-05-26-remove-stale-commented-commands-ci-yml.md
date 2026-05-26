---
type: task
schema_version: '3'
status: planning/proposed
created: '2026-05-26'
impact: low
complexity: small
tags:
- ci
- github-actions
related: []
---
# Remove leftover commented-out command lines from ci.yml

## Goal

The `frontend` job in `ci.yml` carries two commented-out alternative command
lines (`# run: cd src-nuxt && pnpm run lint` after the Lint step and
`# run: cd src-nuxt && pnpm run typecheck` after the Type check step). These are
superseded by the `pnpm frontend:lint` / `pnpm frontend:typecheck` package
scripts the steps now use, and they're dead clutter that can mislead a future
editor into thinking there's a live alternative. This task removes them so the
workflow reads cleanly.

## Today

| Location | Role today |
|---|---|
| `.github/workflows/ci.yml` | the `frontend` job's `Lint` step runs `pnpm frontend:lint` with a stale `# run: cd src-nuxt && pnpm run lint` comment beneath it; the `Type check` step runs `pnpm frontend:typecheck` with a stale `# run: cd src-nuxt && pnpm run typecheck` comment beneath it |

## Proposed

The `frontend` job in `ci.yml` contains no commented-out `# run:` lines. Each
step has exactly one active command and no dead alternatives.

## Approach

1. Delete the `# run: cd src-nuxt && pnpm run lint` comment line beneath the
   `Lint` step.
2. Delete the `# run: cd src-nuxt && pnpm run typecheck` comment line beneath
   the `Type check` step.
3. Confirm the workflow still parses and the `frontend` job runs unchanged
   (the active `run:` lines are untouched).

## Files to touch

| Location | Kind | Change |
|---|---|---|
| `.github/workflows/ci.yml` | modify | remove the two stale `# run:` comment lines in the `frontend` job |

## Acceptance criteria

- [ ] AC-1: No commented-out `# run:` line remains in `ci.yml`.
- [ ] AC-2: The active `Lint` and `Type check` steps still invoke `pnpm frontend:lint` and `pnpm frontend:typecheck` respectively (no behavior change).
- [ ] AC-3: The `frontend` job passes after the edit.

## Out of scope

- Renaming or restructuring the steps themselves.
- Touching the `rust` job or other workflow files.

## Dependencies

- none

## Discovery context

Surfaced while summarizing the project's CI workflows on 2026-05-26: the two
commented-out `cd src-nuxt && pnpm run ...` lines in `ci.yml` were flagged as
leftover dead lines.
