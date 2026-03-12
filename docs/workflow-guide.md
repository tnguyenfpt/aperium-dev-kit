# Aperium Dev Kit v2 — Workflow Guide

**Version**: 2.0 | **Date**: 2026-03-12 | **Audience**: All Aperium engineering team members

This guide defines the spec-driven development workflow for the Aperium platform.
Specs live in git alongside code. CI handles Confluence synchronization on merge.

---

## 1. Prerequisites & Setup

### 1.1 Plugin Stack (3 Tiers)

#### Tier 1 — Superpowers + Community Plugins (Required)

| Plugin | Purpose |
|--------|---------|
| Superpowers | Skill management, brainstorming, TDD, debugging workflows |
| Context7 | Up-to-date library documentation lookup |
| Playwright | Browser automation and E2E testing |
| Atlassian Rovo MCP | Jira integration for ticket creation and sync |

#### Tier 2 — Aperium Custom Skills (Installed by Setup Script)

| Skill | Location | Purpose |
|-------|----------|---------|
| aperium-spec-generate | `.agents/skills/aperium-spec-generate/` | Generate spec artifacts to `specs/APER-123/` |
| aperium-sync-tasks | `.agents/skills/aperium-sync-tasks/` | Sync tasks.md to Jira sub-tasks |
| aperium-close-spec | `.agents/skills/aperium-close-spec/` | Post-merge: update decisions.md, close Jira, trigger Confluence sync |
| aperium-security | `.agents/skills/aperium-security/` | 6-layer defense + OWASP Agentic Top 10 assessments |
| aperium-mcp-dev | `.agents/skills/aperium-mcp-dev/` | FastMCP server scaffolding with PII/RBAC/test patterns |

#### Tier 3 — MCP Servers (Role-Specific)

| Server | Purpose |
|--------|---------|
| Odoo ERP MCP | ERP data access for business logic features |
| Arena PLM MCP | Product lifecycle management integration |
| Malbek CLM MCP | Contract lifecycle management integration |

### 1.2 Repository Bootstrap

Run the setup script to bootstrap a new repo:

```bash
# Linux/macOS
/path/to/aperium-dev-kit/templates/setup.sh /path/to/your-repo

# Windows (PowerShell)
/path/to/aperium-dev-kit/templates/setup.ps1 -RepoPath C:\path\to\your-repo
```

This creates:
- `AGENTS.md` — canonical agent instructions (single source of truth)
- `CLAUDE.md` — symlink to `AGENTS.md`
- `.github/copilot-instructions.md` — symlink to `../AGENTS.md`
- `.agents/skills/` — directory for custom skills
- `specs/` — directory for feature specs

Only 2 symlinks are needed. Codex and Augment read `AGENTS.md` natively.

### 1.3 Simplified Symlink Strategy

```
AGENTS.md                          ← source of truth
CLAUDE.md -> AGENTS.md             ← symlink (Claude Code)
.github/copilot-instructions.md -> ../AGENTS.md  ← symlink (Copilot)
```

Codex reads `AGENTS.md` directly. Augment reads `AGENTS.md` directly.
No other symlinks are needed.

---

## 2. Context Model (3 Layers)

All agent context is organized into three layers:

| Layer | Location | Scope | Lifetime |
|-------|----------|-------|----------|
| **Layer 1 — Code** | `AGENTS.md` | Repository-wide conventions, architecture, forbidden patterns, security model | Permanent, updated via `--update` |
| **Layer 2 — Feature** | `specs/APER-123/` | Requirements, design, tasks, decisions for a single feature | Feature branch lifetime |
| **Layer 3 — Skill** | `.agents/skills/` | Reusable procedural instructions (spec generation, task sync, security audit) | Kit version lifetime |

Agents read Layer 1 automatically. Layer 2 is loaded when working on a feature branch.
Layer 3 is invoked on demand via slash commands.

---

## 3. Phase 1 — Ideation

**Goal**: Transform a feature idea into a structured Jira ticket.

1. **Brainstorm** with the Superpowers `brainstorming` skill to explore the problem
   space, identify constraints, and surface edge cases.

2. **Create Jira ticket** via Atlassian Rovo MCP:
   ```
   Create a Jira story for: [feature description]
   ```

3. **Review before publishing**: Always review AI-drafted tickets before finalizing.
   Every ticket needs:
   - Clear title (action + subject)
   - User story: "As a [role], I want [goal], so that [benefit]"
   - Acceptance criteria (checkboxes)
   - Priority and estimated complexity

**Output**: Jira ticket (e.g., APER-123) with acceptance criteria.

---

## 4. Phase 2 — Spec-Driven Planning

**Goal**: Produce spec artifacts that define what will be built. Specs are committed
to git, not managed in Confluence.

### Workflow

