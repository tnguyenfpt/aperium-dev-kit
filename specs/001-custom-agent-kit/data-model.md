# Data Model: Custom Agent Kit

**Date**: 2026-03-11
**Feature**: 001-custom-agent-kit

This kit produces file-based artifacts, not database entities. The
"data model" here is the catalog of deliverable file types, their
structure, and relationships.

## Entity Catalog

### 1. AGENTS.md Template

**Purpose**: Canonical agent instruction file, per repository.
**Location**: `templates/AGENTS.md.template`
**Lifecycle**: Created once per repo from template; customized at
bootstrap; updated at sprint retrospectives.

**Structure**:
```markdown
<!-- CUSTOMIZABLE: Edit for your repository -->
## Project Identity
[repo-specific: name, purpose, users]

## Architecture Overview
[repo-specific: services, connections, data flow]

<!-- FIXED: Do not modify — managed by aperium-dev-kit -->
## Coding Conventions
[shared: Python, TypeScript, MCP conventions]

## Forbidden Patterns
[shared: banned patterns list]

<!-- CUSTOMIZABLE: Edit for your repository -->
## Build & Test Commands
[repo-specific: exact commands for this repo]

<!-- FIXED: Do not modify — managed by aperium-dev-kit -->
## Security Requirements
[shared: Zero Trust, RBAC, PII, audit logging rules]
```

**Validation rules**:
- Total length: 80-100 lines (warn if exceeded)
- FIXED sections MUST match dev-kit source verbatim
- CUSTOMIZABLE sections MUST NOT be empty

**Relationships**:
- Symlinked to: CLAUDE.md, CODEX.md, .github/copilot-instructions.md, .cursor/rules/main.mdc
- Referenced by: all skills, all prompt templates

### 2. Skill Package

**Purpose**: Encodes team-specific workflow knowledge.
**Location**: `skills/{skill-name}/`
**Lifecycle**: Created once; iterated as team discovers new patterns;
versioned with the dev-kit repo.

**Structure**:
```
skills/{skill-name}/
├── SKILL.md             # Instructions (YAML frontmatter + Markdown body)
└── references/          # Supporting context files
    ├── {context-file-1}.md
    └── {context-file-2}.md
```

**SKILL.md format**:
```yaml
---
name: aperium-{skill-name}
description: One-line description of what the skill does
trigger: Optional trigger conditions
---

# {Skill Title}

## Purpose
[What this skill accomplishes]

## Prerequisites
[What must be in place before using this skill]

## Workflow
[Step-by-step instructions the AI agent follows]

## Output
[What the skill produces and where it goes]
```

**Instances** (3 skills in this kit):

| Skill | Reference Files |
|-------|----------------|
| aperium-spec | architecture-context.md, security-template.md, spec-sections.md |
| aperium-mcp-dev | scaffold-structure.md, middleware-patterns.md, test-patterns.md |
| aperium-security | 6-layer-checklist.md, owasp-agentic-top10.md, report-template.md |

**Validation rules**:
- SKILL.md MUST have valid YAML frontmatter
- SKILL.md MUST contain ## Workflow section
- References MUST be Markdown only (no binary files)

**Relationships**:
- Installed into: target repos (via setup script or manual copy)
- References: AGENTS.md (for convention lookup, not duplication)

### 3. Prompt Template

**Purpose**: Single-use starting point for common tasks.
**Location**: `docs/prompts/{task-name}.md`
**Lifecycle**: Created once; expanded when team discovers new
effective prompts; updated when conventions change.

**Structure**:
```markdown
# Prompt: {Task Name}

## Purpose
[What this prompt helps accomplish]

## Context
See AGENTS.md for project conventions and forbidden patterns.

## Prompt
[The actual prompt template with {PLACEHOLDER} variables]

## Expected Output
[Description of what good output looks like]

## Example
[One concrete example of using this prompt and its output]
```

**Instances** (5 templates):
- new-api-endpoint.md
- new-mcp-tool.md
- new-react-component.md
- debug-template.md
- security-review.md

**Validation rules**:
- MUST contain ## Prompt section
- MUST reference AGENTS.md (not duplicate conventions)
- Placeholders use `{VARIABLE_NAME}` format

**Relationships**:
- References: AGENTS.md (for convention context)
- Independent of: skills (different purpose)

### 4. Setup Script

**Purpose**: Bootstrap a new repo with the kit.
**Location**: `templates/setup.sh` + `templates/setup.ps1`
**Lifecycle**: Run once per repo; re-run to update symlinks or
reinstall skills.

**Inputs**:
- Repository root path (auto-detected)
- AGENTS.md template (from dev-kit repo)

**Outputs**:
- AGENTS.md (copied from template, ready for customization)
- Symlinks (CLAUDE.md, CODEX.md, .github/copilot-instructions.md, .cursor/rules/main.mdc)
- .gitignore updates
- Skills installed (copied to target repo)

**Validation rules**:
- MUST detect existing config files and warn before overwriting
- MUST work on Linux, macOS, and Windows
- MUST report success/failure for each step

### 5. Workflow Guide

**Purpose**: Human-readable guide to the MCP-DLC lifecycle.
**Location**: `docs/workflow-guide.md`
**Lifecycle**: Created once; updated when workflow changes.

**Structure**: See research.md R7 for section outline.

**Validation rules**:
- MUST cover all 4 MCP-DLC phases
- MUST include prerequisites/plugin installation
- MUST include AGENTS.md governance section

**Relationships**:
- References: all skills (by name, with usage instructions)
- References: AGENTS.md template (for governance rules)
- References: prompt library (as supplementary resources)

### 6. Security Assessment Report (output artifact)

**Purpose**: Structured assessment produced by aperium-security skill.
**Location**: Generated in target repo (e.g., `docs/security/assessment-{date}.md`)
**Lifecycle**: Generated per assessment run; retained for audit trail.

**Structure**:
```markdown
# Security Assessment: {Feature Name}

**Date**: {DATE}
**Assessor**: {AGENT + DEVELOPER}
**Scope**: {FILES/FEATURES ASSESSED}

## 6-Layer Defense Model

| Layer | Status | Evidence | Remediation |
|-------|--------|----------|-------------|
| 1. Input Validation | PASS/FAIL/WARN | ... | ... |
| ... | ... | ... | ... |

## OWASP Agentic Top 10

| # | Check | Status | Evidence | Remediation |
|---|-------|--------|----------|-------------|
| 1 | Prompt Injection | PASS/FAIL/WARN | ... | ... |
| ... | ... | ... | ... | ... |

## Summary
[Overall assessment, critical findings, recommended actions]
```
