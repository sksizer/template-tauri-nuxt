Follow these steps exactly in order.

## 1. Check for available updates

Run each of the following and capture the output:

```
pnpm outdated 2>&1 || true
cd src-nuxt && pnpm outdated 2>&1 || true; cd ..
cd src-tauri && cargo update --dry-run 2>&1; cd ..
```

`pnpm outdated` exits non-zero when there are outdated packages — that's expected, don't treat it as a failure.

If ALL of these report nothing to update (no rows from pnpm, and `cargo update --dry-run` shows no "Updating"/"Adding" lines), print "No dependency updates available." and exit. Do not create a branch, commit, or PR.

## 2. Apply within-range updates

Run these in order. Do NOT pass `--latest` to pnpm and do NOT run `cargo upgrade` — this script is for in-range bumps only.

```
pnpm update 2>&1
cd src-nuxt && pnpm update 2>&1; cd ..
cd src-tauri && cargo update 2>&1; cd ..
```

Save the output — you will summarize the bumped packages in the PR body.

## 3. Verify the Tauri version invariant

The following packages must all remain on the same major version after the update (they're a coupled set and will break at runtime otherwise):

- Root `package.json`: `@tauri-apps/cli`
- `src-nuxt/package.json`: `@tauri-apps/api`, `@tauri-apps/plugin-opener`
- `src-tauri/Cargo.toml`: `tauri`, `tauri-build`, `tauri-plugin-opener` (and any other `tauri-plugin-*`)

Within-range updates should preserve this invariant automatically. Double-check by reading the resolved versions in `pnpm-lock.yaml`, `src-nuxt/pnpm-lock.yaml`, and `src-tauri/Cargo.lock`. If majors have drifted, revert all changes (`git checkout .`), print "FAILED: Tauri major-version drift after in-range update — needs manual investigation", and exit.

## 4. Quality gate

Run:

```
just ci
```

If formatting fails, run `just full-write` and re-run `just ci`.

If lint, typecheck, or test failures remain, read the failing code, fix it (the cause will typically be a bumped dep with a breaking change inside its declared range — pin that dep back in the relevant manifest if the fix is non-trivial), and re-run `just ci` until it passes.

If you cannot resolve failures after a few attempts, revert changes (`git checkout .`), print "FAILED: could not resolve checks after dependency update", and exit.

## 5. Create branch, commit, and PR

```
BRANCH="chore/deps-update-$(date +%Y-%m-%d)"
git checkout -b "$BRANCH"
git add -A
git diff --cached --quiet && { echo "No changes to commit."; exit 0; }
git commit -m "chore: update dependencies (within semver ranges)"
git push -u origin "$BRANCH"
```

Create the PR:

- Title: `chore: update dependencies (within semver ranges)`
- Body: two sections —
  - **JS packages bumped** (grouped by root / src-nuxt, from the pnpm update output)
  - **Rust crates bumped** (from the cargo update output)
  - A final note on whether any code changes were required to pass `just ci`.

Print the PR URL.
