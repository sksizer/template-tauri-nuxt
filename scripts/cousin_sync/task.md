You are syncing the shared Tauri scaffolding layer from the canonical template to this cousin template.

The canonical template is at: https://github.com/sksizer/template-tauri-nuxt

## What to sync (the shared layer)

These files should be kept equivalent across all cousin templates, adapted for the
cousin's frontend directory name and framework:

### Direct copy (framework-agnostic)
- `src-tauri/` — all Rust source, Cargo.toml (deps only, not name/version), rustfmt.toml, build.rs, capabilities/, icons/
- `scripts/dev-port.sh` — port assignment logic
- `scripts/tauri-wrapper.mjs` — Tauri CLI wrapper
- `scripts/bring_up_to_date.sh` — upstream sync script
- `scripts/bring_up_to_date_all.sh` — batch sync script
- `scripts/bring_up_to_date/` — sync prompt files
- `scripts/sync_cousins.sh` — cousin sync script
- `scripts/cousin_sync/` — cousin sync prompt files
- `.scripts/backend-lint`, `.scripts/backend-format-check`, `.scripts/backend-test`
- `.editorconfig`
- `cliff.toml`
- `.prettierrc.yml`
- `CLAUDE.md`

### Adapt (replace `src-nuxt` with the cousin's frontend dir)
- `justfile` — same targets, different frontend dir references
- `Makefile` — same targets, different frontend dir references
- `lefthook.yml` — same hooks, different root dirs for frontend hooks
- `mise.toml` — same tools, possibly different frontend-specific config
- `.github/workflows/ci.yml` — same structure, different frontend build/test commands
- `.github/workflows/build-check.yml`
- `.github/workflows/release.yml`
- `.github/dependabot.yml`
- `package.json` — same script structure, different frontend dir in commands
- `.release-it.json`
- `commitlint.config.ts`

### Adapt features for the cousin's framework
When the canonical template has added or changed user-facing features or example code, implement
the equivalent in the cousin's framework using idiomatic patterns. Do NOT copy framework-specific
code verbatim. Instead:

- **Tauri commands with frontend bindings**: If a new Tauri command was added in `src-tauri/src/`
  along with frontend code that calls it, implement the same Tauri command call using the cousin's
  frontend framework. For example, a Vue composable becomes a React hook, an Astro component, or
  a vanilla JS function.
- **UI features** (clipboard, file dialogs, notifications, etc.): Implement the same capability
  using the cousin framework's idioms — components, event handlers, and state management that are
  natural for that framework.
- **Frontend tooling improvements**: If a new testing pattern, component structure convention,
  linting rule, or dev convenience was added, evaluate whether the same concept applies to the
  cousin's ecosystem. If yes, implement it. If the cousin's framework has no equivalent (e.g. a
  Nuxt-specific module), note it in the PR as intentionally skipped.
- **Example/demo code**: Keep the example apps functionally equivalent across all templates so that
  users see the same capabilities regardless of which template they chose.

### Do NOT sync (verbatim)
- Framework-specific source code (don't copy Vue files into an Astro project, etc.)
- Framework-specific config inside the frontend dir (nuxt.config.ts, astro.config.mjs, etc.)
- README.md, docs/
- package.json name/version
- src-tauri/Cargo.toml name/version/description
- src-tauri/tauri.conf.json identifier/productName/beforeDevCommand/beforeBuildCommand/frontendDist

## Process

1. Fetch the canonical template's current state
2. Identify what the cousin's frontend directory is named (look at existing structure)
3. Compare shared-layer files and identify gaps or drift
4. Apply changes, adapting `src-nuxt` references to the cousin's frontend dir name
5. Run quality checks: `just full-check` (or `make full-check` if no justfile)
6. Fix any issues with `just full-write` and re-check

When finished, create a branch named `chore/sync-from-canonical-template` and commit:

```
chore: sync shared Tauri layer from canonical template

Performed the following:
- <list each change made>

Adapted the following for this framework:
- <list adaptations, e.g. "src-nuxt -> src-astro in lefthook.yml">

Did not bring over:
- <list anything intentionally skipped, or "None">
```

Push the branch and create a pull request with:
- Title: `chore: sync shared Tauri layer from canonical template`
- Body summarizing changes, adaptations, and skips
