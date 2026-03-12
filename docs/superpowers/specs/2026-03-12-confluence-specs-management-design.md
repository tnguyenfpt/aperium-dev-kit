# Confluence Specs Management — Design Document

**Date**: 2026-03-12
**Author**: Aperium Engineering
**Status**: Draft
**Feature**: Migrate spec management from Git to Confluence (v1 → v2)

---

## Summary

The Aperium Dev Kit v1 stores specs as Markdown files in Git (`docs/specs/`). V2 moves specs to Confluence as the single source of truth, with AI agents accessing them via Confluence MCP. This design covers all changes needed to update the kit.

## Decisions from Brainstorming

| Question | Decision |
|----------|----------|
| Scope | Full v2 — update all kit components + build 4 Confluence-native skills + GitHub Action template |
| MCP strategy | Hybrid — Atlassian MCP as primary path, documented fallback for alternatives |
| Confluence space | Auto-discover or create on first use (resilient to either state) |
| GitHub Action | Include template + manual fallback via `/aperium:close-spec` skill |
| Fetch strategy | Per-spec freshness check (<4h skip, >4h warn), partial fetch, `--force` flag |

## Delivery Strategy: Layered

Three ordered sub-features on the same branch. Each layer is independently usable.

---

## Layer 1: Kit v2 Foundation (~15 tasks)

### 1.1 AGENTS.md Template Update

**Current**: 6 sections (3 CUSTOMIZABLE, 3 FIXED), 95 lines.
**Change**: Add a 7th section — "Context Model" — as a new FIXED section.

New section content:

```markdown
## Context Model

<!-- FIXED: Do not modify -- managed by aperium-dev-kit -->

This repository uses a split context model:

- **Layer 1 -- Code Context** (this file, `AGENTS.md`): Architecture, conventions,
  build commands. Lives in Git. Changes rarely.
- **Layer 2 -- Feature Context** (`.specs/`): Requirements, design, tasks fetched
  from Confluence per-feature. Gitignored. Re-fetched each session.
- **Layer 3 -- Skill Context** (`.agent/skills/`): Reusable workflow instructions.
  Lives in Git. Grows over time.
```

Target line count: ~105 lines (slight increase from 95).

### 1.2 Setup Scripts Update

Both `setup.sh` and `setup.ps1`:

- Add `.specs/` and `.specs/.freshness/` to the .gitignore block
- Create `.specs/.freshness/` directory during bootstrap
- Add Confluence MCP to the Tier 2 setup guidance in the summary output

### 1.3 .gitignore Template Update

Add:

```gitignore
# Confluence specs (fetched on demand, not tracked)
.specs/
```

### 1.4 Existing Skills Update

**aperium-spec** (to be replaced in Layer 2, but updated here for interim use):
- Workflow step 6 changed: "Write output to Confluence if MCP available; fall back to `docs/specs/{feature}/spec.md`"
- Add Common Mistake: "Committing specs to Git instead of pushing to Confluence"

**aperium-mcp-dev**:
- Add optional step: "Push design spec to Confluence Architecture Reference if MCP available"

**aperium-security**:
- Add optional step: "Push assessment report to Confluence if MCP available"

### 1.5 Workflow Guide Rewrite

Full rewrite of `docs/workflow-guide.md` to reflect:

- Confluence as spec source of truth (not Git)
- `.specs/` fetch pattern for non-Claude-Code agents
- Split context model (3 layers)
- Confluence space structure documentation
- Updated Phase 2 (spec generation → Confluence) and Phase 4 (fetch spec → implement)
- Close-the-loop description (automated + manual paths)
- Updated cheat sheet with new commands
- Updated Kit Component Reference table (new skills, GitHub Action template)

### 1.6 Prompt Templates Update

All 5 prompt templates in `docs/prompts/`:
- Change spec references from `docs/specs/` to `.specs/` (fetched from Confluence)
- Add Context note: "Specs live in Confluence; use `/aperium:fetch-spec` to pull locally"

---

## Layer 2: Confluence Skill Suite (~15 tasks)

### 2.1 Shared Reference: Space Discovery

File: `skills/aperium-confluence/references/space-discovery.md`

Auto-discovery logic used by all 4 skills:

1. Search for Confluence space with name containing "Aperium Specs" (CQL query)
2. If found: use that space key
3. If not found: prompt developer — "No Aperium Specs space found. Create it? (y/n)"
4. Find "Active Specs" parent page in that space
5. If not found: create it
6. Find Epic page (APER-123) under Active Specs
7. If not found: create with title "APER-123: {Epic summary from Jira}"

MCP hybrid pattern:
- Primary: `mcp__claude_ai_Atlassian__*` tools
- Fallback: documented equivalent operations for acli / mcp-atlassian alternatives

