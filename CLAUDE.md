# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## What This Repository Is

The **Aperium Dev Kit** — a bootstrapping toolkit that sets up cross-agent consistency for Aperium platform repositories. It contains:

- **Setup scripts** (`setup.sh`, `setup.ps1`) — Bootstrap any repo with AGENTS.md, symlinks, specs/, and .gitignore
- **Templates** (`templates/`) — AGENTS.md template, .gitignore template, GitHub Actions CI templates
- **Skills** (`skills/`) — Reusable agent skills for spec generation, Jira sync, security review
- **Docs** (`docs/`) — Workflow guide, prompt templates, cross-platform test guide
- **Reference docs** (`docs/`) — v3 process and cross-agent consistency documents

## Repository Structure

```
aperium-dev-kit/
├── setup.sh / setup.ps1          # Run these to bootstrap a target repo
├── templates/
│   ├── AGENTS.md.template        # Source template for AGENTS.md
│   ├── .gitignore.template       # Full .gitignore for new repos
│   ├── setup.sh / setup.ps1      # Original scripts (templates/ copies)
│   └── github-actions/           # CI workflow templates
├── skills/                       # Agent skills (copied to target on --update)
│   ├── aperium-spec-generate/    # Generate specs to specs/APER-123/
│   ├── aperium-sync-tasks/       # Sync tasks to Jira
│   ├── aperium-close-spec/       # Post-merge spec closure
│   ├── aperium-security/         # Security audit (6-layer defense)
│   └── aperium-mcp-dev/          # MCP server scaffolding
├── docs/
│   ├── workflow-guide.md         # Full v2 development workflow
│   ├── cross-platform-test-guide.md  # Testing across AI tools
│   └── prompts/                  # Reusable prompt templates
└── specs/                        # Specs for this repo's own features
```

## Key Concepts

- **AGENTS.md** is the single source of truth for code conventions. Only 2 symlinks: `CLAUDE.md` and `.github/copilot-instructions.md`. Codex, Augment, and Cursor read AGENTS.md natively.
- **Specs-in-git**: Specs live in `specs/APER-123/` committed alongside code. Confluence is a CI-synced presentation layer.
- **`.agents/skills/`**: Industry-standard skills directory, natively supported by Augment and Codex.
- **FIXED vs CUSTOMIZABLE**: AGENTS.md template uses HTML comment markers. FIXED sections are managed by the dev kit; CUSTOMIZABLE sections are per-repo.

## Working in This Repo

- This is a documentation/template repo — no build system, no tests to run
- Templates use `{PLACEHOLDER}` syntax for values filled during bootstrap
- Setup scripts must work on Linux, macOS, and Windows (Git Bash + PowerShell)
- The `--update` flag refreshes FIXED sections and copies skills/prompts to target repos
- `setup.sh` syntax check: `bash -n setup.sh`
- `setup.ps1` syntax check: `powershell.exe -NoProfile -Command "Get-Content setup.ps1 | Out-Null; Write-Host PASS"`

## Git Conventions

- Conventional commits: `feat(scope): description`, `fix(scope):`, `docs(scope):`
- Branch naming: `feature/<id>-<description>` or `fix/<id>-<description>`
