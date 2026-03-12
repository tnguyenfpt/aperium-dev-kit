# Security Considerations Template

## Instructions

This section MUST be included in every feature specification. The AI agent fills it in
based on the feature being specified. No field should be left blank — use "Not Applicable"
with a brief justification when a layer or concern does not apply.

## Template

### Security Considerations

#### Zero Trust Assessment

- What user inputs does this feature accept? How are they validated?
- What external data sources does this feature consume? How are they verified?
- What assumptions about trust boundaries does this feature make?

#### PII Handling

- Does this feature process, store, or display personally identifiable information?
- If yes: what PII fields are involved? How are they masked in logs and error messages?
- Is PII masking middleware required for any MCP tools in this feature?

#### RBAC Requirements

- What roles need access to this feature?
- What permission levels are required for each operation (read, write, delete)?
- Are there any destructive actions that require human approval?

#### 6-Layer Defense Checklist

For each layer, assess whether this feature needs it:

1. **Input Validation** — [Required/Not Applicable] — [Details]
2. **Prompt Injection Detection** — [Required/Not Applicable] — [Details]
3. **Tool Permission Check (RBAC)** — [Required/Not Applicable] — [Details]
4. **Output Validation** — [Required/Not Applicable] — [Details]
5. **Human Approval** — [Required/Not Applicable] — [Details]
6. **Audit Log** — [Required/Not Applicable] — [Details]

#### Data Protection

- What data does this feature create or modify?
- What is the data retention policy?
- Are there compliance requirements (GDPR, SOC2, etc.)?

#### Threat Vectors

- What are the primary attack surfaces introduced by this feature?
- Are there prompt injection risks from user-supplied content?
- Could this feature be used to escalate privileges or bypass access controls?

#### Dependencies

- Does this feature introduce new third-party dependencies with security implications?
- Are secrets required? If so, confirm they are sourced from HashiCorp Vault (never env vars).

## Usage Notes

- The AI agent should fill in the template based on the feature being specified.
- Mark items as "Not Applicable" with a brief justification rather than leaving blank.
- Reference the AGENTS.md Security Requirements section for the full security model.
- This section is reviewed during mandatory security review for relevant PRs.
- Any PR touching auth, authorization, MCP permissions, or data access triggers this review.
- When in doubt about a layer's applicability, mark it as "Required" and document why.
