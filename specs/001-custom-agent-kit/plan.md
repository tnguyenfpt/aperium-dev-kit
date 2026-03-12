# Implementation Plan: Custom Agent Kit

**Branch**: `001-custom-agent-kit` | **Date**: 2026-03-11 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-custom-agent-kit/spec.md`

## Summary

Build a reusable developer toolkit that ensures cross-agent consistency
across all Aperium repositories. The kit provides: (1) an AGENTS.md
template with symlink setup, (2) three custom skills (aperium-spec,
aperium-mcp-dev, aperium-security), (3) an MCP-DLC workflow guide with
governance and plugin onboarding, and (4) a starter prompt library. The
kit lives in this dev-kit repo as the central source; individual repos
bootstrap from it via a setup script.

## Technical Context

**Language/Version**: Bash + PowerShell (cross-platform scripts), Markdown (all documents and skills)
**Primary Dependencies**: Git (symlinks), Claude Code skill system (SKILL.md format), Speckit (spec compatibility)
**Storage**: N/A (file-based artifacts only — no database)
**Testing**: Manual validation (skill output review), script smoke tests (symlink creation, cross-platform)
**Target Platform**: Linux, macOS, Windows (all developer workstations)
**Project Type**: Developer tooling kit / documentation
**Performance Goals**: N/A (human-consumed artifacts)
**Constraints**: Skills MUST be Markdown-only (no compiled dependencies); AGENTS.md MUST stay under 100 lines
**Scale/Scope**: ~10 developers, 5-8 Aperium repositories

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Spec-Driven Development | ✅ PASS | Spec + clarifications complete; plan in progress |
| II. Security-First | ✅ PASS | The aperium-security skill implements this; kit itself handles no user data |
| III. Type Safety | ⚪ N/A | No application code — only scripts and Markdown |
| IV. Async-First | ⚪ N/A | No Python backend code in this kit |
| V. Cross-Agent Consistency | ✅ PASS | This IS the feature — kit implements this principle directly |
| VI. Test Coverage | ✅ PASS | Script smoke tests for setup; skill validation via manual review + acceptance scenarios |
| VII. Forbidden Patterns | ⚪ N/A | No application code — scripts are utility only |
| VIII. Simplicity | ✅ PASS | Kit is Markdown + shell scripts; no compiled dependencies; no unnecessary abstractions |

**Gate result**: PASS — no violations. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/001-custom-agent-kit/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (entity/file catalog)
├── quickstart.md        # Phase 1 output (bootstrap guide)
├── contracts/           # Phase 1 output (file format specs)
│   ├── agents-md-template-format.md
│   ├── skill-format.md
│   └── prompt-template-format.md
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
# Kit deliverables (this repo = central source)
templates/
├── AGENTS.md.template       # AGENTS.md with customizable/fixed sections
├── .gitignore.template      # Git tracking rules for symlinks
└── setup.sh                 # Cross-platform bootstrap script (+ setup.ps1)

skills/
├── aperium-spec/
│   ├── SKILL.md             # Spec generation skill instructions
│   └── references/          # Aperium architecture context, templates
├── aperium-mcp-dev/
│   ├── SKILL.md             # MCP server scaffolding instructions
│   └── references/          # FastMCP patterns, middleware templates
└── aperium-security/
    ├── SKILL.md             # Security assessment instructions
    └── references/          # 6-layer checklist, OWASP Agentic Top 10

docs/
├── workflow-guide.md        # MCP-DLC 4-phase workflow guide
│                            # (includes governance + plugin onboarding)
└── prompts/
    ├── new-api-endpoint.md
    ├── new-mcp-tool.md
    ├── new-react-component.md
    ├── debug-template.md
    └── security-review.md
```

**Structure Decision**: Flat kit layout at repo root. No src/tests
hierarchy because deliverables are documentation and scripts, not
compiled code. The `templates/`, `skills/`, and `docs/` directories
map directly to the three deliverable categories.

## Complexity Tracking

> No violations — table not needed.
