# Feature Specification: Custom Agent Kit

**Feature Branch**: `001-custom-agent-kit`
**Created**: 2026-03-11
**Status**: Draft
**Input**: User description: "Build custom agent kit for team as mentioned in cross_agent_consistency_mcp_dlc.docx"

## Clarifications

### Session 2026-03-11

- Q: Should the kit include an MCP-DLC workflow guide as a deliverable? → A: Yes — include as a full deliverable (new FR + user story scope expansion)
- Q: Should the kit include a starter prompt library (5 templates)? → A: Yes — include all 5 starter prompt templates as a kit deliverable
- Q: Should the kit include governance rules for AGENTS.md maintenance? → A: Yes — include in the workflow guide (ownership, sprint retro update cadence, PR-based review)
- Q: How should the kit handle multi-repo distribution? → A: Template kit — AGENTS.md is a template with per-repo customization; skills and prompts are shared from this dev-kit repo
- Q: Should the kit include a plugin installation guide for the 3-tier stack? → A: Yes — include as a prerequisites/setup section in the MCP-DLC workflow guide

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Single Source of Truth for Agent Instructions (Priority: P1)

A developer clones any Aperium repository and immediately has consistent
AI agent instructions regardless of which tool they use (Claude Code,
Copilot, Cursor/Augment, or Codex). They edit one file (`AGENTS.md`)
and every agent-specific config file reflects the change automatically.

**Why this priority**: Without a unified instruction file, every agent
produces code in its own style. This is the foundation that all other
kit components depend on — the CTO advisory identifies this as the
single most impactful change (29% faster agent runtime, 17% fewer
output tokens).

**Independent Test**: Can be fully tested by creating `AGENTS.md` in a
test repo, running the setup script, and verifying that Claude Code,
Copilot, Cursor, and Codex all read identical instructions. Delivers
immediate value: consistent code output from day one.

**Acceptance Scenarios**:

1. **Given** a freshly cloned Aperium repository, **When** a developer
   runs the setup script, **Then** symlinks are created for CLAUDE.md,
   CODEX.md, `.github/copilot-instructions.md`, and
   `.cursor/rules/main.mdc` all pointing to `AGENTS.md`
2. **Given** the symlinks are in place, **When** a developer edits
   `AGENTS.md`, **Then** every agent-specific config reflects the
   change without additional steps
3. **Given** a developer uses Claude Code, **When** they start a
   session, **Then** the agent reads the same conventions as a
   developer using Copilot or Augment in the same repo
4. **Given** AGENTS.md exists, **When** a developer needs
   tool-specific overrides, **Then** they can add them via the
   tool's native mechanism (e.g., `CLAUDE.local.md`,
   `.cursor/rules/*.mdc`) without modifying the shared file

---

### User Story 2 - Aperium Specification Skill (Priority: P2)

A developer wants to create a feature spec for a new Aperium feature.
They invoke a custom skill that pre-fills templates with
Aperium-specific architecture context (FastAPI, React, MCP servers,
PostgreSQL, Redis, Neo4j) and automatically includes security
considerations. The output follows the standard Speckit format so it
works with any agent.

**Why this priority**: The spec skill is the entry point to the
MCP-DLC workflow. It encodes team knowledge into a repeatable process,
eliminating the "ask the senior dev how we do specs" bottleneck.

**Independent Test**: Can be tested by invoking the skill with a
sample feature description and verifying the output contains
Aperium-specific architecture context, security section, and valid
Speckit-compatible Markdown in `docs/specs/<feature>/`.

**Acceptance Scenarios**:

1. **Given** a developer has the aperium-spec skill installed, **When**
   they invoke it with a feature description, **Then** a spec is
   generated with Aperium architecture context pre-filled (FastAPI
   backend, React frontend, MCP server integrations, data stores)
2. **Given** the skill generates a spec, **When** the spec is reviewed,
   **Then** it contains a mandatory security considerations section
   covering Zero Trust, PII handling, and RBAC
3. **Given** the generated spec, **When** it is consumed by Speckit's
   `/speckit.plan` command, **Then** planning proceeds without errors
   (format compatibility)

---

### User Story 3 - MCP Server Development Skill (Priority: P3)

