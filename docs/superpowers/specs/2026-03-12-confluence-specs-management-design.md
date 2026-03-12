# Specs Management v2 — Design Document

**Date**: 2026-03-12
**Author**: Aperium Engineering
**Status**: Draft (rev 2 — incorporates team review feedback)
**Feature**: Standardize spec management across agents + CI sync to Confluence

---

## Summary

The Aperium Dev Kit v1 stores specs loosely in `docs/specs/`. V2 standardizes specs in a tracked `specs/` directory at the repo root, committed alongside code. Agents read/write specs using native file tools (fast, reliable). Confluence serves as a **presentation layer**, synced automatically via CI pipeline on PR merge. This eliminates MCP dependency during the development loop.

## Key Design Decisions

| Question | Decision | Rationale |
|----------|----------|-----------|
| Spec source of truth | Git (`specs/APER-123/`) | Agents use native file tools; faster and more reliable than MCP during dev loop |
| Confluence role | Presentation layer, synced by CI | Stakeholders view specs in Confluence; agents never need to fetch from it |
| Symlink strategy | 2 symlinks only (CLAUDE.md, copilot-instructions.md) | Codex and Augment read AGENTS.md natively — no symlinks needed |
| Skills directory | `.agents/skills/` | Industry standard; native support in Augment and Codex |
| Jira sync | Agent skill (aperium-sync-tasks) | Developer reviews draft before creating tickets |
| GitHub Action | Template + manual fallback skill | Teams not yet on CI can use `/aperium:close-spec` manually |

## Architecture Change (v1 vs v2)

```
v1 (current):
  AGENTS.md → symlinked to CLAUDE.md, CODEX.md, copilot-instructions.md, main.mdc
  docs/specs/ → specs loosely stored
  .agent/skills/ → custom skills

v2 (proposed):
  AGENTS.md → symlinked to CLAUDE.md, copilot-instructions.md (only 2)
  specs/APER-123/ → standardized spec structure, committed to git
  .agents/skills/ → industry-standard skills directory
  CI pipeline → syncs specs/ to Confluence on PR merge
```

## Delivery Strategy: Layered

Three ordered layers on the same branch. Each is independently usable.

---

## Layer 1: Kit v2 Foundation (~12 tasks)

### 1.1 AGENTS.md Template Update

**Current**: 6 sections (3 CUSTOMIZABLE, 3 FIXED), 95 lines.
**Changes**:
- Add a 7th section — "Context Model" — as a new FIXED section
- Update any references from `.agent/skills/` to `.agents/skills/`

New section content:

```markdown
## Context Model

<!-- FIXED: Do not modify -- managed by aperium-dev-kit -->

This repository uses a split context model:

- **Layer 1 -- Code Context** (this file, `AGENTS.md`): Architecture, conventions,
  build commands. Lives in Git. Changes rarely.
- **Layer 2 -- Feature Context** (`specs/`): Requirements, design, tasks, decisions.
  Committed alongside code. Synced to Confluence via CI.
- **Layer 3 -- Skill Context** (`.agents/skills/`): Reusable workflow instructions.
  Lives in Git. Grows over time.
```

Target line count: ~100 lines (slight increase from 95).

### 1.2 Setup Scripts Update

Both `setup.sh` and `setup.ps1`:

- **Reduce symlinks from 4 to 2**:
  - `CLAUDE.md` -> `AGENTS.md`
  - `.github/copilot-instructions.md` -> `../AGENTS.md`
  - ~~CODEX.md~~ (removed — Codex reads AGENTS.md natively)
  - ~~.cursor/rules/main.mdc~~ (removed — Augment reads AGENTS.md natively)
- Rename `.agent/skills/` to `.agents/skills/` in all copy/update logic. Specifically:
  - `setup.sh` line ~232: change `SKILLS_DEST="${TARGET_REPO}/.agent/skills"` to `.agents/skills`
  - `setup.ps1`: equivalent `$SkillsDest` variable update
- Create `specs/` directory during bootstrap (tracked in git)
- Update .gitignore block (remove CODEX.md and .cursor/rules/main.mdc entries)
- **Update the `--update` mode copy-refresh loop**: currently iterates over 4 files (CLAUDE.md, CODEX.md, copilot-instructions.md, main.mdc); reduce to 2 files (CLAUDE.md, copilot-instructions.md)

