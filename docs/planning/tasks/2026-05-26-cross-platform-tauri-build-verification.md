---
type: task
schema_version: '3'
status: planning/proposed
created: '2026-05-26'
impact: medium
complexity: medium
tags:
- ci
- github-actions
related: []
---
# Verify Tauri builds on macOS and Windows before release, not only at tag time

## Goal

The only Tauri build run on push/PR is `build-check.yml`, which builds on
`ubuntu-22.04` only. macOS and Windows builds are first exercised in
`release.yml`, which triggers on `v*` tags. That means a change that breaks the
macOS or Windows build is not discovered until a release is being cut — the
worst possible time. This task adds pre-release build verification for the
non-Linux platforms so cross-platform breakage surfaces on the PR that
introduces it.

## Today

| Location | Role today |
|---|---|
| `.github/workflows/build-check.yml` | builds `pnpm tauri build --ci` on `ubuntu-22.04` only, on push/PR to `main` |
| `.github/workflows/release.yml` | matrix-builds macOS (arm64 + x86_64), `ubuntu-22.04`, and Windows via `tauri-apps/tauri-action@v0.6.1`; triggers only on `v*` tags |

## Proposed

A push/PR to `main` exercises the Tauri build on macOS and Windows in addition
to Linux, so cross-platform build breakage is caught pre-merge rather than at
tag time. The exact gating posture is a decision for review (see Approach):
either run the cross-platform builds on every PR, or run them on a cheaper
cadence (e.g. only when build-relevant paths change, or on a manual/scheduled
trigger) to manage runner-minute cost.

## Approach

1. Decide the trigger posture with the reviewer. Options:
   - **Every PR (simplest, highest cost):** turn `build-check` into a
     matrix across `ubuntu-22.04`, `macos-latest`, `windows-latest`.
   - **Path-filtered:** run the cross-platform matrix only when `src-tauri/**`,
     `src-nuxt/**`, lockfiles, or workflow files change.
   - **Manual / scheduled:** keep PR builds Linux-only, add a
     `workflow_dispatch` + nightly `schedule` job for the macOS/Windows matrix.
   Recommendation: **path-filtered matrix** — catches real breakage on the PRs
   that can cause it without paying macOS/Windows minutes on docs-only changes.
2. Convert the `build-check` job to a `strategy.matrix` over the chosen
   platforms, adding the Ubuntu-only `apt-get install` step behind an
   `if: matrix.platform == 'ubuntu-22.04'` guard (mirroring `release.yml`) and
   adding the macOS Rust target setup the same way `release.yml` does.
3. Apply the chosen trigger filter (path filter and/or `workflow_dispatch` /
   `schedule`) to the build-check workflow.
4. Push a branch that touches `src-tauri/` and confirm the macOS and Windows
   build jobs run and succeed.

## Files to touch

| Location | Kind | Change |
|---|---|---|
| `.github/workflows/build-check.yml` | modify | convert the single Linux build job to a cross-platform matrix and apply the agreed trigger filter |

## Acceptance criteria

- [ ] AC-1: A qualifying push/PR to `main` runs a Tauri build on macOS and Windows (not only Linux).
- [ ] AC-2: The macOS and Windows build jobs complete successfully on a branch that changes `src-tauri/`.
- [ ] AC-3: The Linux build job (`ubuntu-22.04`) continues to run and pass under the new matrix.

## Out of scope

- Producing or uploading installable release artifacts on PRs (that remains `release.yml`'s job; this task verifies the build compiles, not distribution).
- Code signing / notarization for macOS or Windows.

## Dependencies

- Likely overlaps with `[[2026-05-26-consolidate-ci-and-build-check-workflows]]`: if build-check is folded into `ci.yml` first, apply this matrix to the merged job instead. Sequence the two so they don't conflict.

## Discovery context

Surfaced while summarizing the project's CI workflows on 2026-05-26: noted that
no macOS/Windows build runs until a `v*` tag triggers `release.yml`, so
cross-platform breakage is invisible until release time.
