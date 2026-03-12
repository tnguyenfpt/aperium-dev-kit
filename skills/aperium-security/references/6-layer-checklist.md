# 6-Layer Defense Model Checklist

Reference checklist for assessing compliance with Aperium's 6-layer agentic security model.
Each layer includes check items, evidence patterns, common failure modes, and pass/fail criteria.
An assessor should walk through every check item and record a verdict per layer.

---

## Layer 1: Input Validation

**Purpose:** Prevent malformed or malicious data from entering the system at the boundary.

### Check Items

- [ ] All user-facing endpoints accept input through Pydantic models (no raw `dict` or untyped params).
- [ ] String inputs define `max_length` via `Field()` constraints.
- [ ] Numeric inputs define `ge`, `le`, or `gt`, `lt` range bounds.
- [ ] Enum fields use Python `Enum` or `Literal` types rather than open strings.
- [ ] No raw user input is interpolated into SQL queries, shell commands, or file paths.

### Evidence Patterns

- Pydantic `BaseModel` subclasses for every request body and query parameter set.
- `Field(max_length=..., ge=..., le=...)` annotations on model fields.
- ORM query builder usage (SQLAlchemy, Tortoise) instead of raw SQL strings.

### Common Failure Modes

- Optional fields lack validation constraints (e.g., `Optional[str]` with no length limit).
- `Any` type used to bypass validation.
- Path parameters passed directly to `open()` or `subprocess` without sanitization.

### Verdict Criteria

- **PASS:** All inputs validated with constraints; no raw input in dangerous operations.
- **WARN:** Models exist but some fields lack range or length constraints.
- **FAIL:** Raw user input reaches SQL, shell, or file-system operations.

---

## Layer 2: Prompt Injection Detection

**Purpose:** Prevent adversarial manipulation of LLM behavior through crafted inputs.

### Check Items

- [ ] All user-supplied text is scanned for known injection patterns before reaching the LLM.
- [ ] System prompts are defined in code or config, never concatenated with user content.
- [ ] Tool descriptions and parameter schemas contain no user-controllable strings.

### Evidence Patterns

- A dedicated sanitization function or middleware invoked before every LLM call.
- Prompt templates that use structured message arrays (`system`, `user` roles) rather than string concatenation.
- Static tool definitions registered at startup, not generated from runtime data.

### Common Failure Modes

- f-string or `.format()` concatenation of user input directly into prompt strings.
- User content placed inside the system message role.
- Tool descriptions dynamically built from database records that users can edit.

### Verdict Criteria

- **PASS:** Injection scanning present on all LLM input paths; strict role separation.
- **WARN:** Scanning exists but does not cover all entry points.
- **FAIL:** User input directly concatenated into prompts or system messages.

---

## Layer 3: Tool Permission Check (RBAC)

**Purpose:** Ensure every tool invocation is authorized against the caller's role and permissions.

### Check Items

- [ ] Each MCP tool declares the permissions it requires (e.g., via decorator or metadata).
- [ ] A middleware or guard verifies the caller's role before tool execution begins.
- [ ] Permission denial events are logged with caller identity and requested tool.
- [ ] Service accounts follow least-privilege: scoped to only the tools they need.

### Evidence Patterns

- Permission decorators (e.g., `@requires_permission("erp:read")`) on tool functions.
- Role-to-permission mapping in a central config or database table.
- Deny-log entries in structured log output.

### Common Failure Modes

- Newly added tools missing RBAC decorators (no permission check at all).
- Over-privileged service accounts with wildcard or admin permissions.
- RBAC checks present but bypassable via internal API routes.

### Verdict Criteria

- **PASS:** All tools enforce RBAC; denials logged; service accounts least-privilege.
- **WARN:** RBAC present but one or more tools lack permission declarations.
- **FAIL:** Tools executable without any permission check.

---

## Layer 4: Output Validation

**Purpose:** Prevent leakage of internal details or sensitive data through tool responses.

### Check Items

- [ ] Tool outputs pass through a sanitization layer before reaching the user or LLM.
- [ ] Error responses return generic messages; stack traces and DB queries are suppressed.
- [ ] PII fields (email, phone, SSN, etc.) are masked in all outbound payloads.
- [ ] Response schemas are defined so unexpected fields are stripped.

### Evidence Patterns

- Output middleware or response model that filters fields before serialization.
- Custom exception handlers that map internal errors to safe HTTP responses.
- PII masking utility applied in the response pipeline.

### Common Failure Modes

- Raw exception propagation (e.g., `HTTPException(detail=str(e))`).
- PII visible in error messages or debug payloads.
- Verbose mode left enabled in production configuration.

### Verdict Criteria

- **PASS:** All outputs sanitized; PII masked; errors generic.
- **WARN:** Sanitization exists but PII masking is incomplete.
- **FAIL:** Stack traces, raw queries, or unmasked PII in responses.

---

## Layer 5: Human Approval

**Purpose:** Require explicit human confirmation before irreversible or high-impact operations.

### Check Items

- [ ] Destructive actions (delete, overwrite, modify production data) trigger a confirmation gate.
- [ ] Bulk operations (batch update, mass delete) require explicit approval with count preview.
- [ ] Approval decisions are recorded with: approver identity, timestamp, and action summary.

### Evidence Patterns

- Confirmation prompt or approval-workflow step in destructive operation handlers.
- A pending-approval state or queue for high-impact actions.
- Audit records linking the approval event to the subsequent action.

### Common Failure Modes

- New destructive endpoints added without a confirmation gate.
- Approval bypassed in automated pipelines with no compensating control.
- Approval logged but missing the approver's identity.

### Verdict Criteria

- **PASS:** All destructive and bulk operations gated; approvals logged with identity.
- **WARN:** Gates exist for most operations but coverage is incomplete.
- **FAIL:** Destructive actions execute without any human confirmation.

---

## Layer 6: Audit Log

**Purpose:** Maintain a tamper-evident record of all tool invocations for compliance and forensics.

### Check Items

- [ ] Every tool invocation logs: timestamp, caller identity, tool name, input summary, output summary, status.
- [ ] Log entries do not contain raw PII (PII is masked before writing).
- [ ] Logs are structured (JSON format) and queryable by standard tooling.
- [ ] Log retention period meets the applicable compliance requirement (define the requirement).
- [ ] Log integrity is protected (append-only store or signed entries).

### Evidence Patterns

- Logging middleware that wraps every tool call with pre/post log statements.
- JSON log formatter configuration (e.g., `python-json-logger`, `structlog`).
- Log sink configuration pointing to a managed service (Cloud Logging, ELK, etc.).

### Common Failure Modes

- Incomplete log fields (e.g., missing output summary or caller identity).
- PII written to logs in plain text.
- Unstructured log lines that resist automated querying.
- No defined retention policy.

### Verdict Criteria

- **PASS:** All fields present; PII masked; structured format; retention defined.
- **WARN:** Logging present but missing one or two fields or partial PII masking.
- **FAIL:** No logging middleware, or PII in logs, or no retention policy.

---

## Assessment Summary Template

| Layer | Verdict | Notes |
|-------|---------|-------|
| 1 - Input Validation | | |
| 2 - Prompt Injection Detection | | |
| 3 - Tool Permission Check (RBAC) | | |
| 4 - Output Validation | | |
| 5 - Human Approval | | |
| 6 - Audit Log | | |

**Overall:** A single FAIL on any layer marks the assessment as non-compliant.
Two or more WARN verdicts also require remediation before production deployment.