Note: The `--update` flag already exists in both scripts (built in v1). The v2 changes are additive — the existing FIXED-section refresh and skills/prompts copy logic handles propagation.

### 1.3 .gitignore Template Update

Remove from gitignore (these no longer exist):
- `CODEX.md`
- `.cursor/rules/main.mdc`

Keep gitignored:
- `CLAUDE.md` (symlink)
- `.github/copilot-instructions.md` (symlink)

### 1.4 Existing Skills Update

**aperium-spec** (to be replaced in Layer 2, but updated here for interim use):
- Change output path from `docs/specs/{feature}/` to `specs/{feature}/`
- Note: The v1 skill generates a single `spec.md` file. The interim update only changes the output directory. The full multi-file spec structure (requirements.md, design.md, tasks.md, decisions.md, review-checklist.md) is implemented in the replacement `aperium-spec-generate` skill in Layer 2.

**aperium-mcp-dev**:
- Update skill directory reference from `.agent/skills/` to `.agents/skills/`

**aperium-security**:
- Update output note: "Assessment report written to `specs/{feature}/security-assessment.md`"

### 1.5 Workflow Guide Rewrite

Full rewrite of `docs/workflow-guide.md` to reflect:

- Specs in git as source of truth (`specs/APER-123/`)
- Confluence as presentation layer (CI-synced, not agent-accessed)
- Split context model (3 layers)
- Simplified symlink strategy (AGENTS.md + 2 symlinks only)
- `.agents/skills/` as standard skills directory
- Updated Phase 2 (spec generation → `specs/`) and Phase 4 (read local spec → implement)
- Close-the-loop CI description + manual fallback
- Updated cheat sheet with new commands
- Updated Kit Component Reference table

### 1.6 Prompt Templates Update

All 5 prompt templates in `docs/prompts/`:
- Change spec references from `docs/specs/` to `specs/`
- Remove any Confluence fetch references
- Update Context note: "Specs live in `specs/APER-123/` and are committed to git"

### 1.7 Spec Directory Convention

Standardized structure for every feature:

```
specs/
  APER-123/
    requirements.md
    design.md
    tasks.md
    decisions.md          (NEW — captures design decisions and trade-offs)
    review-checklist.md
  APER-456/
    ...
```

The `specs/` directory is tracked in git. Specs are committed on the feature branch alongside code.

---

## Layer 2: Agent Skill Suite (~10 tasks)

### 2.1 `aperium-spec-generate`

**Replaces**: `skills/aperium-spec/` (old skill removed, references migrated)

**Location**: `skills/aperium-spec-generate/`

**SKILL.md trigger**: "Use when creating a new feature specification for an Aperium service"

**Workflow**:
1. Accept Epic key (APER-123) + feature description
2. Optionally fetch Jira ticket details via Atlassian MCP for context (skip if MCP unavailable)
3. Load architecture-context.md, security-template.md, spec-sections.md
4. Generate spec interactively (Socratic brainstorming if Superpowers available)
5. Write each section to `specs/APER-123/`: requirements.md, design.md, tasks.md, decisions.md, review-checklist.md
6. Report file paths + suggest next steps ("commit specs, then start implementation")

**References** (migrated from aperium-spec + new):
- `references/architecture-context.md` (migrated)
- `references/security-template.md` (migrated)
- `references/spec-sections.md` (migrated, updated with decisions.md and review-checklist.md templates)

### 2.2 `aperium-sync-tasks`

**Location**: `skills/aperium-sync-tasks/`

**SKILL.md trigger**: "Use when task breakdown is ready in specs/ and needs to be synced to Jira as child tickets"

**Workflow**:
1. Accept Epic key (APER-123)
2. Read `specs/APER-123/tasks.md` (local file — fast, no MCP needed)
3. Parse numbered tasks with complexity, dependencies, test criteria
4. Generate Markdown draft of Jira tickets locally — **intermediate checkpoint**: present to developer for review
5. On developer approval: create child tickets under Epic via Jira MCP
6. Update `specs/APER-123/tasks.md` with Jira ticket IDs for traceability
7. Report created ticket IDs + links

**MCP error handling**: If Jira MCP fails at step 5, save the draft to `specs/APER-123/jira-draft.md` for manual creation.

**References**:
- `references/jira-ticket-format.md` (ticket template with fields mapping)

### 2.3 `aperium-close-spec`

**Location**: `skills/aperium-close-spec/`

**SKILL.md trigger**: "Use when a feature is merged and the spec needs implementation notes and archival"