A developer needs to create a new MCP server for a third-party
integration (e.g., a new ERP connector). They invoke the
aperium-mcp-dev skill which scaffolds a complete FastMCP server with
PII masking middleware, RBAC permission checks, integration test suite,
and Docker configuration — all following the team's established
patterns.

**Why this priority**: MCP server creation is a recurring task with
high boilerplate and strict security requirements. Codifying the
pattern eliminates the "reverse-engineer an existing server" problem
and prevents security gaps in new integrations.

**Independent Test**: Can be tested by invoking the skill with a
service name, verifying the scaffolded project structure includes all
required middleware, tests, and configuration, and confirming the
generated server passes lint and type checks.

**Acceptance Scenarios**:

1. **Given** a developer invokes the aperium-mcp-dev skill with a
   service name, **When** the scaffolding completes, **Then** a
   directory structure is created containing FastMCP server code,
   PII masking middleware, RBAC permission checks, and Docker config
2. **Given** the scaffolded server, **When** the developer runs the
   integration test suite, **Then** template tests pass and
   demonstrate the middleware chain (input validation, PII masking,
   RBAC check, output validation)
3. **Given** the scaffolded server, **When** it is registered in the
   MCP server registry, **Then** the registry documentation is
   updated automatically

---

### User Story 4 - Security Assessment Skill (Priority: P4)

A developer or reviewer wants to assess a new feature (especially
MCP integrations) against Aperium's 6-layer security model and
OWASP Agentic Top 10. They invoke the aperium-security skill which
performs an automated assessment and generates a structured report
identifying gaps.

**Why this priority**: Security assessment is mandatory for all
agentic features. A skill-based approach makes it repeatable and
ensures nothing is missed, reducing reliance on a single security
expert.

**Independent Test**: Can be tested by running the skill against an
existing MCP server or feature branch and verifying the report covers
all 6 defense layers and OWASP Agentic Top 10 items with
pass/fail/warning status for each.

**Acceptance Scenarios**:

1. **Given** a feature branch with agentic code, **When** the
   developer invokes the aperium-security skill, **Then** a security
   assessment report is generated covering all 6 defense layers
   (input validation, prompt injection detection, tool permission
   check, output validation, human approval, audit log)
2. **Given** the assessment identifies gaps, **When** the developer
   reviews the report, **Then** each gap has a specific remediation
   recommendation
3. **Given** an MCP server under assessment, **When** the skill
   checks PII handling, **Then** it verifies PII masking middleware
   is present and configured for all tools that handle user data

---

### User Story 5 - MCP-DLC Workflow Guide (Priority: P2)

A new or existing team member wants to understand how the entire
development lifecycle works end-to-end — from ticket creation through
spec generation, task decomposition, implementation, to delivery. They
read a single workflow guide that maps each of the 4 MCP-DLC phases to
the specific tools, skills, and actions required at each stage.

**Why this priority**: Same priority as the aperium-spec skill because
the workflow guide is what ties all kit components together into the
unified lifecycle the CTO advisory calls for. Without it, skills exist
in isolation and the team lacks the "single spec-driven lifecycle."

**Independent Test**: Can be tested by giving the guide to a developer
unfamiliar with the workflow and verifying they can identify which
tool/skill to use at each phase, and successfully walk through a
sample feature from ticket to deployment.

**Acceptance Scenarios**:

1. **Given** a developer reads the MCP-DLC workflow guide, **When**
   they reach Phase 1 (Ideation & Ticket Creation), **Then** the
   guide describes how to use AI agents + Jira MCP to create
   structured tickets with a draft-first review pattern
2. **Given** a developer is in Phase 2 (Spec-Driven Planning),
   **When** they follow the guide, **Then** it directs them to use
   the aperium-spec skill (or Speckit/Superpowers) and explains how
   to produce the three spec artifacts
3. **Given** a developer completes Phase 3 (Task Decomposition),
   **When** tasks.md is generated, **Then** the guide explains how
   to sync tasks to Jira tickets with intermediate review
4. **Given** a developer is in Phase 4 (Implementation & Delivery),
   **When** they follow the guide, **Then** it maps agent-specific
   implementation patterns (Augment, Claude Code, Copilot, Codex)
   and explains the PR → merge → deploy → Jira status update loop
5. **Given** a team completes a sprint, **When** they hold the
   retrospective, **Then** the guide defines who updates AGENTS.md
   (tech lead), what triggers updates (new patterns, pitfalls,
   conventions), and that changes require PR-based review
