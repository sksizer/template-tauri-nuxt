Follow these steps exactly in order.

## 1. Record the current Tauri major version

Read `src-tauri/Cargo.toml` and note the major version of the `tauri` crate (e.g. `"2"` → major `2`). This is the authoritative pin and will be used to detect and gate the atomic Tauri bump.

## 2. Ensure cargo-upgrade is available

The Rust upgrade step requires `cargo upgrade`, which ships with `cargo-edit`:

```
cargo upgrade --help &>/dev/null || cargo install cargo-edit
```

## 3. Upgrade all NON-Tauri dependencies to latest

### 3a. JS (pnpm)

Run `pnpm update --latest` at the root and in `src-nuxt/`, but exclude every `@tauri-apps/*` package so they can be bumped atomically as one unit in step 4.

The simplest safe pattern: snapshot the current `@tauri-apps/*` versions from each `package.json`, run `pnpm update --latest`, then restore those exact versions in each `package.json` and re-run `pnpm install` to reconcile the lockfile.

```
# At root
cp package.json /tmp/root-pkg.json.bak
pnpm update --latest 2>&1
# Restore any @tauri-apps/* versions that got bumped by this step
# (use jq or manual edits — see Cargo.toml-style restoration below for the pattern)
pnpm install 2>&1

# In src-nuxt/
cd src-nuxt
cp package.json /tmp/src-nuxt-pkg.json.bak
pnpm update --latest 2>&1
# Restore any @tauri-apps/* versions
pnpm install 2>&1
cd ..
```

### 3b. Rust (cargo)

```
cd src-tauri
cargo upgrade --exclude tauri --exclude tauri-build \
    $(grep -oE '^tauri-plugin-[a-z0-9_-]+' Cargo.toml | sed 's/^/--exclude /') 2>&1
cargo update 2>&1
cd ..
```

## 4. Atomically upgrade the Tauri set (if a newer major is available)

Determine the latest major version of the `tauri` crate on crates.io and of `@tauri-apps/cli` on npm:

```
curl -s https://crates.io/api/v1/crates/tauri | grep -oE '"max_stable_version":"[^"]+"' | head -1
pnpm view @tauri-apps/cli version
```

Let `CURRENT_MAJOR` = the major from step 1 and `LATEST_MAJOR` = the smaller of the two latest majors observed above (take the MIN so we don't move one ecosystem ahead of the other).

- If `LATEST_MAJOR == CURRENT_MAJOR`, no Tauri bump is needed — skip this step.
- If `LATEST_MAJOR > CURRENT_MAJOR`, upgrade the entire Tauri set to `LATEST_MAJOR` in ONE logical change:
  - Root `package.json`: set `@tauri-apps/cli` to `^LATEST_MAJOR`.
  - `src-nuxt/package.json`: set `@tauri-apps/api`, `@tauri-apps/plugin-opener`, and any other `@tauri-apps/*` to `^LATEST_MAJOR`.
  - `src-tauri/Cargo.toml`: set `tauri`, `tauri-build`, and every `tauri-plugin-*` crate to `"LATEST_MAJOR"` (or `"^LATEST_MAJOR"`, matching the existing style).
  - Run `pnpm install` at root and in `src-nuxt/`, and `cargo update` in `src-tauri/`.
  - Check the Tauri migration guide (https://tauri.app/start/migrate/) for required code changes; apply them if obvious, otherwise leave TODOs in a dedicated commit message section.

After this step, every package in the Tauri set MUST resolve to the same major in the lockfiles. If you cannot achieve that, revert all changes (`git checkout .`), print "FAILED: Tauri set cannot be bumped atomically — needs manual investigation", and exit.

## 5. Quality gate

Run:

```
just ci
```

If formatting fails, run `just full-write` and re-run `just ci`.

If lint / typecheck / test failures remain, read the failing code and fix it. Breaking API changes from a major bump are expected — apply obvious migrations. If a failure requires non-trivial judgment (e.g. a removed API with no drop-in replacement), revert the specific dep to its previous major, note the skip in the PR body, and re-run `just ci`.

If you cannot get `just ci` green after reasonable effort, revert all changes (`git checkout .`), print "FAILED: could not resolve checks after dependency upgrade", and exit.

## 6. Create branch, commit, and PR

```
BRANCH="chore/deps-upgrade-$(date +%Y-%m-%d)"
git checkout -b "$BRANCH"
git add -A
git diff --cached --quiet && { echo "No changes to commit."; exit 0; }
git commit -m "chore: upgrade dependencies to latest"
git push -u origin "$BRANCH"
```

Create the PR:

- Title: `chore: upgrade dependencies to latest`
- Body: four sections —
  - **JS packages upgraded** (grouped by root / src-nuxt, with `old → new` version pairs)
  - **Rust crates upgraded** (with `old → new` pairs)
  - **Tauri bump** (either "stayed on major N" or "moved from N → M, with X code changes applied")
  - **Skipped or deferred** (any deps intentionally pinned back, with the reason)
  - **Code changes** (summary of any migration fixes applied)

Print the PR URL.