**Workflow**:
1. Accept Epic key (APER-123) + PR link + optional deviation notes
2. Create/update `specs/APER-123/decisions.md` with: implementation deviations, trade-offs, lessons learned
3. Check if all Jira child tickets under Epic are Done (via Jira MCP; if MCP fails, skip check and warn)
4. If all done: add `status: completed` header to `specs/APER-123/requirements.md`
5. If not all done: report which tickets remain open
6. Commit updated spec files
7. Report completion status — note that CI will sync to Confluence on merge

**References**:
- `references/implementation-notes-template.md` (template for decisions.md additions)

### 2.4 Skill Directory Structure (Final)

```
skills/
  aperium-spec-generate/        (NEW - replaces aperium-spec)
    SKILL.md
    references/
      architecture-context.md   (migrated)
      security-template.md      (migrated)
      spec-sections.md          (migrated + updated)
  aperium-sync-tasks/           (NEW)
    SKILL.md
    references/
      jira-ticket-format.md
  aperium-close-spec/           (NEW)
    SKILL.md
    references/
      implementation-notes-template.md
  aperium-mcp-dev/              (existing, updated)
    SKILL.md
    references/ (unchanged)
  aperium-security/             (existing, updated)
    SKILL.md
    references/ (unchanged)
```

Note: `aperium-fetch-spec` is eliminated — specs live in git, no fetching needed.
Note: `aperium-confluence` shared library is eliminated — Confluence sync is handled by CI, not agent skills.
Note: Paths above are dev-kit source locations (`skills/`). In target repos, skills are copied to `.agents/skills/` by the setup script.

---

## Layer 3: CI Automation (~8 tasks)

### 3.1 Confluence Sync Action

**File**: `templates/github-actions/confluence-sync.yml`

**Purpose**: Sync `specs/` directory to Confluence as formatted pages on PR merge.

**Design**:
- Uses `workflow_call` for reusable workflow pattern
- Trigger: on PR merge to `develop` or `main`
- Inputs: `confluence_space_key`, `jira_project_key`
- Secrets: `ATLASSIAN_API_TOKEN`, `ATLASSIAN_EMAIL`, `ATLASSIAN_BASE_URL`

**Why REST instead of MCP**: MCP tools are not available in CI environments — the Action uses Atlassian REST API directly via `curl` with API token auth.

**Steps**:
1. Extract ticket ID from branch name regex: `(feat|feature|fix|refactor|test|docs|chore|perf|security)/([A-Z]+-\d+)-.*` → capture group 2
2. Detect which `specs/APER-123/` files changed in the PR (via `git diff`)
3. For each changed spec file:
   a. Auto-discover/create Confluence space structure (Active Specs → Epic page → child pages)
   b. Convert Markdown to Confluence storage format (XHTML)
   c. Create or update the corresponding Confluence child page
4. If spec has `status: completed` header → move Epic page from "Active Specs" to "Completed Specs"

### 3.2 Close-the-Loop Action

**File**: `templates/github-actions/close-the-loop.yml`

**Purpose**: Transition Jira tickets and add implementation notes on PR merge.

**Steps**:
1. Extract ticket ID from branch name (same regex as 3.1)
2. Fetch PR metadata (link, merge SHA, author) via `gh` CLI
3. Call Jira REST API to transition ticket to "Done"
4. Check if all sibling tickets under Epic are Done → if yes, transition Epic
5. Add PR comment with summary of actions taken

**Error handling**: Each step is independent — Jira failure doesn't block other steps. Failures are reported as PR comments, not pipeline failures.

### 3.3 Confluence Space Auto-Discovery

Implemented as a reusable composite action (`templates/github-actions/confluence-discover/action.yml`) called by both CI workflows. Outputs: `space_key`, `active_specs_page_id`, `completed_specs_page_id`, `epic_page_id`.

Shared logic used by both CI actions:

