# Research: Custom Agent Kit

**Date**: 2026-03-11
**Feature**: 001-custom-agent-kit

## R1: AGENTS.md Best Practices and Template Structure

**Decision**: Use a 6-section AGENTS.md template with clearly marked
`<!-- CUSTOMIZABLE -->` and `<!-- FIXED -->` comment blocks.

**Rationale**: The CTO advisory recommends ~80-100 lines of dense,
human-written context. ETH Zurich research (March 2026) shows
human-written context files improve agent task success rates by ~4%,
while LLM-generated files degrade performance by 3%. The 6-section
structure comes directly from the advisory:

1. Project Identity (3-5 lines) — CUSTOMIZABLE per repo
2. Architecture Overview (10-15 lines) — CUSTOMIZABLE per repo
3. Coding Conventions (20-30 lines) — FIXED across all repos
4. Forbidden Patterns (5-10 lines) — FIXED across all repos
5. Build & Test Commands (5-10 lines) — CUSTOMIZABLE per repo
6. Security Requirements (10-15 lines) — FIXED across all repos

**Alternatives considered**:
- Single monolithic AGENTS.md with no template markers: rejected because
  downstream repos would drift as they copy-paste and edit freely.
- YAML/TOML config with Markdown generation: rejected because it adds
  tooling complexity (Principle VIII: Simplicity) and agents read
  Markdown natively.

## R2: Symlink Strategy Across Operating Systems

**Decision**: Provide both `setup.sh` (Bash) and `setup.ps1`
(PowerShell) scripts. Use `ln -sfn` on Unix, `New-Item -ItemType
SymbolicLink` on Windows.

**Rationale**: Windows symlinks require either Developer Mode enabled
or admin privileges. The PowerShell script detects whether symlink
creation succeeds and falls back to file copy with a warning if
permissions are insufficient.

**Alternatives considered**:
- Git `core.symlinks` config: rejected because it doesn't help with
  non-Git symlink targets like `.cursor/rules/main.mdc`.
- Junction points (Windows): rejected because they only work for
  directories, not files.
- Hardlinks: rejected because they don't survive Git operations
  (checkout, pull) and can't cross filesystems.

## R3: Claude Code Skill Format (SKILL.md)

**Decision**: Each skill is a directory containing a `SKILL.md` file
(natural language instructions in Markdown) plus an optional
`references/` subdirectory with supporting context files.

**Rationale**: This is the standard Claude Code skill format. Skills
are loaded by the agent at invocation time. The SKILL.md file
contains the complete workflow instructions, and references provide
domain-specific context (templates, checklists, examples).

**Key constraints**:
- SKILL.md MUST be self-contained enough to guide any LLM (not just
  Claude) — output must be consumable Markdown
- No compiled code or runtime dependencies in skills
- Skills should reference AGENTS.md conventions rather than
  duplicating them
- Each skill needs a YAML frontmatter block with `name`,
  `description`, and optional `trigger` conditions

**Alternatives considered**:
- Python scripts called by the agent: rejected because it adds
  runtime dependencies and breaks cross-agent compatibility.
- Custom MCP tool per skill: rejected because MCP tools are for
  system integrations, not developer workflow guidance.

## R4: Prompt Template Best Practices

**Decision**: Each prompt template is a standalone Markdown file in
`docs/prompts/` with a consistent structure: Purpose, Context
(references AGENTS.md), Prompt (the actual template with
placeholders), and Expected Output (what good output looks like).

**Rationale**: Prompt templates differ from skills — they are
single-use starting points, not multi-step workflows. Keeping them
as simple Markdown files means any agent can consume them (paste into
chat, reference as context, etc.).

**Key constraints**:
- Templates MUST reference "see AGENTS.md for conventions" rather
  than duplicating rules (single source of truth)
- Placeholders use `{VARIABLE_NAME}` format for clarity
- Each template includes one concrete example of expected output