### 2.2 `aperium-spec-generate`

**Replaces**: `skills/aperium-spec/` (old skill removed, references migrated)

**Location**: `skills/aperium-spec-generate/`

**SKILL.md trigger**: "Use when creating a new feature specification for an Aperium service and pushing it to Confluence"

**Workflow**:
1. Accept Epic key (APER-123) + feature description
2. Fetch Jira ticket details via Atlassian MCP for context
3. Run space auto-discovery (reference: space-discovery.md)
4. Load architecture-context.md, security-template.md, spec-sections.md
5. Generate spec interactively (Socratic brainstorming if Superpowers available)
6. Push each section as a Confluence child page: Requirements, Design, Tasks, Review Checklist
7. **Local fallback**: If MCP unavailable, write to `docs/specs/{feature}/` and warn
8. Report page URLs + suggest next steps

**References** (migrated from aperium-spec + new):
- `references/architecture-context.md` (migrated)
- `references/security-template.md` (migrated)
- `references/spec-sections.md` (migrated)
- `references/confluence-page-templates.md` (NEW — Confluence page structure for each section type)

### 2.3 `aperium-fetch-spec`

**Location**: `skills/aperium-fetch-spec/`

**SKILL.md trigger**: "Use when starting implementation and need to pull the latest spec from Confluence to the local .specs/ directory"

**Workflow**:
1. Accept Epic key (APER-123), optional `--force` flag
2. Check `.specs/.freshness/APER-123.json`:
   - If exists and <4 hours old and no `--force`: report "Spec is fresh (fetched {time})", skip
   - If >4 hours old: warn "Spec is stale ({hours}h old). Fetching latest..."
   - If missing or `--force`: proceed to fetch
3. Search Confluence for the Epic's child pages
4. Download each as Markdown → write to `.specs/APER-123/{section}.md`
5. Write freshness metadata to `.specs/.freshness/APER-123.json`:
   ```json
   {
     "ticket": "APER-123",
     "fetched_at": "2026-03-12T10:00:00Z",
     "space_key": "APERSPEC",
     "page_versions": {
       "requirements": {"page_id": "12345", "version": 3},
       "design": {"page_id": "12346", "version": 5},
       "tasks": {"page_id": "12347", "version": 2},
       "review-checklist": {"page_id": "12348", "version": 1}
     }
   }
   ```
6. Report file paths + freshness timestamp

**References**:
- `references/freshness-schema.md` (JSON schema + freshness logic)

### 2.4 `aperium-sync-tasks`

**Location**: `skills/aperium-sync-tasks/`

**SKILL.md trigger**: "Use when task breakdown is ready in Confluence and needs to be synced to Jira as child tickets"

**Workflow**:
1. Accept Epic key (APER-123)
2. Read Tasks page from Confluence (direct MCP or from `.specs/APER-123/tasks.md`)
3. Parse numbered tasks with complexity, dependencies, test criteria
4. Generate Markdown draft of Jira tickets locally — **intermediate checkpoint**: present to developer for review
5. On developer approval: create child tickets under Epic via Jira MCP
6. Update Confluence Tasks page with Jira ticket IDs for traceability
7. Report created ticket IDs + links

**References**:
- `references/jira-ticket-format.md` (ticket template with fields mapping)

### 2.5 `aperium-close-spec`

**Location**: `skills/aperium-close-spec/`

**SKILL.md trigger**: "Use when a feature is merged and the Confluence spec needs implementation notes and archival"

**Workflow**:
1. Accept Epic key (APER-123) + PR link + optional deviation notes
2. Find the Epic's spec page in Confluence (via space-discovery)
3. Create/update "Implementation Notes" child page: PR link, merge commit SHA, design deviations, test coverage summary
4. Check if all Jira child tickets under Epic are Done
5. If all done: move Epic spec page from "Active Specs" to "Completed Specs"
6. If not all done: report which tickets remain open, skip archival
7. Optionally clean up `.specs/APER-123/` locally
8. Report completion status

**References**:
- `references/implementation-notes-template.md` (Markdown template for the notes page)

### 2.6 Skill Directory Structure (Final)

```
skills/
  aperium-spec-generate/        (NEW - replaces aperium-spec)
    SKILL.md
    references/
      architecture-context.md   (migrated)
      security-template.md      (migrated)
      spec-sections.md          (migrated)
      confluence-page-templates.md  (NEW)
  aperium-fetch-spec/           (NEW)
    SKILL.md
    references/
      freshness-schema.md
  aperium-sync-tasks/           (NEW)
    SKILL.md
    references/
      jira-ticket-format.md
  aperium-close-spec/           (NEW)
    SKILL.md
    references/
      implementation-notes-template.md
  aperium-confluence/           (NEW - shared references)
    references/
      space-discovery.md
  aperium-mcp-dev/              (existing, updated)
    SKILL.md
    references/ (unchanged)
  aperium-security/             (existing, updated)
    SKILL.md
    references/ (unchanged)
```

