# Development Instructions

When you generate new code or update existing code, run `just ci` to verify everything passes
(lint, format, typecheck, test, build). For a quick Rust-only check, use `just rust-lint` and
`just rust-format`.

If there are formatting issues, run `just full-write` to auto-fix them, then re-run `just full-check`.

To see all available commands, run `just --list`.

## Quick Reference

- `just full-check` — Run all checks (lint + format-check + typecheck)
- `just full-write` — Auto-fix all formatting (frontend + Rust)
- `just ci` — Full CI pipeline (lint, format, typecheck, test, build, storybook)
- `just test` — Run all tests (frontend + Rust)
