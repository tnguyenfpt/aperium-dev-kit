---
name: aperium-spec-generate
description: "Use when creating a new feature specification for an Aperium project. Generates a complete spec directory with requirements, design, tasks, decisions, and review checklist."
---

# aperium-spec-generate

Generate a complete feature specification directory following the Aperium spec-driven development workflow.

## When to Use

- Starting a new feature or epic
- Creating a formal spec from brainstorming output
- Documenting requirements before implementation begins

## Workflow

### 1. Accept Feature Context

Gather from the user:
- **Epic/ticket key** (e.g., `APER-123`) — used as directory name
- **Feature name** and one-line purpose
- **Primary users** and business domain
- **Key requirements** (functional and non-functional)

### 2. Load References

Read the following reference files for templates and guidance:
- `references/spec-sections.md` — section templates and format
- `references/security-template.md` — security considerations template
- `references/architecture-context.md` — platform architecture context

### 3. Generate Spec Interactively

Work through each section with the user:
1. **Requirements** — user scenarios, acceptance criteria, edge cases
2. **Design** — architecture decisions, component interactions, data model
3. **Tasks** — numbered task list with complexity (S/M/L) and dependencies
4. **Decisions** — key design choices with rationale and trade-offs
5. **Review Checklist** — pre-populated from template, customized per feature

### 4. Write to specs/ Directory

Create the spec directory and files:

```
specs/{TICKET_KEY}/
  requirements.md
  design.md
  tasks.md
  decisions.md
  review-checklist.md
```

### 5. Validate Output

Verify:
- All 5 files created with correct content
- No placeholder text remaining (all `{PLACEHOLDER}` values filled)
- Security section addresses 6-layer defense model
- Tasks have complexity estimates and dependencies

### 6. Report

Summarize what was generated and suggest next steps:
- Review spec with team
- Use `aperium-sync-tasks` to create Jira tickets from tasks.md
- Begin implementation following the task breakdown

## Output

| Input | Output |
|-------|--------|
| Epic key + feature context | `specs/{TICKET_KEY}/` directory with 5 spec files |

## Common Mistakes

- **Writing to `docs/specs/` instead of `specs/`** — v2 uses `specs/` at repo root
- **Skipping the decisions file** — every spec needs at least one documented decision
- **Generic security section** — must reference specific 6-layer defense checks relevant to the feature
- **Missing edge cases** — each requirement needs at least one edge case scenario

## References

- `references/spec-sections.md` — Section templates
- `references/security-template.md` — Security assessment template
- `references/architecture-context.md` — Platform architecture context