6. **Given** a new developer joins the team, **When** they read the
   workflow guide prerequisites section, **Then** they find a 3-tier
   plugin list with install instructions for each tool (Tier 1: all
   members, Tier 2: role-specific, Tier 3: custom Aperium skills)

---

### User Story 6 - Starter Prompt Library (Priority: P3)

A developer working on a common task (new API endpoint, new MCP tool,
new React component, debugging, or security review) wants a proven
prompt template rather than writing one from scratch. They open the
`docs/prompts/` directory and find a ready-to-use template that
includes Aperium-specific context and produces consistent results
across any AI agent.

**Why this priority**: Same priority as MCP server skill — the prompt
library is a quick-win knowledge sharing mechanism referenced in both
the dev process doc and the CTO advisory. It reduces prompt
variability and encodes team best practices.

**Independent Test**: Can be tested by having a developer use each
template with at least 2 different AI agents and verifying the output
follows Aperium conventions and includes all expected sections.

**Acceptance Scenarios**:

1. **Given** a developer needs to create a new FastAPI endpoint,
   **When** they use the `new-api-endpoint.md` template, **Then** the
   AI output follows Aperium conventions (async, typed, Depends(),
   Google-style docstrings)
2. **Given** a developer needs to add a new MCP tool, **When** they
   use the `new-mcp-tool.md` template, **Then** the output includes
   PII masking, RBAC checks, input validation, and error handling
3. **Given** a developer uses any prompt template with Copilot vs.
   Claude Code, **When** both outputs are compared, **Then** both
   follow the same conventions defined in AGENTS.md

---

### Edge Cases

- What happens when a developer has existing tool-specific config
  files that conflict with the symlink setup? (Setup script detects
  conflicts and prompts the developer to back up or merge.)
- What happens when symlink target paths differ across operating
  systems (Windows vs. Linux/macOS)? (Setup script uses
  platform-appropriate symlink commands.)
- What happens when the MCP server scaffold is invoked for an
  integration type not yet supported (e.g., SOAP vs. REST)?
  (Skill defaults to REST/HTTP transport and warns about
  unsupported types.)
- What happens when the security assessment runs against code that
  has no agentic features? (Produces a clean "not applicable" report
  rather than errors.)
- What happens when AGENTS.md grows beyond the recommended 80-100
  lines? (Linting warns that the file exceeds the recommended size
  and suggests moving detail to linked reference docs.)
- What happens when the shared AGENTS.md template in the dev-kit
  repo is updated but downstream repos have already customized their
  copy? (The template uses clearly marked fixed vs. customizable
  sections; a diff/merge guide is included in the workflow docs.)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The kit MUST include a canonical `AGENTS.md` file
  containing project identity, architecture overview, coding
  conventions, forbidden patterns, build/test commands, and security
  requirements (~80-100 lines of human-written context)
- **FR-002**: The kit MUST include a setup script that creates
  symlinks from all agent-specific config files to `AGENTS.md`
  (CLAUDE.md, CODEX.md, .github/copilot-instructions.md,
  .cursor/rules/main.mdc)
- **FR-003**: The setup script MUST work on Linux, macOS, and Windows
- **FR-004**: The kit MUST include a `.gitignore` configuration that
  tracks `AGENTS.md` and handles symlinked files appropriately
- **FR-005**: The `aperium-spec` skill MUST generate specs in
  Speckit-compatible Markdown format with Aperium-specific
  architecture context pre-filled
- **FR-006**: The `aperium-spec` skill MUST include a mandatory
  security considerations section in every generated spec
- **FR-007**: The `aperium-mcp-dev` skill MUST scaffold a FastMCP
  server with PII masking middleware, RBAC permission checks,
  integration test suite, and Docker configuration
- **FR-008**: The `aperium-mcp-dev` skill MUST register new servers
  in the MCP server registry documentation
- **FR-009**: The `aperium-security` skill MUST assess features
  against all 6 layers of Aperium's defense model
- **FR-010**: The `aperium-security` skill MUST check for OWASP
  Agentic Top 10 compliance
- **FR-011**: The `aperium-security` skill MUST generate a structured
  report with pass/fail/warning status per check and remediation
  recommendations for failures