**Alternatives considered**:
- Centralized prompt management tool (e.g., LangSmith): rejected as
  over-engineering for 5 templates (Principle VIII).
- Skills instead of prompts: rejected because prompts serve a
  different purpose (one-shot context injection vs. guided workflow).

## R5: MCP Server Scaffold Patterns (FastMCP 3.0)

**Decision**: The aperium-mcp-dev skill generates a directory
structure following FastMCP 3.0 HTTP transport patterns with the
team's established middleware chain.

**Rationale**: The team has standardized on FastMCP for all MCP
server development. The scaffold encodes the patterns from existing
servers (Odoo, Arena, Malbek) into a repeatable template.

**Standard scaffold structure**:
```
mcp-{service-name}/
├── src/
│   ├── server.py          # FastMCP server definition
│   ├── tools/             # Tool definitions (one per file)
│   ├── middleware/
│   │   ├── pii_masking.py # PII detection and masking
│   │   └── rbac.py        # Permission checks
│   └── config.py          # Environment config (Vault integration)
├── tests/
│   ├── integration/       # Full tool execution tests
│   └── unit/              # Middleware and utility tests
├── Dockerfile
├── docker-compose.yml
├── pyproject.toml
└── README.md
```

**Alternatives considered**:
- Cookiecutter template: rejected because it requires Python runtime
  and adds a dependency (skills are Markdown-only).
- Copier template: same objection as cookiecutter.
- The skill instructs the AI agent to generate the scaffold directly,
  which is more flexible and doesn't require template tooling.

## R6: Security Assessment Checklist (6-Layer + OWASP Agentic Top 10)

**Decision**: The aperium-security skill uses a structured checklist
approach with pass/fail/warning status for each item, organized in
two sections: the 6-layer defense model and OWASP Agentic Top 10.

**6-Layer Defense Checklist**:
1. Input validation — all user inputs and LLM outputs validated
2. Prompt injection detection — injection patterns checked
3. Tool permission check — RBAC verified before execution
4. Output validation — responses sanitized before display/action
5. Human approval — destructive actions require confirmation
6. Audit log — every tool invocation logged with context

**OWASP Agentic Top 10 (2025)**:
1. Prompt Injection
2. Broken Access Control
3. Data Poisoning
4. Insufficient Monitoring
5. Insecure Tool Use
6. Excessive Agency
7. Sensitive Information Disclosure
8. Supply Chain Vulnerabilities
9. Denial of Service
10. Improper Error Handling

**Report format**: Markdown table with columns: Check, Status
(PASS/FAIL/WARN), Evidence, Remediation.

**Alternatives considered**:
- Automated static analysis tool: rejected as out of scope for this
  kit (the skill guides human + AI review, not automated scanning).
- Integration with existing security tools (Snyk, Bandit): deferred
  to future enhancement; the skill focuses on agentic-specific
  concerns that these tools don't cover.

## R7: Workflow Guide Structure

**Decision**: Single `docs/workflow-guide.md` document organized by
the 4 MCP-DLC phases, with additional sections for prerequisites,
governance, and quick-reference cheat sheet.

**Document structure**:
1. Prerequisites & Setup (3-tier plugin installation)
2. Phase 1: Ideation & Ticket Creation
3. Phase 2: Spec-Driven Planning
4. Phase 3: Task Decomposition & Jira Sync
5. Phase 4: Implementation & Delivery
6. AGENTS.md Governance
7. Quick-Reference Cheat Sheet

**Rationale**: Matches the 4-phase MCP-DLC from the CTO advisory.
A single document (not a multi-file guide) keeps it simple and
searchable. The prerequisites section at the top ensures new
developers set up their environment before learning the workflow.

**Alternatives considered**:
- Multi-page documentation site (MkDocs, Docusaurus): rejected as
  over-engineering for one guide document (Principle VIII).
- Embedding in AGENTS.md: rejected because AGENTS.md must stay
  under 100 lines and is agent-focused, not human-focused.
