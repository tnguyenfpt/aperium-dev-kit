# Contract: Skill Package Format

**Version**: 1.0
**Date**: 2026-03-11

## Overview

Defines the file structure and SKILL.md format for all Aperium
custom skills.

## Directory Structure

```
skills/{skill-name}/
├── SKILL.md             # Required: main instruction file
└── references/          # Optional: supporting context files
    ├── *.md             # Markdown context files only
    └── ...
```

## SKILL.md Format

### YAML Frontmatter (required)

```yaml
---
name: aperium-{skill-name}
description: One-line description (max 120 chars)
trigger: Optional conditions when this skill should activate
version: Semantic version (e.g., 1.0.0)
---
```

### Required Sections

| Section | Purpose |
|---------|---------|
| `## Purpose` | What the skill accomplishes (1-3 sentences) |
| `## Prerequisites` | What must be in place before use |
| `## Workflow` | Step-by-step instructions for the AI agent |
| `## Output` | What the skill produces and where files go |

### Optional Sections

| Section | Purpose |
|---------|---------|
| `## Examples` | Concrete usage examples |
| `## Troubleshooting` | Common issues and solutions |
| `## References` | Links to reference files in references/ |

## Constraints

- SKILL.md MUST be self-contained Markdown (no external URLs required
  at runtime)
- References MUST be Markdown files (no binary, no code files)
- Skills MUST NOT duplicate AGENTS.md conventions — reference them
  instead: "See AGENTS.md Section 3: Coding Conventions"
- Skills MUST produce output that is agent-agnostic (consumable
  Markdown, not tool-specific formats)
- Total SKILL.md length: recommended under 500 lines

## Installation

Skills are installed by copying the skill directory into the target
repo's `.agent/skills/` directory (or equivalent for the AI agent
platform). The setup script handles this.

## Aperium Skills Inventory

| Skill Name | Trigger | Primary Output |
|-----------|---------|----------------|
| aperium-spec | Developer invokes for new feature spec | `docs/specs/{feature}/spec.md` |
| aperium-mcp-dev | Developer invokes for new MCP server | `mcp-{service}/` scaffold |
| aperium-security | Developer invokes for security review | `docs/security/assessment-{date}.md` |
