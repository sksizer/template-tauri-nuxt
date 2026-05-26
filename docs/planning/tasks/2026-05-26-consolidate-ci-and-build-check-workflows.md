---
type: task
schema_version: '3'
status: planning/proposed
created: '2026-05-26'
impact: medium
complexity: small
tags:
- ci
- github-actions
related: []
---
# Fold build-check into ci.yml to remove duplicated workflow setup

## Goal

`ci.yml` and `build-check.yml` trigger on the same events (push to `main`, PRs
to `main`) and both stand up a near-identical `ubuntu-22.04` toolchain (apt
system deps, Node, pnpm, Rust, rust-cache, `project:init`). The only real
difference is the final step: `ci.yml`'s rust job runs lint/format/test while
`build-check.yml` runs `pnpm tauri build --ci`. Maintaining two files means the
shared setup drifts (it already has — see the pnpm-version task). Folding the
build check in as a third job of `ci.yml` gives one workflow file to keep in
sync. This task is a structural decision for review, not a forced merge.

## Today

| Location | Role today |
|---|---|
| `.github/workflows/ci.yml` | "CI" workflow; jobs `frontend` and `rust`; triggers on push/PR to `main` |
| `.github/workflows/build-check.yml` | "Build Check" workflow; single `build-check` job running `pnpm tauri build --ci`; same push/PR-to-`main` triggers and near-identical `ubuntu-22.04` setup |

## Proposed

A single workflow file (`ci.yml`) contains the frontend, rust, and build-check
jobs, and `build-check.yml` no longer exists. Shared setup (apt deps, Node,
pnpm, Rust, cache, `project:init`) lives in one place per job, eliminating the
cross-file drift risk. The build-check job retains its current behavior
(`pnpm tauri build --ci` on `ubuntu-22.04`).

## Approach

1. Confirm the consolidation direction with the reviewer. Recommendation:
   **merge** `build-check` into `ci.yml` as a third job, because the two files
   already share triggers and setup and have drifted. (Keeping them separate is
   the alternative if the reviewer prefers an isolated build signal.)
2. Add a `build-check` job to `ci.yml` mirroring the current
   `build-check.yml` job (system deps, Node, pnpm, Rust, rust-cache,
   `project:init`, then `pnpm tauri build --ci`).
3. Delete `.github/workflows/build-check.yml`.
4. Push and confirm the consolidated `ci.yml` runs all three jobs and the
   build-check job still produces a successful Tauri build.

## Files to touch

| Location | Kind | Change |
|---|---|---|
| `.github/workflows/ci.yml` | modify | add a `build-check` job running `pnpm tauri build --ci` |
| `.github/workflows/build-check.yml` | delete | remove the standalone workflow once its job lives in `ci.yml` |

## Acceptance criteria

- [ ] AC-1: A single workflow run on a PR to `main` executes the frontend, rust, and build-check jobs.
- [ ] AC-2: `.github/workflows/build-check.yml` no longer exists in the repo.
- [ ] AC-3: The build-check job runs `pnpm tauri build --ci` on `ubuntu-22.04` and succeeds.

## Out of scope

- Deduplicating the toolchain setup into a reusable composite action or `workflow_call` (a larger refactor; revisit only if the duplication still hurts after consolidation).
- Changing what the build-check actually verifies (cross-platform builds are tracked in the cross-platform-build task).

## Dependencies

- Coordinate with `[[2026-05-26-unify-pnpm-version-across-ci-workflows]]` so the merged file lands one agreed pnpm version rather than re-introducing drift.

## Discovery context

Surfaced while summarizing the project's CI workflows on 2026-05-26: `ci.yml`
and `build-check.yml` were noted to share triggers and setup with only the
terminal step differing.
