---
name: aperium-close-spec
description: "Use when a feature is merged and the spec needs implementation notes, Jira ticket transitions, and optional Confluence archival."
---

# aperium-close-spec

Close out a feature specification after merge: add implementation notes, transition Jira tickets, and prepare for Confluence archival.

## When to Use

- After a feature PR is merged to develop/main
- When all implementation tasks are complete
- To formally close out a spec before CI syncs to Confluence

## Prerequisites

- Feature branch has been merged
- `specs/{TICKET_KEY}/` directory exists with complete spec files
- PR URL and merge commit SHA are known

## Workflow

### 1. Gather Merge Context

Collect:
- **PR URL** (from `gh pr view` or user input)
- **Merge commit SHA** (from `git log` or user input)
- **Author** (from git or user input)
- **Date** (current date)

### 2. Review Implementation Against Spec

Compare the actual implementation with the spec:
- Read `specs/{TICKET_KEY}/requirements.md` — were all requirements met?
- Read `specs/{TICKET_KEY}/design.md` — any deviations from the design?
- Read `specs/{TICKET_KEY}/tasks.md` — all tasks completed?
- Read `specs/{TICKET_KEY}/review-checklist.md` — all items checked?

### 3. Write Implementation Notes

Using `references/implementation-notes-template.md`, create the implementation notes section and append it to `specs/{TICKET_KEY}/decisions.md`:
- Document design deviations with rationale
- Capture lessons learned
- Record metrics (planned vs actual effort, coverage)

### 4. Update Review Checklist

Mark all completed items in `specs/{TICKET_KEY}/review-checklist.md` as checked.

### 5. Check Jira Ticket Status

If Atlassian MCP is available:
- Verify all sub-tasks under the Epic are in "Done" status
- If any are not Done, report which ones and ask developer to resolve
- Transition the Epic to "Done" if all sub-tasks are complete

If MCP is unavailable:
- Report the tickets that should be transitioned
- Provide manual instructions

### 6. Mark Spec as Completed

Add `status: completed` to the top of `specs/{TICKET_KEY}/requirements.md` (after the title heading):

```markdown
**Status**: Completed
```

This header triggers CI archival — the `confluence-sync` workflow moves the epic page from "Active Specs" to "Completed Specs" when it detects this marker.

### 7. Commit Updated Spec

```bash
git add specs/{TICKET_KEY}/
git commit -m "docs(spec): close {TICKET_KEY} with implementation notes"
```

### 8. Report

Summarize:
- Implementation notes added to decisions.md
- Review checklist status
- Jira ticket transitions (completed or manual steps needed)
- Remind: CI will sync to Confluence on next push/merge

## Output

| Input | Output |
|-------|--------|
| Merged PR + spec directory | Updated decisions.md + review-checklist.md, Jira transitions |

## Common Mistakes

- **Archiving before all tickets are Done** — check Jira status first
- **Not committing updated spec files** — the implementation notes must be in git for CI sync
- **Skipping lessons learned** — even "none noted" is valuable; don't leave it blank
- **Forgetting to push** — CI sync happens on push, not on local commit

## References

- `references/implementation-notes-template.md` — Template for implementation notes