1. Search for Confluence space with name containing "Aperium Specs" (REST API)
2. If found: use that space key
3. If not found: fail with clear error message (CI should not create spaces — that's a one-time admin setup)
4. Find "Active Specs" parent page
5. If not found: create it
6. Find "Completed Specs" parent page
7. If not found: create it
8. Find Epic page (APER-123) under Active Specs
9. If not found: create with title "APER-123: {Epic summary from git commit}"

### 3.4 README Documentation

**File**: `templates/github-actions/README.md`

Contents:
- Installation instructions (copy to `.github/workflows/`)
- Required secrets setup (Atlassian API token, email, base URL)
- Confluence space setup (one-time admin step)
- Customization (branch naming pattern, Jira project key, Confluence space key)
- Markdown-to-Confluence conversion notes
- Troubleshooting (expired tokens, wrong space key, permission errors)
- Manual fallback: reference to `/aperium:close-spec` skill

Note: GitHub Action templates are NOT auto-copied by `setup.sh`. They live in the dev-kit's `templates/github-actions/` directory and must be manually copied to each repo's `.github/workflows/`. This is intentional — CI configuration requires per-repo customization (space keys, project keys, secrets).

---

## Migration Path (v1 → v2)

For repos already using the v1 kit:

1. Run `setup.sh --update` (Layer 1 changes propagate via FIXED section refresh)
2. Symlinks for CODEX.md and .cursor/rules/main.mdc become orphaned — developer should remove them manually (documented in workflow guide)
   - **Note on CLAUDE.md**: Some repos may have a standalone CLAUDE.md with custom content (not a symlink). The setup script's existing conflict detection prompts before overwriting. Developers with custom CLAUDE.md content should merge it into AGENTS.md's CUSTOMIZABLE sections before converting CLAUDE.md to a symlink.
3. `.agent/skills/` → `.agents/skills/` rename: `--update` copies skills to new path; developer removes old `.agent/` directory after confirming
4. Old `docs/specs/` directory remains (not deleted) — teams move specs to `specs/` at their own pace
5. Old `aperium-spec` skill is replaced by `aperium-spec-generate` via the skills copy in `--update`. The `--update` script does NOT delete old skill directories — developer removes `skills/aperium-spec/` (or `.agents/skills/aperium-spec/`) after confirming
6. Workflow guide updated automatically via `--update`

No breaking changes — v1 workflow continues to work alongside v2.

---

## File Inventory (Expected Deliverables)

| # | File | Action |
|---|------|--------|
| 1 | `templates/AGENTS.md.template` | Update (add Context Model, .agents/skills/, remove extra symlinks) |
| 2 | `templates/setup.sh` | Update (2 symlinks, .agents/skills/, specs/ dir) |
| 3 | `templates/setup.ps1` | Update (2 symlinks, .agents/skills/, specs/ dir) |
| 4 | `templates/.gitignore.template` | Update (remove CODEX.md, main.mdc; keep CLAUDE.md, copilot-instructions.md) |
| 5 | `docs/workflow-guide.md` | Rewrite (specs-in-git, CI sync, simplified symlinks) |
| 6 | `docs/prompts/new-api-endpoint.md` | Update (spec path refs) |
| 7 | `docs/prompts/new-mcp-tool.md` | Update (spec path refs) |
| 8 | `docs/prompts/new-react-component.md` | Update (spec path refs) |
| 9 | `docs/prompts/debug-template.md` | Update (spec path refs) |
| 10 | `docs/prompts/security-review.md` | Update (spec path refs) |
| 11 | `skills/aperium-spec/` | Remove (replaced by aperium-spec-generate) |
| 12 | `skills/aperium-spec-generate/SKILL.md` | Create |
| 13 | `skills/aperium-spec-generate/references/architecture-context.md` | Migrate |
| 14 | `skills/aperium-spec-generate/references/security-template.md` | Migrate |
| 15 | `skills/aperium-spec-generate/references/spec-sections.md` | Migrate + update (add decisions.md template) |
| 16 | `skills/aperium-sync-tasks/SKILL.md` | Create |
| 17 | `skills/aperium-sync-tasks/references/jira-ticket-format.md` | Create |
| 18 | `skills/aperium-close-spec/SKILL.md` | Create |
| 19 | `skills/aperium-close-spec/references/implementation-notes-template.md` | Create |
| 20 | `skills/aperium-mcp-dev/SKILL.md` | Update (.agents/skills/ refs) |
| 21 | `skills/aperium-security/SKILL.md` | Update (output path refs) |
| 22 | `templates/github-actions/confluence-sync.yml` | Create |
| 23 | `templates/github-actions/close-the-loop.yml` | Create |
| 24 | `templates/github-actions/README.md` | Create |
| 25 | `templates/github-actions/confluence-discover/action.yml` | Create |

**Total**: 25 files (11 updates, 2 migrations, 9 creates, 1 remove, 1 rewrite, 1 migrate+update)
