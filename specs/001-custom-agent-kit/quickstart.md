# Quickstart: Custom Agent Kit

**Date**: 2026-03-11
**Feature**: 001-custom-agent-kit

## What You Get

After setup, a target repository will have:

- `AGENTS.md` — single source of truth for all AI agent instructions
- Symlinks — CLAUDE.md, CODEX.md, .github/copilot-instructions.md,
  .cursor/rules/main.mdc all pointing to AGENTS.md
- 3 custom skills — aperium-spec, aperium-mcp-dev, aperium-security
- MCP-DLC workflow guide — 4-phase development lifecycle reference
- 5 prompt templates — starter library for common tasks

## Bootstrap a New Repo (5 minutes)

### Step 1: Clone the dev-kit

```bash
git clone <aperium-dev-kit-repo-url> /tmp/aperium-dev-kit
```

### Step 2: Run the setup script

**Linux/macOS**:
```bash
/tmp/aperium-dev-kit/templates/setup.sh /path/to/your-repo
```

**Windows (PowerShell)**:
```powershell
/tmp/aperium-dev-kit/templates/setup.ps1 -RepoPath C:\path\to\your-repo
```

The script will:
1. Copy `AGENTS.md.template` to your repo as `AGENTS.md`
2. Prompt you to fill in CUSTOMIZABLE sections (project identity,
   architecture, build commands)
3. Create symlinks for all agent-specific config files
4. Update `.gitignore` to track AGENTS.md and handle symlinks
5. Copy skills to `.agent/skills/` (or instruct on installation)
6. Copy prompt templates to `docs/prompts/`

### Step 3: Customize AGENTS.md

Open `AGENTS.md` and fill in the sections marked
`<!-- CUSTOMIZABLE -->`:

- **Project Identity**: Your repo name, what it does, who uses it
- **Architecture Overview**: Services, data stores, integrations
- **Build & Test Commands**: Exact CLI commands for your repo

Leave `<!-- FIXED -->` sections unchanged.

### Step 4: Verify

```bash
# Check symlinks exist and point to AGENTS.md
ls -la CLAUDE.md CODEX.md .github/copilot-instructions.md
ls -la .cursor/rules/main.mdc

# Start any AI agent and verify it reads the conventions
# Claude Code: open a session and ask "what are the coding conventions?"
# Copilot: check that suggestions follow the patterns in AGENTS.md
```

## Using the Kit

### Generate a Feature Spec

```
/aperium-spec user-behavior-analytics dashboard
```

Output: `docs/specs/user-behavior-analytics/spec.md` with
Aperium architecture context and security section pre-filled.

### Scaffold an MCP Server

```
/aperium-mcp-dev arena-plm
```

Output: `mcp-arena-plm/` directory with FastMCP server, PII
middleware, RBAC checks, tests, and Docker config.

### Run a Security Assessment

```
/aperium-security --scope mcp-arena-plm/
```

Output: `docs/security/assessment-2026-03-11.md` with 6-layer
defense + OWASP Agentic Top 10 checklist results.

### Use a Prompt Template

Open `docs/prompts/new-api-endpoint.md`, fill in the placeholders,
and paste into your AI agent of choice.

## Install Plugins (Prerequisites)

See `docs/workflow-guide.md` Prerequisites section for the 3-tier
plugin installation guide:

- **Tier 1** (all members): Superpowers, Speckit, Context7, Frontend
  Design, Playwright
- **Tier 2** (role-specific): Atlassian Rovo MCP, Commit Commands,
  Feature Dev
- **Tier 3** (custom): aperium-spec, aperium-mcp-dev,
  aperium-security (installed by setup script)

## Updating the Kit

When the dev-kit repo updates shared content (FIXED sections,
skills, prompts):

1. Pull latest dev-kit
2. Re-run setup script with `--update` flag
3. Script diffs FIXED sections and updates them in your AGENTS.md
4. Script copies updated skills and prompts
5. CUSTOMIZABLE sections are preserved