1. **Generate specs** using the `aperium-spec-generate` skill:
   ```
   /aperium-spec-generate APER-123 user-behavior-analytics
   ```
   This creates `specs/APER-123/` containing:

   | File | Purpose |
   |------|---------|
   | `requirements.md` | User stories, acceptance criteria, edge cases, out-of-scope |
   | `design.md` | Architecture decisions, component interactions, data model, security |
   | `tasks.md` | Numbered task list with complexity (S/M/L), dependencies, test criteria |
   | `decisions.md` | ADR log — records key decisions and their rationale |
   | `review-checklist.md` | Pre-PR quality checklist (tests, security, conventions) |

2. **Review the spec**: Tech lead reviews for completeness before implementation.

3. **Commit specs to feature branch**: Specs travel with the code.
   ```bash
   git add specs/APER-123/
   git commit -m "docs(spec): add APER-123 user-behavior-analytics spec"
   ```

### Agent Selection

| Task | Recommended Agent |
|------|-------------------|
| Complex feature specs | Claude Code + aperium-spec-generate |
| Spec review | Augment Code (multi-file awareness) |
| Quick features | Any agent; spec can be lightweight |

**Output**: `specs/APER-123/` committed to the feature branch.

---

## 5. Phase 3 — Task Decomposition

**Goal**: Break specs into executable tasks and sync them to Jira.

### Workflow

1. **Review tasks.md**: The `aperium-spec-generate` skill produces an initial
   `tasks.md`. Refine it as needed — adjust priorities, add missing tasks, split
   complex tasks.

2. **Sync to Jira** using the `aperium-sync-tasks` skill:
   ```
   /aperium-sync-tasks specs/APER-123/tasks.md APER-123
   ```
   This creates Jira sub-tasks linked to the parent ticket with complexity labels
   and dependency notes.

3. **Intermediate review**: Developer and tech lead review the task breakdown
   before implementation begins.

**Output**: `tasks.md` finalized; Jira sub-tasks created and linked.

---

## 6. Phase 4 — Implementation & Delivery

**Goal**: Execute the task plan, producing tested code ready for merge.

### Workflow

1. **Read local specs**: The agent reads `specs/APER-123/` for full context —
   requirements, design decisions, and task list. No need to fetch from Confluence.

2. **Implement with TDD**: Follow the task plan. Write tests first, then
   implementation. Mark tasks complete in `tasks.md` as you go.

3. **Quality gates** — all checks must pass before PR:
   ```bash
   # Python
   ruff check . && ruff format --check .
   mypy .
   pytest --cov

   # Frontend
   npm run lint && npm run typecheck
   npm run test

   # E2E
   npx playwright test
   ```

4. **Security review**: If the feature touches auth, MCP permissions, or data
   access, run the `aperium-security` skill:
   ```
   /aperium-security --scope src/features/<feature>/
   ```

5. **PR and merge**: Create PR with conventional commit message. Squash-merge
   to develop. Deploy to staging. Run E2E. Deploy to production.

6. **Close the spec**: After merge, run the `aperium-close-spec` skill:
   ```
   /aperium-close-spec APER-123
   ```
   This:
   - Updates `decisions.md` with final implementation notes
   - Transitions the Jira ticket to Done
   - Triggers Confluence sync (or CI handles it automatically)

### CI Automation (Post-Merge)

Two CI workflows handle post-merge sync automatically:

- **`confluence-sync.yml`** — On PR merge, syncs `specs/APER-123/` to Confluence
  so non-engineering stakeholders can read specs in their preferred tool.
- **`close-the-loop.yml`** — On PR merge, updates Jira ticket status and adds
  a comment linking to the merged PR.

If CI fails, use `/aperium-close-spec APER-123` as a manual fallback.

**Output**: Tested code merged; specs synced to Confluence; Jira ticket closed.

---

## 7. AGENTS.md Governance

### FIXED vs CUSTOMIZABLE Sections

The `AGENTS.md` template uses HTML comment markers to distinguish sections:

```markdown
<!-- FIXED:START — managed by aperium-dev-kit -->
## Coding Conventions
...
## Forbidden Patterns
...
## Security Model
...
<!-- FIXED:END -->

<!-- CUSTOMIZABLE:START -->
## Project Identity
...
## Architecture
...
## Build & Test Commands
...
<!-- CUSTOMIZABLE:END -->
```

- **FIXED sections**: Coding conventions, forbidden patterns, security model.
  Changes MUST be made in the dev-kit repo first, then propagated via `--update`.
- **CUSTOMIZABLE sections**: Project identity, architecture, build commands.
  Each repo owns these and can modify them via normal PR review.

### Update Workflow

To pull latest FIXED sections from the dev-kit into a downstream repo:

```bash
# Linux/macOS
/path/to/aperium-dev-kit/templates/setup.sh --update /path/to/your-repo

# Windows (PowerShell)
/path/to/aperium-dev-kit/templates/setup.ps1 -Update -RepoPath C:\path\to\your-repo
```

