# OWASP Agentic Top 10 Assessment Checklist (2025 Edition)

Reference file for the `aperium-security` skill. Each item is self-contained
and designed for use during security assessments of agentic AI systems.

---

## AG01 -- Prompt Injection

- **Risk:** Attacker manipulates LLM behavior by embedding malicious instructions in user-supplied input, causing the agent to bypass intended constraints or execute unintended actions.
- **Check procedure:** Verify that all LLM inputs pass through a sanitization layer. Confirm system prompts are structurally separated from user content. Test with known injection patterns (role override, instruction override, context escape).
- **Evidence requirements:** Input validation middleware present and active; prompt templates use parameterized insertion (no raw concatenation); injection pattern scanner in the request pipeline.
- **Remediation template:** Add input sanitization middleware before the LLM call. Use structured prompt templates that isolate system instructions from user data. Deploy an injection-pattern detection layer (regex + classifier).
- **Criteria:** PASS -- all LLM inputs sanitized, prompt/data separation enforced. WARN -- sanitization present but no injection-pattern scanning. FAIL -- user content concatenated directly into system prompts.

---

## AG02 -- Broken Access Control

- **Risk:** Users or agents access resources or invoke tools beyond their authorized scope, leading to privilege escalation or unauthorized data exposure.
- **Check procedure:** Verify RBAC checks execute before every tool invocation. Confirm resource-level authorization (row/object level). Validate that the principle of least privilege is applied to agent tool registrations.
- **Evidence requirements:** Permission middleware on all tool endpoints; role definitions with explicit allow-lists; resource ownership checks; audit log entries for authorization decisions.
- **Remediation template:** Add RBAC middleware to the tool execution pipeline. Implement resource-level authorization checks. Restrict each agent's tool set to the minimum required for its role.
- **Criteria:** PASS -- RBAC enforced on all tools, resource-level checks present. WARN -- RBAC present but missing resource-level checks. FAIL -- tools executable without permission verification.

---

## AG03 -- Data Poisoning

- **Risk:** Malicious or corrupted data introduced into training sets, knowledge bases, RAG indices, or cached context degrades agent accuracy or causes harmful outputs.
- **Check procedure:** Verify data source validation on ingestion pipelines. Confirm integrity checks (hashing, signatures) on knowledge base updates. Test cache invalidation procedures.
- **Evidence requirements:** Data provenance tracking; integrity hashes on ingested documents; source allow-listing for RAG corpora; cache TTLs and invalidation hooks.
- **Remediation template:** Add data source validation and allow-listing on all ingestion paths. Implement integrity hashing for knowledge base entries. Configure cache TTLs and forced invalidation on source changes.
- **Criteria:** PASS -- all data sources validated, integrity checks enforced. WARN -- validation present but no integrity hashing. FAIL -- unvalidated data flows into knowledge base or context.

---

## AG04 -- Insufficient Monitoring

- **Risk:** Attacks, anomalies, or policy violations go undetected because agent activity is not logged, monitored, or alerted on.
- **Check procedure:** Verify structured logging of all tool invocations, LLM calls, and authorization decisions. Confirm anomaly detection rules are active. Check that alerts route to the security team.
- **Evidence requirements:** Structured log entries for every tool call (who, what, when, result); monitoring dashboard with agent activity metrics; alert rules for anomalous patterns (volume spikes, unusual tool sequences, repeated failures).
- **Remediation template:** Add structured logging middleware to the agent pipeline. Deploy monitoring dashboards for agent activity. Configure alert rules for anomaly detection (rate anomalies, error spikes, off-hours activity).
- **Criteria:** PASS -- all tool calls logged, anomaly alerts configured. WARN -- logging present but no anomaly detection. FAIL -- tool invocations not logged.

---

## AG05 -- Insecure Tool Use

- **Risk:** Agent tools execute dangerous operations (file writes, API calls, database mutations) without proper input validation, error handling, or timeout guards.
- **Check procedure:** Verify every tool validates its inputs against a schema. Confirm error handling wraps all tool logic. Check that per-tool timeouts are configured and enforced.
- **Evidence requirements:** Input validation schemas per tool; try/catch or error boundary around tool execution; timeout configuration in tool registration; no raw shell or SQL execution.
- **Remediation template:** Add input validation schemas to all tool definitions. Wrap tool execution in error boundaries with structured error responses. Configure per-tool timeouts in the tool registry.
- **Criteria:** PASS -- all tools have input validation, error handling, and timeouts. WARN -- most tools covered but gaps exist. FAIL -- tools accept unvalidated input or lack timeouts.

