Fetch the latest state of the upstream template repository and compare it against this project.

If the project is already up to date and there are no meaningful changes to apply, do nothing and exit.
Do not create a branch, commit, or PR.

Apply any new or changed files from the template, respecting project-specific overrides.
Pay special attention to:
- Tooling config: justfile, Makefile, lefthook.yml, mise.toml, .editorconfig, .prettierrc.yml
- CI workflows: .github/workflows/
- Rust config: src-tauri/rustfmt.toml, src-tauri/Cargo.toml (dependency versions only, not package name/version)
- Scripts: scripts/, .scripts/
- Release config: .release-it.json, cliff.toml, commitlint.config.ts

Do NOT overwrite:
- src-tauri/src/ (project-specific Rust code)
- src-nuxt/app/ or src-nuxt/components/ (project-specific frontend code)
- package.json name/version fields
- src-tauri/Cargo.toml name/version/description fields
- src-tauri/tauri.conf.json identifier/productName fields
- README.md, docs/

After making changes, run the quality gate:

```
just full-check
```

If there are formatting issues, fix them with:

```
just full-write
```

Then run `just full-check` again to confirm everything passes.

When finished, create a branch named `chore/update-from-template` and a single commit with the following format:

```
chore: update project from upstream template

Performed the following:
- <list each change made>

Did not bring over the following because of project-specific overrides:
- <list anything intentionally skipped, or "None">
```

Then push the branch and create a pull request with:
- Title: `chore: update from upstream template`
- Body summarizing what was changed and what was intentionally skipped
