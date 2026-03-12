---
name: aperium-security
description: "Use when reviewing a feature branch, MCP server, or agentic code for security compliance, or before merging any PR that touches auth, permissions, or data access"
---

# Aperium Security Assessment Skill

## Purpose
Perform structured security assessments against Aperium's 6-layer defense model and OWASP Agentic Top 10. Generates a detailed report with pass/fail/warn status and remediation recommendations.

## Prerequisites
- Codebase or feature branch to assess must be accessible
- AGENTS.md must exist (for security requirements reference)

## When to Use
- Before merging any PR that touches auth, authorization, MCP permissions, or data access
- After creating or modifying an MCP server
- During scheduled security reviews of agentic features
- When onboarding a new third-party integration
- Before deploying any feature that handles PII

## Workflow
1. **Accept scope**: feature name, files/directories, assessment type (Full, Focused, or Pre-merge).
2. **Load checklists** from `references/6-layer-checklist.md`, `references/owasp-agentic-top10.md`, and `references/report-template.md`.
3. **Assess 6-Layer Defense Model** (layer by layer):
   - Layer 1 Input Validation: Pydantic models, constraints, no raw input in dangerous ops
   - Layer 2 Prompt Injection Detection: input sanitization, prompt/data separation
   - Layer 3 Tool Permission Check: RBAC on all tools, least privilege
   - Layer 4 Output Validation: response sanitization, error message safety
   - Layer 5 Human Approval: destructive action gates, bulk operation confirmations
   - Layer 6 Audit Log: logging completeness, PII-free logs, structured format
   - Record per layer: Status (PASS/FAIL/WARN), Evidence (specific findings), Remediation (if needed)
4. **Assess OWASP Agentic Top 10**: follow check procedure per item, gather evidence, determine status, record remediation for any FAIL or WARN.
5. **Generate report** using `references/report-template.md`: header, 6-layer table, OWASP table, executive summary, critical findings, recommended actions.
6. **Write output** to `specs/{feature}/security-assessment.md`.
7. **Report** findings summary and path to full report.

## Output
- **File**: `specs/{feature}/security-assessment.md`
- **Format**: Structured Markdown with assessment tables
- **Content**: 6-layer results, OWASP results, executive summary, remediation actions

## References
- `references/6-layer-checklist.md` -- Assessment criteria per defense layer
- `references/owasp-agentic-top10.md` -- OWASP Agentic Top 10 checklist
- `references/report-template.md` -- Report output template

## Common Mistakes
- Marking layers as "N/A" without justification; every layer should be assessed
- Providing vague evidence instead of specific file paths and line numbers
- Skipping OWASP items that seem irrelevant; assess all 10 with evidence
- Writing generic remediation instead of actionable fixes with code references
- Not checking PII masking in error messages and logs

## Quick Reference

| Input | Output |
|-------|--------|
| Scope path (files/dirs) | `specs/{feature}/security-assessment.md` |
| 6-layer checklist (auto-loaded) | Per-layer PASS/FAIL/WARN with evidence |
| OWASP checklist (auto-loaded) | Per-item PASS/FAIL/WARN with evidence |