---

## AG06 -- Excessive Agency

- **Risk:** The agent possesses more tools or broader permissions than required for its designated task, expanding the blast radius of any compromise.
- **Check procedure:** Verify the agent's tool set is minimal for its purpose. Confirm destructive actions (delete, overwrite, send) require human approval. Check that tool scope is limited by context.
- **Evidence requirements:** Tool registration manifest showing only required tools; human-in-the-loop gate on destructive operations; scope restrictions per agent role or session.
- **Remediation template:** Audit and remove unnecessary tools from each agent profile. Add human approval gates for destructive actions. Implement session-scoped tool access tied to the current task.
- **Criteria:** PASS -- minimal tool set, destructive actions gated. WARN -- tool set reasonable but no human-in-the-loop for destructive ops. FAIL -- agent has broad unrestricted tool access.

---

## AG07 -- Sensitive Information Disclosure

- **Risk:** PII, secrets, or internal system details are exposed in agent responses, log output, or error messages.
- **Check procedure:** Verify PII masking middleware is active on all tool outputs. Confirm secrets are not present in logs or error responses. Test with synthetic PII to validate masking.
- **Evidence requirements:** PII masking middleware in the response pipeline; log output free of secrets and PII; error messages returning only user-safe content; redaction rules for known sensitive patterns.
- **Remediation template:** Add PII masking middleware to the agent response pipeline. Sanitize all error messages before returning to users. Audit log output for secrets and add redaction rules.
- **Criteria:** PASS -- PII masked, secrets absent from logs and responses. WARN -- PII masking present but incomplete pattern coverage. FAIL -- PII or secrets visible in responses or logs.

---

## AG08 -- Supply Chain Vulnerabilities

- **Risk:** Compromised or vulnerable dependencies, plugins, or MCP servers introduce security risks into the agent platform.
- **Check procedure:** Verify all dependencies are pinned to exact versions. Confirm CI runs vulnerability scanning (e.g., `pip audit`, `npm audit`). Check that new plugins undergo a vetting process.
- **Evidence requirements:** Pinned versions in `pyproject.toml` / `package-lock.json`; CI vulnerability scan step with blocking on critical findings; documented plugin approval process.
- **Remediation template:** Pin all dependencies to exact versions. Add dependency vulnerability scanning to the CI pipeline (block on critical/high). Establish a plugin vetting and approval process.
- **Criteria:** PASS -- dependencies pinned, CI scanning active, plugin vetting documented. WARN -- scanning present but not blocking on critical findings. FAIL -- unpinned dependencies or no vulnerability scanning.

---

## AG09 -- Denial of Service

- **Risk:** Resource exhaustion through excessive requests, oversized inputs, or runaway tool execution renders the agent platform unavailable.
- **Check procedure:** Verify rate limiting on agent endpoints. Confirm input size limits are enforced. Check that per-tool and per-session timeouts prevent runaway execution.
- **Evidence requirements:** Rate limiter middleware with configured thresholds; max input length enforcement; per-tool timeout configuration; per-session resource budgets.
- **Remediation template:** Add rate limiting middleware to all agent-facing endpoints. Enforce maximum input size at the API gateway. Configure per-tool timeouts and per-session resource budgets.
- **Criteria:** PASS -- rate limiting, input size limits, and timeouts all enforced. WARN -- rate limiting present but missing input size or timeout limits. FAIL -- no rate limiting or timeout configuration.

---

## AG10 -- Improper Error Handling

- **Risk:** Unhandled errors expose internal state (stack traces, config details) or cause the agent to enter undefined behavior, potentially bypassing security controls.
- **Check procedure:** Verify error boundaries wrap all tool and LLM call paths. Confirm error responses are user-safe (no stack traces, no internal paths). Test with malformed inputs to trigger error paths.
- **Evidence requirements:** Error handler middleware in the agent pipeline; user-facing error responses with generic messages; internal errors logged but not returned; graceful degradation (agent remains functional after errors).
- **Remediation template:** Add error boundary middleware to the agent execution pipeline. Replace raw exception responses with structured, user-safe error messages. Implement graceful degradation so partial failures do not crash the session.
- **Criteria:** PASS -- all error paths handled, user-safe responses, graceful degradation. WARN -- error handling present but some paths return raw exceptions. FAIL -- stack traces or internal details exposed in error responses.
