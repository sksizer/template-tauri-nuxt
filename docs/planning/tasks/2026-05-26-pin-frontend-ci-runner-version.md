---
type: task
schema_version: '3'
status: open/ready
created: '2026-05-26'
impact: low
complexity: small
tags:
- ci
- github-actions
related: []
---
# Pin the frontend CI job to a fixed Ubuntu runner version

## Goal

In `ci.yml`, the `frontend` job runs on `ubuntu-latest` while the `rust` job
runs on the explicitly pinned `ubuntu-22.04`. `ubuntu-latest` is a moving
label that GitHub re-points to a new Ubuntu major every so often, which can
introduce a runner-image change the project didn't choose. Pinning the
frontend job to an explicit version makes CI reproducible and consistent with
how the rest of the repo's jobs are pinned. Low impact (the frontend job has
no native/Tauri system dependencies), but worth aligning for predictability.

## Today

| Location | Role today |
|---|---|
| `.github/workflows/ci.yml` | `frontend` job declares `runs-on: ubuntu-latest`; the `rust` job in the same file declares `runs-on: ubuntu-22.04` |

## Proposed

The `frontend` job runs on an explicitly pinned Ubuntu runner image rather than
the floating `ubuntu-latest` label. The chosen version is a decision for review
(see Approach), but the destination is: no `*-latest` runner label remains in
`ci.yml`.

## Approach

1. Decide which pinned image the frontend job should use. Recommendation:
   `ubuntu-24.04` (current latest LTS image; the frontend job has no Tauri
   native deps tying it to 22.04, so it does not need to match the rust job's
   `ubuntu-22.04`). Alternative: pin to `ubuntu-22.04` for uniformity with the
   rust job.
2. Replace `runs-on: ubuntu-latest` in the `frontend` job with the chosen
   pinned image.
3. Push and confirm the frontend job still passes on the pinned image.

## Files to touch

| Location | Kind | Change |
|---|---|---|
| `.github/workflows/ci.yml` | modify | change the `frontend` job's `runs-on: ubuntu-latest` to a pinned Ubuntu image |

## Acceptance criteria

- [ ] AC-1: No job in `ci.yml` uses a floating `*-latest` runner label; every `runs-on` is a pinned version.
- [ ] AC-2: The `frontend` job passes on the newly pinned runner image.

## Out of scope

- Pinning runner images in `release.yml` (its matrix uses `*-latest` for macOS/Windows by design; revisit separately if desired).
- Changing the rust job's existing `ubuntu-22.04` pin.

## Dependencies

- none

## Discovery context

Surfaced while summarizing the project's CI workflows on 2026-05-26: the
frontend job's `ubuntu-latest` was noted as inconsistent with the rust job's
explicit `ubuntu-22.04` pin.
