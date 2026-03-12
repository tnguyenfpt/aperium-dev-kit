---
name: aperium-sync-tasks
description: "Use when task breakdown is ready in specs/ and needs to be synced to Jira. Creates Jira tickets from tasks.md with proper linking and story points."
---

# aperium-sync-tasks

Sync task breakdown from `specs/{TICKET_KEY}/tasks.md` to Jira, creating linked tickets with story points and dependencies.

## When to Use

- After spec generation is complete and reviewed
- When tasks.md has been finalized and approved by the team
- To create Jira tickets that match the implementation plan

## Prerequisites

- `specs/{TICKET_KEY}/tasks.md` exists and is complete
- Jira project key is known (e.g., `APER`)
- Atlassian MCP server is configured (or manual fallback is acceptable)

## Workflow

### 1. Read tasks.md

Parse `specs/{TICKET_KEY}/tasks.md` to extract:
- Task number, title, complexity (S/M/L)
- Dependencies between tasks
- Test criteria / acceptance criteria
- Component assignment (from design.md if available)

### 2. Map to Jira Format

Using `references/jira-ticket-format.md`:
- Convert complexity to story points (S=1, M=3, L=5)
- Format description in Jira markup
- Build dependency links between tasks

### 3. Present Draft for Review

Show the developer a summary table:

```
| # | Summary | Points | Dependencies | Status |
|---|---------|--------|-------------|--------|
| 1 | Database models | 1 | None | Ready |
| 2 | API schemas | 1 | T1 | Ready |
| 3 | Profile endpoint | 3 | T1 | Ready |
```

Wait for developer approval before creating tickets.

### 4. Create Jira Tickets

Using Atlassian MCP (preferred):
- Create each ticket as a Sub-task under the Epic
- Set story points, labels, component
- Create "Blocked By" links for dependencies
- Add spec reference in description

### 5. Update tasks.md with Jira IDs

After ticket creation, update `specs/{TICKET_KEY}/tasks.md`:
- Add Jira ticket ID next to each task heading
- Example: `### Task 3: Implement profile endpoint (M) — APER-123-T3`

### 6. Handle MCP Errors

If Atlassian MCP is unavailable or fails:
1. Save draft tickets to `specs/{TICKET_KEY}/jira-draft.md`
2. Report which tickets were created vs failed
3. Provide manual creation instructions for failed tickets

### 7. Report

Summarize:
- Tickets created (with links)
- Total story points
- Dependency chain visualization
- Any failures requiring manual intervention

## Output

| Input | Output |
|-------|--------|
| `specs/{TICKET_KEY}/tasks.md` | Jira tickets + updated tasks.md with ticket IDs |

## Common Mistakes

- **Creating tickets without developer review** — always present draft first
- **Not updating tasks.md with Jira IDs** — the bidirectional link is essential
- **Ignoring dependencies** — Jira "Blocked By" links must match tasks.md dependencies
- **Wrong story point mapping** — S=1, M=3, L=5 (not 1, 2, 3)

## References

- `references/jira-ticket-format.md` — Ticket template and field mapping
