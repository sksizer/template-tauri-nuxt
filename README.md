# Tauri + Nuxt.js + TypeScript Template

A starting point for desktop applications using [Tauri](https://tauri.app/), [Nuxt.js](https://nuxt.com/), and [TypeScript](https://www.typescriptlang.org/).

## Features

- Peer directory structure separating frontend and backend code
- Pre-configured CI/CD (lint, build, release)
- Comprehensive linting and formatting (ESLint, oxlint, Prettier, Clippy, rustfmt)
- Git hooks via Lefthook with conventional commits
- Storybook for isolated component development
- Makefile and mise for ergonomic development commands
- Version management with release-it (syncs `package.json` → `Cargo.toml`)
- Template drift detection against upstream

## Project Structure

```
template_tauri_nuxt/
├── .github/           # CI/CD workflows and Dependabot config
│   └── workflows/     # ci, build-check, release
├── .scripts/          # Helper scripts for CI and tooling
├── docs/              # Project documentation
├── src-nuxt/          # Frontend Nuxt.js application
│   ├── .storybook/    # Storybook configuration
│   ├── app/           # Vue components and assets
│   │   └── components/  # Extracted components + stories
│   ├── server/        # Nuxt server code
│   ├── tests/         # Frontend tests (Vitest)
│   └── public/        # Static assets
└── src-tauri/         # Rust/Tauri backend
    ├── src/           # Rust source code
    ├── capabilities/  # Tauri capability definitions
    └── icons/         # App icons (all platforms)
```

## Prerequisites

- [Node.js](https://nodejs.org/) (LTS) and [pnpm](https://pnpm.io/)
- [Rust](https://www.rust-lang.org/tools/install) (1.93.0+)
- [Tauri CLI](https://tauri.app/start/) v2
- **Optional**: [mise](https://mise.jdx.dev/) — auto-installs all tool versions

## Setup

```bash
# With mise (recommended — installs Node, pnpm, Rust, tauri-cli automatically):
mise install

# Then install project dependencies:
make setup        # or: pnpm run project:init && pnpm lefthook install
```

## Development Commands

### Makefile (recommended)

| Target | Description |
|--------|-------------|
| `make dev` | Run Tauri dev server |
| `make build` | Production build |
| `make build-debug` | Build with debug symbols |
| `make lint` | Run all linters (frontend + Rust) |
| `make lint-fix` | Auto-fix lint issues |
| `make format` | Format all code |
| `make format-check` | Check formatting without changes |
| `make test` | Run all tests (frontend + Rust) |
| `make ci` | Full CI pipeline (lint, format-check, test, build) |
| `make setup` | Install deps and git hooks |
| `make storybook` | Launch Storybook dev server |
| `make storybook-build` | Build Storybook static site |
| `make clean` | Remove build artifacts |
| `make help` | Show all available targets |

### pnpm / cargo

```bash
pnpm tauri dev      # or: cargo tauri dev
pnpm tauri build    # or: cargo tauri build
```

## Developer Tooling

JS/TS tooling configs (Prettier, oxlint, `eslint-config-prettier`) live in `src-nuxt/` alongside the code they check. The root `package.json` orchestrates cross-project scripts.

### mise

[mise](https://mise.jdx.dev/) manages tool versions and provides convenience tasks. Pinned versions:

- **Node**: LTS
- **pnpm**: latest
- **Rust**: 1.93.0 (auto-installs `tauri-cli` v2.10.0)

Run `mise run dev`, `mise run build`, `mise run test_all`, etc.

### Lefthook (Git Hooks)

**pre-commit** (parallel):
- `eslint` — lint JS/TS/Vue
- `oxlint` — fast lint pass
- `prettier` — format check
- `clippy` — Rust lint (warnings = errors)
- `rustfmt` — Rust format check

**commit-msg**: `commitlint` enforces [Conventional Commits](https://www.conventionalcommits.org/) via `@commitlint/config-conventional`.

### Storybook

Standalone [Storybook](https://storybook.js.org/) (`@storybook/vue3-vite`) for isolated component development. Stories are co-located with components in `src-nuxt/app/components/`.

```bash
make storybook          # or: pnpm storybook
make storybook-build    # build static Storybook site
```

### EditorConfig

Consistent formatting across editors: 2-space indent (4 for Rust, tabs for Makefile), LF line endings, UTF-8.

## Components

Extracted reusable Vue components in `src-nuxt/app/components/`:

| Component | Description |
|-----------|-------------|
| `AppHeader` | Application header with branding |
| `AppFooter` | Footer with links |
| `GradientButton` | Styled button with gradient effect |
| `ResultBanner` | Display area for operation results |
| `EchoCard` | Card for echo/ping functionality |

Each component has a co-located `.stories.ts` file for Storybook.

## Linting & Formatting

| Layer | Frontend | Backend |
|-------|----------|---------|
| Fast lint | [oxlint](https://oxc.rs/) | — |
| Full lint | [ESLint](https://eslint.org/) + `@nuxt/eslint` | [cargo clippy](https://doc.rust-lang.org/clippy/) (`-D warnings`) |
| Format | [Prettier](https://prettier.io/) (no semi, single quotes, 100 width) | `cargo fmt` |

## Testing

| Layer | Tool | Command |
|-------|------|---------|
| Frontend | [Vitest](https://vitest.dev/) + `@nuxt/test-utils` | `make test-unit` |
| Backend | `cargo test` | `make rust-test` |
| All | — | `make test` |

## CI/CD

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| [`ci.yml`](.github/workflows/ci.yml) | Push/PR to `main` | Frontend lint + typecheck + test; Rust format + clippy + test |
| [`build-check.yml`](.github/workflows/build-check.yml) | Push/PR to `main` | Full Tauri build verification |
| [`release.yml`](.github/workflows/release.yml) | Tag `v*` | Multi-platform build (macOS aarch64/x86_64, Ubuntu, Windows) via `tauri-apps/tauri-action`; creates draft GitHub release |

**Dependabot**: Weekly updates for npm (root + `src-nuxt`) and Cargo (`src-tauri`).

## Version Management

Single version source in root `package.json`, synced to `src-tauri/Cargo.toml` via [release-it](https://github.com/release-it/release-it) + `@release-it/bumper`.

```bash
pnpm run release    # bumps version, tags as v{version}, syncs Cargo.toml
```

## Template Drift Detection

Compare your project against the upstream template for tooling file drift:

```bash
pnpm run template:check
```

## Nuxt Configuration

- **SSR disabled** — SPA mode for desktop
- **Dev server**: `localhost:1420`
- **Modules**: `@nuxt/ui`, `@nuxt/content`, `@nuxt/fonts`, `@nuxt/icon`, `@nuxt/scripts`, `@nuxt/eslint`, `@nuxt/test-utils`
- **Styling**: Tailwind CSS v4 (via `@nuxt/ui`)

## Tauri Configuration

- **`withGlobalTauri`**: enabled — exposes Tauri API to frontend
- **Default window**: 800x600
- **Build command**: `pnpm generate` (static output)
- **Version**: reads from root `package.json`


## Acknowledgements

Build tooling and developer experience configuration (Lefthook, commitlint, Prettier, oxlint, EditorConfig, Makefile) were inspired by and adapted from [oxide-dock](https://github.com/fridzema/oxide-dock) by [@fridzema](https://github.com/fridzema).

## Additional Resources

- [Tauri Documentation](https://tauri.app/v1/guides/)
- [Nuxt.js Documentation](https://nuxt.com/docs)
- [TypeScript Documentation](https://www.typescriptlang.org/docs/)
