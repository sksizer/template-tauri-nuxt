# Tauri + Nuxt.js + TypeScript Template

A starting point for desktop applications using [Tauri](https://tauri.app/), [Nuxt.js](https://nuxt.com/), and [TypeScript](https://www.typescriptlang.org/).

## Features

- Peer directory structure separating frontend and backend code
- Pre-configured CI/CD (lint, build, release)
- Comprehensive linting and formatting (ESLint, oxlint, Prettier, Clippy, rustfmt)
- Git hooks via Lefthook with conventional commits
- Storybook for isolated component development
- Auto-port assignment for parallel worktree development
- Makefile or justfile for ergonomic development commands (keep whichever you prefer)
- Version management with release-it (syncs `package.json` → `Cargo.toml`)
- Template drift detection against upstream

## Project Structure

```
template_tauri_nuxt/
├── .github/           # CI/CD workflows and Dependabot config
│   └── workflows/     # ci, build-check, release
├── .scripts/          # Helper scripts for CI and tooling
├── scripts/           # Dev tooling (auto-port, tauri wrapper)
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
make setup        # or: just setup / pnpm run project:init && pnpm lefthook install
```

## Development Commands

### Makefile / justfile

This template ships with both a `Makefile` and a `justfile` — they expose identical targets. Pick whichever runner you prefer and delete the other:

- **make** — available everywhere, no extra install needed
- **[just](https://github.com/casey/just)** — installable via `cargo install just` or `mise use just`

| Target | Description |
| --- | --- |
| `dev` | Run Tauri dev server (auto-assigned port) |
| `build` | Production build |
| `build-debug` | Build with debug symbols |
| `storybook` | Launch Storybook dev server (auto-assigned port) |
| `ports` | Show auto-assigned port block for this worktree |
| `lint` | Run all linters (frontend + Rust) |
| `lint-fix` | Auto-fix lint issues |
| `format` | Format all code |
| `format-check` | Check formatting without changes |
| `test` | Run all tests (frontend + Rust) |
| `ci` | Full CI pipeline (lint, format-check, test, build) |
| `setup` | Install deps and git hooks |
| `storybook-build` | Build Storybook static site |
| `clean` | Remove build artifacts |

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

### Auto-Port System

Each worktree (or checkout directory) gets a deterministic block of 4 ports derived from the absolute path of the project. This allows multiple worktrees of the same project to run simultaneously without port conflicts.

| Service | Env Variable | Offset |
| --- | --- | --- |
| Nuxt dev server | `TAURI_DEV_PORT` | base + 0 |
| Storybook | `STORYBOOK_PORT` | base + 1 |
| MCP server | `MCP_PORT` | base + 2 |
| HTTP server | `HTTP_PORT` | base + 3 |

**How it works**: `scripts/dev-port.sh` hashes the current working directory to pick a port block in the 3000–9996 range. If those ports are busy it scans forward for a free block. The `scripts/tauri-wrapper.mjs` wrapper injects the correct `devUrl` into Tauri's config at launch.

With **mise**, port env vars are set automatically when you enter the directory (see `mise.toml [env]`). Without mise, the wrapper script handles port assignment transparently.

```bash
# View your assigned ports
make ports            # or: just ports / scripts/dev-port.sh --all

# Override manually (all 4 ports shift together)
TAURI_DEV_PORT=5000 make dev    # → Nuxt:5000, Storybook:5001, MCP:5002, HTTP:5003
```

### EditorConfig

Consistent formatting across editors: 2-space indent (4 for Rust, tabs for Makefile), LF line endings, UTF-8.

## Components

Extracted reusable Vue components in `src-nuxt/app/components/`:

| Component | Description |
| --- | --- |
| AppHeader | Application header with branding |
| AppFooter | Footer with links |
| GradientButton | Styled button with gradient effect |
| ResultBanner | Display area for operation results |
| EchoCard | Card for echo/ping functionality |

Each component has a co-located `.stories.ts` file for Storybook.

## Linting & Formatting

| Layer | Frontend | Backend |
| --- | --- | --- |
| Fast lint | oxlint | — |
| Full lint | ESLint + @nuxt/eslint | cargo clippy (-D warnings) |
| Format | Prettier (no semi, single quotes, 100 width) | cargo fmt |

## Testing

| Layer | Tool | Command |
| --- | --- | --- |
| Frontend | Vitest + @nuxt/test-utils | make test-unit |
| Backend | cargo test | make rust-test |
| All | — | make test |

## CI/CD

| Workflow | Trigger | What it does |
| --- | --- | --- |
| ci.yml | Push/PR to main | Frontend lint + typecheck + test; Rust format + clippy + test |
| build-check.yml | Push/PR to main | Full Tauri build verification |
| release.yml | Tag v* | Multi-platform build (macOS aarch64/x86_64, Ubuntu, Windows) via tauri-apps/tauri-action; creates draft GitHub release |

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
- **Dev server**: `localhost:<auto-port>` (see [Auto-Port System](#auto-port-system))
- **Modules**: `@nuxt/ui`, `@nuxt/fonts`, `@nuxt/icon`, `@nuxt/scripts`, `@nuxt/eslint`, `@nuxt/test-utils`
- **Styling**: Tailwind CSS v4 (via `@nuxt/ui`)

## Tauri Configuration

- `withGlobalTauri`: enabled — exposes Tauri API to frontend
- **Default window**: 800x600
- **Build command**: `pnpm generate` (static output)
- **Version**: reads from root `package.json`

## Acknowledgements

Build tooling and developer experience configuration (Lefthook, commitlint, Prettier, oxlint, EditorConfig, Makefile) were inspired by and adapted from [oxide-dock](https://github.com/fridzema/oxide-dock) by [@fridzema](https://github.com/fridzema).

## Additional Resources

- [Tauri Documentation](https://tauri.app/v1/guides/)
- [Nuxt.js Documentation](https://nuxt.com/docs)
- [TypeScript Documentation](https://www.typescriptlang.org/docs/)