---

## Layer 3: CI Automation (~5 tasks)

### 3.1 GitHub Action Template

**File**: `templates/github-actions/close-the-loop.yml`

**Design**:
- Uses `workflow_call` for reusable workflow pattern
- Trigger: on PR merge to `develop` or `main`
- Inputs: `confluence_space_key`, `jira_project_key`
- Secrets: `ATLASSIAN_API_TOKEN`, `ATLASSIAN_EMAIL`, `ATLASSIAN_BASE_URL`

**Steps**:
1. Extract ticket ID from branch name regex: `(feature|fix)/([A-Z]+-\d+)-.*` → capture group 2
2. Fetch PR metadata (link, merge SHA, author) via `gh` CLI
3. Call Confluence REST API to create/update Implementation Notes child page
4. Call Jira REST API to transition ticket to "Done"
5. Check if all sibling tickets under Epic are Done → if yes, call Confluence API to move spec page under "Completed Specs"

**Error handling**: Each step is independent — Confluence failure doesn't block Jira update and vice versa. Failures are reported as PR comments, not pipeline failures.

### 3.2 README Documentation

**File**: `templates/github-actions/README.md`

Contents:
- Installation instructions (copy to `.github/workflows/`)
- Required secrets setup (Atlassian API token, email, base URL)
- Customization (branch naming pattern, Jira project key, Confluence space key)
- Troubleshooting (expired tokens, wrong space key, permission errors)
- Manual fallback: reference to `/aperium:close-spec` skill

---

## Migration Path (v1 → v2)

For repos already using the v1 kit:

1. Run `setup.sh --update` (Layer 1 changes propagate via FIXED section refresh)
2. `.specs/` directory and `.gitignore` rules added automatically
3. Old `docs/specs/` directory remains (not deleted) — teams migrate specs to Confluence at their own pace
4. Old `aperium-spec` skill is replaced by `aperium-spec-generate` via the skills copy in `--update`
5. Workflow guide updated automatically via `--update`

No breaking changes — v1 local-spec workflow continues to work alongside v2 Confluence workflow.

---

## File Inventory (Expected Deliverables)

| # | File | Action |
|---|------|--------|
| 1 | `templates/AGENTS.md.template` | Update (add Context Model section) |
| 2 | `templates/setup.sh` | Update (.specs/ gitignore, .freshness dir) |
| 3 | `templates/setup.ps1` | Update (.specs/ gitignore, .freshness dir) |
| 4 | `templates/.gitignore.template` | Update (add .specs/) |
| 5 | `docs/workflow-guide.md` | Rewrite (Confluence-centric) |
| 6 | `docs/prompts/new-api-endpoint.md` | Update (spec references) |
| 7 | `docs/prompts/new-mcp-tool.md` | Update (spec references) |
| 8 | `docs/prompts/new-react-component.md` | Update (spec references) |
| 9 | `docs/prompts/debug-template.md` | Update (spec references) |
| 10 | `docs/prompts/security-review.md` | Update (spec references) |
| 11 | `skills/aperium-spec/` | Remove (replaced by aperium-spec-generate) |
| 12 | `skills/aperium-spec-generate/SKILL.md` | Create |
| 13 | `skills/aperium-spec-generate/references/architecture-context.md` | Migrate |
| 14 | `skills/aperium-spec-generate/references/security-template.md` | Migrate |
| 15 | `skills/aperium-spec-generate/references/spec-sections.md` | Migrate |
| 16 | `skills/aperium-spec-generate/references/confluence-page-templates.md` | Create |
| 17 | `skills/aperium-fetch-spec/SKILL.md` | Create |
| 18 | `skills/aperium-fetch-spec/references/freshness-schema.md` | Create |
| 19 | `skills/aperium-sync-tasks/SKILL.md` | Create |
| 20 | `skills/aperium-sync-tasks/references/jira-ticket-format.md` | Create |
| 21 | `skills/aperium-close-spec/SKILL.md` | Create |
| 22 | `skills/aperium-close-spec/references/implementation-notes-template.md` | Create |
| 23 | `skills/aperium-confluence/references/space-discovery.md` | Create |
| 24 | `skills/aperium-mcp-dev/SKILL.md` | Update |
| 25 | `skills/aperium-security/SKILL.md` | Update |
| 26 | `templates/github-actions/close-the-loop.yml` | Create |
| 27 | `templates/github-actions/README.md` | Create |

**Total**: 27 files (10 updates, 2 migrations, 12 creates, 1 remove, 2 rewrites)
