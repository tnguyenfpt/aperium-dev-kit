# Prompt: Security Review

## Purpose
Perform an AI-assisted security review using Aperium's 6-layer defense model, producing actionable findings and remediation recommendations.

## Context
See AGENTS.md for project conventions and forbidden patterns.
Aperium enforces a 6-layer defense model on all agentic features: input validation, prompt injection detection, tool permission check, output validation, human approval for destructive actions, and audit logging. Any PR touching auth, authorization, MCP permissions, or data access requires a mandatory security review.

Specs live in `specs/APER-123/` and are committed to git alongside code.

## Prompt
```
Perform a security review of the following feature in the Aperium platform.

Feature name: {FEATURE_NAME}
Files to review: {FILES_TO_REVIEW}
Scope: {SCOPE}

Evaluate against the Aperium 6-layer defense model:
1. **Input validation** — Are all inputs validated with explicit schemas?
   Check for injection vectors (SQL, NoSQL, command, prompt injection).
2. **Prompt injection detection** — If the feature processes user-supplied
   text fed to an LLM, is there prompt injection detection/filtering?
3. **Tool permission check** — Are RBAC permissions verified before tool
   execution? Is the permission granularity appropriate?
4. **Output validation** — Are outputs sanitized before returning to clients?
   Is PII masked? Are error messages safe (no stack traces, no internal paths)?
5. **Human approval** — Do destructive actions (delete, bulk update, financial
   transactions) require human-in-the-loop confirmation?
6. **Audit logging** — Are security-relevant actions logged with actor, action,
   resource, timestamp, and outcome?

Additionally check:
- OWASP Agentic Top 10 applicability
- PII exposure assessment (fields, logs, error messages)
- Secrets management (no hardcoded secrets, Vault integration)
- Dependency vulnerabilities (known CVEs in direct dependencies)

Return a structured report with a finding severity (Critical/High/Medium/Low)
for each layer, a summary, and prioritized remediation steps.
```

## Expected Output
- A 6-layer checklist with pass/fail/warning status per layer
- OWASP Agentic Top 10 findings relevant to the feature
- PII assessment identifying any exposed or unmasked fields
- RBAC verification confirming correct permission scoping
- Secrets management audit (no hardcoded credentials, proper Vault usage)
- A prioritized remediation list with severity ratings
- Estimated effort for each remediation item

## Example

**Filled-in prompt:**
> Feature name: **Odoo Customer Sync MCP Tool**
> Files to review: `mcp_servers/odoo/tools/sync_customers.py`,
> `mcp_servers/odoo/middleware.py`, `mcp_servers/odoo/schemas/customer.py`
> Scope: New MCP tool that syncs customer records from Odoo into the Aperium
> data layer, including names, emails, phone numbers, and billing addresses.

**Snippet of expected output:**

### 6-Layer Assessment

| Layer | Status | Finding |
|-------|--------|---------|
| 1. Input validation | PASS | Pydantic schemas enforce field types and bounds on sync parameters. |
| 2. Prompt injection | N/A | No LLM processing in this tool. |
| 3. Tool permission | WARNING | Permission `odoo:customers:sync` exists but does not distinguish read-only sync from write-back. |
| 4. Output validation | FAIL | `billing_address` and `phone` are returned unmasked in the sync response. |
| 5. Human approval | PASS | Bulk sync over 500 records triggers approval workflow. |
| 6. Audit logging | WARNING | Sync start/complete events are logged but individual record changes are not. |

### PII Assessment — High Severity
Fields `email`, `phone`, and `billing_address` in `CustomerSyncOutput` are
not passed through the `mask_pii` middleware. These fields are also written
to the sync log at DEBUG level without masking.

### Prioritized Remediation

| # | Severity | Finding | Remediation | Effort |
|---|----------|---------|-------------|--------|
| 1 | **Critical** | PII fields unmasked in response | Apply `@mask_pii(fields=["email", "phone", "billing_address"])` to the tool | S |
| 2 | **High** | PII in DEBUG logs | Replace raw values with masked versions in log statements | S |
| 3 | **Medium** | Permission too broad | Split into `odoo:customers:sync_read` and `odoo:customers:sync_write` | M |
| 4 | **Low** | Record-level audit gap | Add per-record change events to the audit log | M |
