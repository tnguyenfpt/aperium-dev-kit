# Contract: AGENTS.md Template Format

**Version**: 1.0
**Date**: 2026-03-11

## Overview

Defines the structure and rules for the AGENTS.md template that all
Aperium repositories bootstrap from.

## Template Sections

The template uses HTML comments to mark sections as CUSTOMIZABLE
(repo-specific) or FIXED (shared across all repos).

### Required Sections (in order)

| # | Section | Type | Lines | Content |
|---|---------|------|-------|---------|
| 1 | Project Identity | CUSTOMIZABLE | 3-5 | Repo name, purpose, users |
| 2 | Architecture Overview | CUSTOMIZABLE | 10-15 | Services, connections, data flow |
| 3 | Coding Conventions | FIXED | 20-30 | Python, TypeScript, MCP rules |
| 4 | Forbidden Patterns | FIXED | 5-10 | Banned patterns list |
| 5 | Build & Test Commands | CUSTOMIZABLE | 5-10 | Exact CLI commands for this repo |
| 6 | Security Requirements | FIXED | 10-15 | Zero Trust, RBAC, PII, audit |

### Marker Format

```markdown
<!-- CUSTOMIZABLE: Edit for your repository -->
## Section Name
[content]

<!-- FIXED: Do not modify — managed by aperium-dev-kit -->
## Section Name
[content]
```

## Constraints

- **Total length**: 80-100 lines (setup script warns if exceeded)
- **FIXED sections**: MUST match the dev-kit source verbatim; setup
  script can validate this with a diff check
- **CUSTOMIZABLE sections**: MUST NOT be left empty after bootstrap;
  setup script prompts for required values
- **No agent-specific syntax**: Content must be readable by Claude,
  Copilot, Cursor, Codex, and Augment (plain Markdown only)

## Symlink Targets

When AGENTS.md is created, the setup script creates these symlinks:

| Target File | Relative Path from AGENTS.md |
|-------------|------------------------------|
| CLAUDE.md | Same directory |
| CODEX.md | Same directory |
| .github/copilot-instructions.md | .github/ subdirectory |
| .cursor/rules/main.mdc | .cursor/rules/ subdirectory |

## Versioning

The AGENTS.md template in the dev-kit repo is versioned via Git.
Downstream repos track which template version they bootstrapped from
via a comment at the bottom:

```markdown
<!-- aperium-dev-kit template version: {GIT_SHA} -->
```