This replaces FIXED sections while preserving CUSTOMIZABLE sections.

### Change Process

| Section Type | Who Can Change | Where | Review Required |
|-------------|---------------|-------|-----------------|
| FIXED | Dev-kit maintainers | `aperium-dev-kit` repo | Tech lead + 1 reviewer |
| CUSTOMIZABLE | Any developer | Target repo | Tech lead approval |

### Version Tracking

Each repo tracks its template version:
```markdown
<!-- aperium-dev-kit template version: {GIT_SHA} -->
```

---

## 8. CI Integration

### confluence-sync.yml

**Trigger**: PR merged to `develop` or `main` that includes changes in `specs/`.

**What it does**:
1. Runs the `confluence-discover` action to find spec directories with changes
2. Converts Markdown specs to Confluence ADF format
3. Creates or updates Confluence pages under the project's spec space

Confluence is a read-only mirror. Git is the source of truth for specs.

### close-the-loop.yml

**Trigger**: PR merged to `develop` or `main`.

**What it does**:
1. Extracts Jira ticket ID from the branch name (e.g., `feature/APER-123-...`)
2. Transitions the Jira ticket to "Merged" or "Done"
3. Adds a comment to the ticket with the PR link and merge SHA

### Manual Fallback

If either workflow fails, use the skill directly:
```
/aperium-close-spec APER-123
```

---

## 9. Kit Component Reference

### Templates

| Component | Location | Purpose |
|-----------|----------|---------|
| AGENTS.md template | `templates/AGENTS.md.template` | Canonical agent instructions with FIXED/CUSTOMIZABLE sections |
| .gitignore template | `templates/.gitignore.template` | Git tracking rules (includes symlink handling) |
| Setup script (Bash) | `templates/setup.sh` | Bootstrap + update repos (Linux/macOS) |
| Setup script (PS) | `templates/setup.ps1` | Bootstrap + update repos (Windows) |

### Skills

| Skill | Location | Purpose |
|-------|----------|---------|
| aperium-spec-generate | `skills/aperium-spec-generate/` | Generate 5-file spec set to `specs/APER-123/` |
| aperium-sync-tasks | `skills/aperium-sync-tasks/` | Sync tasks.md to Jira sub-tasks |
| aperium-close-spec | `skills/aperium-close-spec/` | Post-merge: update decisions.md, close Jira, sync Confluence |
| aperium-security | `skills/aperium-security/` | 6-layer defense + OWASP Agentic Top 10 assessments |
| aperium-mcp-dev | `skills/aperium-mcp-dev/` | FastMCP server scaffolding with PII/RBAC/test patterns |

### CI Workflows

| Component | Location | Purpose |
|-----------|----------|---------|
| confluence-discover | `.github/actions/confluence-discover/` | Detect changed spec directories |
| confluence-sync.yml | `.github/workflows/confluence-sync.yml` | Sync specs to Confluence on merge |
| close-the-loop.yml | `.github/workflows/close-the-loop.yml` | Update Jira on merge |

### Documentation

| Component | Location | Purpose |
|-----------|----------|---------|
| API endpoint prompt | `docs/prompts/new-api-endpoint.md` | FastAPI endpoint template |
| MCP tool prompt | `docs/prompts/new-mcp-tool.md` | MCP tool creation template |
| React component prompt | `docs/prompts/new-react-component.md` | React component template |
| Debugging prompt | `docs/prompts/debug-template.md` | Structured debugging template |
| Security review prompt | `docs/prompts/security-review.md` | Security review template |
| Workflow guide | `docs/workflow-guide.md` | This file |

---

## 10. Quick-Reference Cheat Sheet

### Setup & Update

```bash
# Bootstrap a new repo
setup.sh /path/to/repo                    # Linux/macOS
setup.ps1 -RepoPath C:\path\to\repo       # Windows

# Update FIXED sections from latest dev-kit
setup.sh --update /path/to/repo            # Linux/macOS
setup.ps1 -Update -RepoPath C:\path\to\repo  # Windows
```

### Spec Workflow

```bash
# Generate specs for a feature
/aperium-spec-generate APER-123 feature-name

# Commit specs
git add specs/APER-123/
git commit -m "docs(spec): add APER-123 feature-name spec"

# Sync tasks to Jira
/aperium-sync-tasks specs/APER-123/tasks.md APER-123

# Close spec after merge
/aperium-close-spec APER-123
```

### Security

```bash
/aperium-security --scope src/features/<feature>/
```

### MCP Server Scaffolding

```bash
/aperium-mcp-dev <service-name>
```

### Phase Summary

```
Phase 1: Ideation           -> Jira ticket with acceptance criteria
Phase 2: Spec-Driven Plan   -> specs/APER-123/ committed to feature branch
Phase 3: Task Decomposition -> tasks.md finalized + Jira sub-tasks
Phase 4: Implementation     -> Tested code + PR + CI syncs to Confluence
```
