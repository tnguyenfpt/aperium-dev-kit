# Security Assessment Report Template

## Instructions

The aperium-security skill fills this template when performing an assessment.
The assessor (AI agent + developer) works through each checklist item and records findings.

## Template

```markdown
# Security Assessment: {FEATURE_NAME}

**Date**: {DATE}
**Assessor**: {AGENT_NAME} + {DEVELOPER_NAME}
**Scope**: {FILES_AND_FEATURES_ASSESSED}
**Assessment Type**: [Full / Focused / Pre-merge]

## Executive Summary

[2-3 sentence overview of findings. Include: total checks, pass/fail/warn counts, critical findings if any.]

## 6-Layer Defense Model

| Layer | Status | Evidence | Remediation |
|-------|--------|----------|-------------|
| 1. Input Validation | PASS/FAIL/WARN | [What was found] | [Fix if needed] |
| 2. Prompt Injection Detection | PASS/FAIL/WARN | [What was found] | [Fix if needed] |
| 3. Tool Permission Check (RBAC) | PASS/FAIL/WARN | [What was found] | [Fix if needed] |
| 4. Output Validation | PASS/FAIL/WARN | [What was found] | [Fix if needed] |
| 5. Human Approval | PASS/FAIL/WARN | [What was found] | [Fix if needed] |
| 6. Audit Log | PASS/FAIL/WARN | [What was found] | [Fix if needed] |

### Layer Details

[For each FAIL or WARN, provide detailed findings: file paths, line numbers, specific issues, and recommended fixes.]

## OWASP Agentic Top 10

| # | Check | Status | Evidence | Remediation |
|---|-------|--------|----------|-------------|
| 1 | Prompt Injection | PASS/FAIL/WARN | [What was found] | [Fix if needed] |
| 2 | Broken Access Control | PASS/FAIL/WARN | [What was found] | [Fix if needed] |
| 3 | Data Poisoning | PASS/FAIL/WARN | [What was found] | [Fix if needed] |
| 4 | Insufficient Monitoring | PASS/FAIL/WARN | [What was found] | [Fix if needed] |
| 5 | Insecure Tool Use | PASS/FAIL/WARN | [What was found] | [Fix if needed] |
| 6 | Excessive Agency | PASS/FAIL/WARN | [What was found] | [Fix if needed] |
| 7 | Sensitive Info Disclosure | PASS/FAIL/WARN | [What was found] | [Fix if needed] |
| 8 | Supply Chain Vulnerabilities | PASS/FAIL/WARN | [What was found] | [Fix if needed] |
| 9 | Denial of Service | PASS/FAIL/WARN | [What was found] | [Fix if needed] |
| 10 | Improper Error Handling | PASS/FAIL/WARN | [What was found] | [Fix if needed] |

### OWASP Details

[For each FAIL or WARN, provide detailed findings.]

## Summary

### Statistics
- Total checks: {N}
- Passed: {N} | Failed: {N} | Warnings: {N}
- Critical findings: {N}

### Critical Findings

[List any FAIL items that must be fixed before merge.]

### Recommended Actions

1. [Priority-ordered list of remediation actions]

### Sign-off
- [ ] All critical findings addressed
- [ ] Remediation verified by re-assessment
- [ ] Approved for merge by: {APPROVER}
```

## Usage Notes

- Status values: PASS (fully compliant), FAIL (violation found, must fix), WARN (partial compliance, should fix)
- Evidence should reference specific file paths and line numbers when possible
- Remediation should be actionable (specific code changes, not generic advice)
- Reports are saved to: `specs/{feature}/security-assessment.md`