- **FR-012**: The kit MUST include an MCP-DLC workflow guide that
  maps all 4 phases (Ideation & Ticket Creation, Spec-Driven
  Planning, Task Decomposition & Jira Sync, Implementation &
  Delivery) to specific tools, skills, and actions
- **FR-013**: The workflow guide MUST include agent-specific
  implementation patterns for Augment, Claude Code, Copilot, and
  Codex
- **FR-013a**: The workflow guide MUST include AGENTS.md governance
  rules: designated ownership (tech lead), sprint retro update
  cadence (15-30 min per sprint), and PR-based review for all
  changes to AGENTS.md
- **FR-013b**: The workflow guide MUST include a prerequisites/setup
  section with 3-tier plugin installation instructions: Tier 1 (all
  members: Superpowers, Speckit, Context7, Frontend Design,
  Playwright), Tier 2 (role-specific: Atlassian Rovo MCP, Commit
  Commands, Feature Dev), Tier 3 (custom Aperium skills)
- **FR-014**: The kit MUST include a starter prompt library in
  `docs/prompts/` with 5 templates: `new-api-endpoint.md`,
  `new-mcp-tool.md`, `new-react-component.md`, `debug-template.md`,
  and `security-review.md`
- **FR-015**: Each prompt template MUST include Aperium-specific
  context (stack, conventions, security requirements) and produce
  output consistent with AGENTS.md conventions
- **FR-016**: The kit MUST include an AGENTS.md template with
  customizable sections (project identity, architecture overview) and
  fixed sections (coding conventions, forbidden patterns, security
  rules) so each repo can tailor context while inheriting shared
  standards
- **FR-017**: Skills and prompt templates MUST be shared from this
  dev-kit repo (central source); individual repos reference or
  install them rather than maintaining independent copies
- **FR-018**: The setup script MUST support bootstrapping a new repo
  from the AGENTS.md template (copy template, create symlinks,
  install skills)
- **FR-019**: All three custom skills MUST be stored in a standard
  skill directory structure and be installable across the team
- **FR-020**: All three custom skills MUST work with Claude Code and
  produce output consumable by other agents (Copilot, Codex, Augment)

### Key Entities

- **AGENTS.md**: The canonical agent instruction file per repository.
  Created from a shared template in this dev-kit repo, customized
  with per-repo project identity and architecture, while inheriting
  fixed conventions and security rules. Single source of truth for
  all AI coding agents in each repository.
- **Skill**: A self-contained package (SKILL.md + optional reference
  files + optional scripts) that encodes team-specific knowledge into
  an executable workflow any AI agent can follow.
- **MCP Server Scaffold**: A template project structure for new FastMCP
  integrations including middleware, tests, and deployment config.
- **Security Assessment Report**: A structured document produced by the
  security skill covering 6-layer defense and OWASP compliance with
  per-check status and remediation guidance.

### Assumptions

- The team uses Git for version control with branch-based workflows
- All developers have at least one AI coding agent installed
  (Claude Code, Copilot, Augment, or Codex)
- The Speckit and Superpowers plugins are installed per the CTO
  advisory (Tier 1 recommended stack)
- FastMCP 3.0 HTTP transport patterns are the established standard
  for MCP server development
- HashiCorp Vault is the secrets management solution (no env vars
  or in-code secrets)
- The team follows conventional commits and the branch naming
  convention defined in the constitution
- Skills are authored as Markdown-based instruction files (SKILL.md
  format) compatible with Claude Code's skill system

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Any developer can set up consistent agent instructions
  in a new or existing repo in under 5 minutes by running the setup
  script
- **SC-002**: Code produced by different AI agents in the same repo
  follows identical conventions (verifiable by running lint + type
  checks on output from at least 2 different agents)
- **SC-003**: A new feature spec generated via the aperium-spec skill
  includes all mandatory sections (architecture context, security
  considerations, Speckit-compatible format) without manual editing
  of boilerplate
- **SC-004**: A new MCP server can be scaffolded and pass lint + type
  checks within 10 minutes of invoking the aperium-mcp-dev skill
- **SC-005**: Security assessments cover 100% of the 6-layer defense
  model checks and all applicable OWASP Agentic Top 10 items
- **SC-006**: Time from feature idea to structured spec reduces by at
  least 50% compared to manual spec writing
- **SC-007**: Team onboarding time for "how do we build MCP servers"
  reduces from tribal knowledge transfer to under 15 minutes with
  the skill
