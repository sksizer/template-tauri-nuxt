---
type: task
schema_version: '3'
status: in-progress
created: '2026-05-27'
impact: medium
complexity: medium
tags:
- ci
- github-actions
related: []
readiness_verified_at: '2026-05-27T03:32:06Z'
last_reviewed: '2026-05-27'
---
# Overhaul the CI workflows in one pass to avoid cross-task merge conflicts

## Goal

Five separately-identified CI gaps all touch the same small set of workflow
files — `ci.yml` is touched by four of them and `build-check.yml` by three — so
shipping them as independent PRs would produce heavy merge conflicts (and a
direct contradiction: one change deletes `build-check.yml` while another
modifies it). This task bundles all five into a single ordered change set so
the work lands as one coherent PR. It replaces the five granular tasks that
were drafted first (pnpm-version unification, frontend runner pin,
build-check/ci consolidation, cross-platform build verification, and the
ci.yml comment cleanup) — each survives here as a numbered step in the
Approach.

## Today

| Location | Role today |
|---|---|
| `.github/workflows/ci.yml` | "CI" workflow; `frontend` job on `ubuntu-latest` with two stale `# run:` comment lines, `rust` job on `ubuntu-22.04`; `pnpm/action-setup@v4` pinned to `10.24.0` |
| `.github/workflows/build-check.yml` | "Build Check" workflow; single `ubuntu-22.04` job running `pnpm tauri build --ci`; pnpm pinned to `10.28.2`; near-identical setup to `ci.yml`; Linux-only |
| `.github/workflows/release.yml` | matrix release build (macOS arm64+x86_64, `ubuntu-22.04`, Windows) on `v*` tags; pnpm pinned to `10.28.2` |
| `package.json` | declares `"pnpm": "^10.33.4"`; no `packageManager` field |

## Proposed

A single PR leaves the CI workflows in this end state:

- **One pnpm version everywhere**, consistent with `package.json`'s `^10.33.4`.
- **No floating `*-latest` runner** in the push/PR CI jobs.
- **No dead commented-out command lines** in `ci.yml`.
- **One workflow file** (`ci.yml`) holding the frontend, rust, and build jobs;
  `build-check.yml` deleted.
- **The build job runs on macOS and Windows in addition to Linux** before
  release, so cross-platform breakage is caught pre-merge.

## Approach

Ordered so each step builds on the previous within the single PR (no internal
conflicts). Recommendations are given where a granular task left a decision
open; the reviewer can override any of them on this PR.

1. **Cleanup (`ci.yml`):** delete the two stale `# run: cd src-nuxt && pnpm run ...`
   comment lines under the `Lint` and `Type check` steps.
2. **Pin frontend runner (`ci.yml`):** replace the `frontend` job's
   `runs-on: ubuntu-latest` with a pinned image. Recommendation: `ubuntu-24.04`
   (frontend has no Tauri native deps tying it to 22.04).
3. **Unify pnpm:** make pnpm a single source of truth. Recommendation: add
   `"packageManager": "pnpm@10.33.4"` to `package.json` and drop the explicit
   `with: version:` from every `pnpm/action-setup@v4` step (`ci.yml`,
   `release.yml`, and the build job). Alternative: pin the literal `10.33.4` in
   each step instead.
4. **Consolidate build-check into `ci.yml`:** add a `build-check` job to
   `ci.yml` mirroring the current `build-check.yml` job (apt system deps, Node,
   pnpm, Rust, rust-cache, `project:init`, then `pnpm tauri build --ci`), then
   delete `.github/workflows/build-check.yml`.
5. **Cross-platform build matrix:** convert that new `build-check` job to a
   `strategy.matrix` over `ubuntu-22.04`, `macos-latest`, `windows-latest`,
   guarding the apt step with `if: matrix.platform == 'ubuntu-22.04'` and
   adding the macOS Rust targets the way `release.yml` does. Recommendation:
   gate the macOS/Windows legs with a path filter (`src-tauri/**`,
   `src-nuxt/**`, lockfiles, workflow files) so docs-only PRs don't pay
   macOS/Windows runner minutes. Alternatives: run on every PR, or move the
   non-Linux legs to a `workflow_dispatch` + nightly `schedule`.
6. Push the branch (touching `src-tauri/` so the cross-platform legs fire) and
   confirm every job passes.

## Files to touch

| Location | Kind | Change |
|---|---|---|
| `.github/workflows/ci.yml` | modify | remove stale comments; pin frontend runner; unify pnpm; add a cross-platform `build-check` job |
| `.github/workflows/build-check.yml` | delete | folded into `ci.yml` |
| `.github/workflows/release.yml` | modify | unify pnpm version to match |
| `package.json` | modify | add `packageManager: pnpm@10.33.4` (recommended pnpm-unification path) |

## Acceptance criteria

- [ ] AC-1: A single PR to `main` triggers one workflow run covering the frontend, rust, and build jobs.
- [ ] AC-2: `.github/workflows/build-check.yml` no longer exists.
- [ ] AC-3: The pnpm version is identical across all remaining workflow jobs and satisfies `package.json`'s `^10.33.4`.
- [ ] AC-4: No push/PR CI job uses a floating `*-latest` runner label; no commented-out `# run:` line remains in `ci.yml`.
- [ ] AC-5: A qualifying PR runs the Tauri build on macOS and Windows (not only Linux), and all three platform legs succeed on a branch that changes `src-tauri/`.

## Out of scope

- Changing `release.yml`'s matrix or trigger beyond the pnpm-version unification.
- Code signing / notarization, or uploading installable artifacts on PRs.
- Extracting shared setup into a composite action or `workflow_call` (revisit only if duplication still hurts after consolidation).

## Dependencies

- none (this task absorbs the five superseded tasks; no external blockers)

## Discovery context

Bundled on 2026-05-27 from five granular CI-gap tasks created 2026-05-26.
They were consolidated because all five touch the same workflow files
(`ci.yml`, `build-check.yml`, `release.yml`) and would merge-conflict — and in
one case directly contradict — if shipped as separate PRs.
