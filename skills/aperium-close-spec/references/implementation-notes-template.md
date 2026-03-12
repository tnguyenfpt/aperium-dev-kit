# Implementation Notes Template

This template is appended to `specs/{TICKET_KEY}/decisions.md` when a feature spec is closed after merge.

## Template

```markdown
## Implementation Notes (added on closure)

- **PR**: {PR_URL}
- **Merge commit**: {COMMIT_SHA}
- **Date**: {YYYY-MM-DD}
- **Author**: {AUTHOR}

### Design Deviations

{List any deviations from the original design, or "None — implemented as designed."}

### Lessons Learned

{Key takeaways from the implementation, or "None noted."}

### Metrics

- **Planned story points**: {TOTAL_PLANNED}
- **Actual effort**: {ACTUAL_ESTIMATE}
- **Test coverage**: {COVERAGE_PERCENTAGE}
```

## Guidance

- **Design Deviations** should document WHY the deviation was necessary, not just WHAT changed
- **Lessons Learned** should be actionable — things the team should do differently next time
- **Metrics** help calibrate future estimates
- If no deviations occurred, explicitly state "None — implemented as designed" (this is valuable data)
