# Tasks: Custom Agent Kit

**Input**: Design documents from `/specs/001-custom-agent-kit/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: No test tasks included — not requested in the feature specification. Validation is manual (skill output review, script smoke tests).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Kit root**: repository root (`c:\Dev\Aperium_Workspaces\aperium-dev-kit\`)
- **Templates**: `templates/`
- **Skills**: `skills/{skill-name}/`
- **Docs**: `docs/`

---

## Phase 1: Setup

**Purpose**: Create directory structure for all kit deliverables

- [x] T001 Create kit directory structure: `templates/`, `skills/aperium-spec/references/`, `skills/aperium-mcp-dev/references/`, `skills/aperium-security/references/`, `docs/prompts/`
- [x] T002 [P] Create `.gitignore.template` in `templates/.gitignore.template` with rules to track AGENTS.md and handle symlinked files (CLAUDE.md, CODEX.md, .github/copilot-instructions.md, .cursor/rules/main.mdc)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create the AGENTS.md template — all skills, prompts, and the workflow guide reference it

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Write AGENTS.md template in `templates/AGENTS.md.template` with 6 sections: Project Identity (CUSTOMIZABLE), Architecture Overview (CUSTOMIZABLE), Coding Conventions (FIXED), Forbidden Patterns (FIXED), Build & Test Commands (CUSTOMIZABLE), Security Requirements (FIXED). Use `<!-- CUSTOMIZABLE -->` and `<!-- FIXED -->` comment markers per contracts/agents-md-template-format.md. Target 80-100 lines total. Include version tracking comment at bottom: `<!-- aperium-dev-kit template version: {GIT_SHA} -->`

**Checkpoint**: AGENTS.md template ready — user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Single Source of Truth (Priority: P1) MVP

**Goal**: Developer can bootstrap any repo with consistent agent instructions via a single setup script

**Independent Test**: Run setup script in a test repo, verify all 4 symlinks point to AGENTS.md, verify editing AGENTS.md propagates to all symlinked files

- [x] T004 [US1] Write Bash setup script in `templates/setup.sh` that: (1) accepts target repo path as argument, (2) copies AGENTS.md.template to target as AGENTS.md, (3) creates symlinks for CLAUDE.md, CODEX.md, .github/copilot-instructions.md, and .cursor/rules/main.mdc all pointing to AGENTS.md, (4) creates required directories (.github/, .cursor/rules/), (5) appends .gitignore.template rules to target .gitignore, (6) detects existing config files and prompts before overwriting, (7) reports success/failure for each step
- [x] T005 [P] [US1] Write PowerShell setup script in `templates/setup.ps1` that mirrors setup.sh functionality for Windows: uses `New-Item -ItemType SymbolicLink` for symlinks, falls back to file copy with warning if symlink creation fails (permissions), same conflict detection and reporting behavior
- [x] T006 [US1] Add `--update` flag to both setup scripts (`templates/setup.sh` and `templates/setup.ps1`) that: (1) diffs FIXED sections in existing AGENTS.md against template source, (2) updates FIXED sections while preserving CUSTOMIZABLE sections, (3) copies updated skills and prompts to target repo

**Checkpoint**: At this point, User Story 1 should be fully functional — a developer can run the setup script and get consistent agent instructions across all tools

---

## Phase 4: User Story 2 - Aperium Specification Skill (Priority: P2)

**Goal**: Developer invokes aperium-spec skill and gets an Aperium-context-prefilled spec in Speckit format

**Independent Test**: Invoke the skill with a sample feature description, verify output contains architecture context, security section, and valid Speckit Markdown

### Implementation for User Story 2

- [x] T007 [P] [US2] Write architecture context reference file in `skills/aperium-spec/references/architecture-context.md` containing Aperium platform overview: FastAPI backend, React frontend, MCP servers (Odoo, Arena, Malbek), PostgreSQL + Redis + Neo4j, Vertex AI + BigQuery, and service interaction patterns
- [x] T008 [P] [US2] Write security template reference file in `skills/aperium-spec/references/security-template.md` containing mandatory security considerations section template: Zero Trust patterns, PII handling requirements, RBAC enforcement rules, 6-layer defense model checklist items
- [x] T009 [P] [US2] Write spec sections reference file in `skills/aperium-spec/references/spec-sections.md` containing Speckit-compatible section templates pre-filled with Aperium-specific placeholders for each mandatory section (User Scenarios, Requirements, Success Criteria)
- [x] T010 [US2] Write SKILL.md in `skills/aperium-spec/SKILL.md` with YAML frontmatter (name: aperium-spec, description, trigger), Purpose, Prerequisites (AGENTS.md must exist), Workflow (step-by-step: accept feature description, load architecture context from references/, generate spec with security section, output to docs/specs/{feature}/spec.md), Output section. Reference AGENTS.md for conventions rather than duplicating

**Checkpoint**: At this point, User Story 2 should be fully functional — the aperium-spec skill produces Speckit-compatible specs with Aperium context

---

## Phase 5: User Story 5 - MCP-DLC Workflow Guide (Priority: P2)

**Goal**: Team has a single reference document mapping the 4-phase development lifecycle to tools, skills, and actions

**Independent Test**: Give the guide to a developer unfamiliar with the workflow, verify they can identify the correct tool/skill at each phase

### Implementation for User Story 5

- [x] T011 [US5] Write MCP-DLC workflow guide in `docs/workflow-guide.md` with 7 sections per research.md R7: (1) Prerequisites & Setup with 3-tier plugin installation (Tier 1: Superpowers, Speckit, Context7, Frontend Design, Playwright; Tier 2: Atlassian Rovo MCP, Commit Commands, Feature Dev; Tier 3: aperium-spec, aperium-mcp-dev, aperium-security), (2) Phase 1: Ideation & Ticket Creation with Jira MCP + draft-first pattern, (3) Phase 2: Spec-Driven Planning with aperium-spec/Speckit/Superpowers, (4) Phase 3: Task Decomposition & Jira Sync with intermediate review, (5) Phase 4: Implementation & Delivery with agent-specific patterns (Augment, Claude Code, Copilot, Codex), (6) AGENTS.md Governance with ownership (tech lead), sprint retro update cadence (15-30 min), PR-based review, (7) Quick-Reference Cheat Sheet

**Checkpoint**: At this point, User Story 5 should be fully functional — new and existing developers can follow the complete MCP-DLC lifecycle

---

## Phase 6: User Story 3 - MCP Server Development Skill (Priority: P3)

**Goal**: Developer invokes aperium-mcp-dev skill and gets a complete FastMCP server scaffold

**Independent Test**: Invoke the skill with a service name, verify scaffolded structure includes all required middleware, tests, and config

### Implementation for User Story 3

- [x] T012 [P] [US3] Write scaffold structure reference file in `skills/aperium-mcp-dev/references/scaffold-structure.md` containing the complete directory tree for a new MCP server per research.md R5: src/server.py, src/tools/, src/middleware/pii_masking.py, src/middleware/rbac.py, src/config.py, tests/integration/, tests/unit/, Dockerfile, docker-compose.yml, pyproject.toml, README.md
- [x] T013 [P] [US3] Write middleware patterns reference file in `skills/aperium-mcp-dev/references/middleware-patterns.md` containing PII masking middleware template (detection patterns, masking rules, logging), RBAC permission check template (role lookup, permission verification, denial handling), and input validation patterns
- [x] T014 [P] [US3] Write test patterns reference file in `skills/aperium-mcp-dev/references/test-patterns.md` containing integration test templates (happy-path tool execution, error-path handling, middleware chain verification) and unit test templates (PII detection, RBAC rules, config loading)
- [x] T015 [US3] Write SKILL.md in `skills/aperium-mcp-dev/SKILL.md` with YAML frontmatter (name: aperium-mcp-dev, description, trigger), Purpose, Prerequisites, Workflow (accept service name, generate scaffold using references, configure Docker, create pyproject.toml with Aperium dependencies, register in MCP server registry), Output section

**Checkpoint**: At this point, User Story 3 should be fully functional — the aperium-mcp-dev skill scaffolds complete MCP servers

---

## Phase 7: User Story 6 - Starter Prompt Library (Priority: P3)

**Goal**: Developers have 5 proven prompt templates for common tasks

**Independent Test**: Use each template with 2 different AI agents, verify output follows AGENTS.md conventions

### Implementation for User Story 6

- [x] T016 [P] [US6] Write prompt template in `docs/prompts/new-api-endpoint.md` per contracts/prompt-template-format.md: Purpose (FastAPI endpoint generation), Context (reference AGENTS.md), Prompt (with placeholders: {RESOURCE_NAME}, {OPERATIONS}, {URL_PATH}, {MODEL_NAME}), Expected Output (async def, type hints, Depends(), Google docstrings), Example (concrete user endpoint)
- [x] T017 [P] [US6] Write prompt template in `docs/prompts/new-mcp-tool.md` per contracts/prompt-template-format.md: Purpose (MCP tool creation), Context (reference AGENTS.md + MCP conventions), Prompt (with placeholders: {SERVICE_NAME}, {TOOL_NAME}, {DESCRIPTION}), Expected Output (FastMCP tool def, PII masking, RBAC, input validation, error handling), Example (concrete Odoo tool)
- [x] T018 [P] [US6] Write prompt template in `docs/prompts/new-react-component.md` per contracts/prompt-template-format.md: Purpose (React component with tests), Context (reference AGENTS.md + TS/React conventions), Prompt (with placeholders: {COMPONENT_NAME}, {PROPS}, {PURPOSE}), Expected Output (functional component, hooks, Zustand, co-located test), Example (concrete dashboard widget)
- [x] T019 [P] [US6] Write prompt template in `docs/prompts/debug-template.md` per contracts/prompt-template-format.md: Purpose (structured debugging), Context (reference AGENTS.md), Prompt (with placeholders: {ERROR_MESSAGE}, {EXPECTED_BEHAVIOR}, {CONTEXT}), Expected Output (root cause analysis, fix proposal, verification steps), Example (concrete async bug)
- [x] T020 [P] [US6] Write prompt template in `docs/prompts/security-review.md` per contracts/prompt-template-format.md: Purpose (AI-assisted security review), Context (reference AGENTS.md + 6-layer defense model), Prompt (with placeholders: {FEATURE_NAME}, {FILES_TO_REVIEW}, {SCOPE}), Expected Output (OWASP checklist, PII assessment, RBAC verification), Example (concrete MCP tool review)

**Checkpoint**: All 5 prompt templates complete — developers can use them with any AI agent

---

## Phase 8: User Story 4 - Security Assessment Skill (Priority: P4)

**Goal**: Developer invokes aperium-security skill and gets a structured security assessment report

**Independent Test**: Run skill against an existing MCP server, verify report covers all 6 defense layers and OWASP Agentic Top 10 items

### Implementation for User Story 4

- [x] T021 [P] [US4] Write 6-layer checklist reference file in `skills/aperium-security/references/6-layer-checklist.md` containing detailed assessment criteria for each layer: (1) Input Validation — check items, evidence patterns, common failures; (2) Prompt Injection Detection — patterns to check, testing methods; (3) Tool Permission Check — RBAC verification steps; (4) Output Validation — sanitization checks; (5) Human Approval — destructive action gates; (6) Audit Log — logging completeness checks
- [x] T022 [P] [US4] Write OWASP Agentic Top 10 reference file in `skills/aperium-security/references/owasp-agentic-top10.md` containing assessment criteria for all 10 items per research.md R6: Prompt Injection, Broken Access Control, Data Poisoning, Insufficient Monitoring, Insecure Tool Use, Excessive Agency, Sensitive Information Disclosure, Supply Chain Vulnerabilities, Denial of Service, Improper Error Handling — with check procedure, evidence requirements, and remediation templates for each
- [x] T023 [P] [US4] Write report template reference file in `skills/aperium-security/references/report-template.md` containing the Markdown report structure per data-model.md Entity 6: header with date/assessor/scope, 6-Layer Defense Model table (Layer, Status, Evidence, Remediation), OWASP Agentic Top 10 table (Check, Status, Evidence, Remediation), Summary section
- [x] T024 [US4] Write SKILL.md in `skills/aperium-security/SKILL.md` with YAML frontmatter (name: aperium-security, description, trigger), Purpose, Prerequisites (codebase to assess), Workflow (accept scope/feature name, load checklists from references, systematically assess each 6-layer item, assess each OWASP item, generate report using report template, output to docs/security/assessment-{date}.md), Output section

**Checkpoint**: All user stories should now be independently functional

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Validation, documentation updates, and cross-story integration

- [x] T025 Review all 3 SKILL.md files (`skills/aperium-spec/SKILL.md`, `skills/aperium-mcp-dev/SKILL.md`, `skills/aperium-security/SKILL.md`) for consistent format: verify YAML frontmatter, required sections (Purpose, Prerequisites, Workflow, Output), AGENTS.md references (not convention duplication), and cross-agent compatibility (no Claude-specific syntax)
- [x] T026 [P] Review all 5 prompt templates in `docs/prompts/` for consistent format per contracts/prompt-template-format.md: verify Purpose, Context (AGENTS.md reference), Prompt ({PLACEHOLDER} format), Expected Output, and Example sections
- [x] T027 [P] Validate AGENTS.md template in `templates/AGENTS.md.template`: verify line count is 80-100, all 6 sections present, CUSTOMIZABLE/FIXED markers correct, no empty sections, version tracking comment present
- [x] T028 [P] Validate setup scripts (`templates/setup.sh` and `templates/setup.ps1`): verify both scripts accept target repo path, create all 4 symlinks, handle conflict detection, support --update flag, report success/failure
- [x] T029 Update `docs/workflow-guide.md` to cross-reference all completed kit components: link to each skill by name with invocation syntax, link to prompt library, link to setup script instructions
- [x] T030 Run quickstart.md validation: walk through `specs/001-custom-agent-kit/quickstart.md` end-to-end in a fresh test directory to verify the bootstrap flow works as documented

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup (T001) — BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase (T003) completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3 → P4)
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) — No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) — Independent of US1 (skill doesn't need setup script)
- **User Story 5 (P2)**: Can start after Foundational (Phase 2) — References skills by name but doesn't require them to exist yet
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) — Independent of other skills
- **User Story 6 (P3)**: Can start after Foundational (Phase 2) — Independent of skills
- **User Story 4 (P4)**: Can start after Foundational (Phase 2) — Independent of other skills

### Within Each User Story

- Reference files (marked [P]) before SKILL.md (SKILL.md references them)
- SKILL.md last within each skill (depends on all reference files)
- Prompt templates are all independent (all [P])

### Parallel Opportunities

- T001 and T002 can run in parallel (Phase 1)
- T004 and T005 can run in parallel (US1 setup scripts)
- T007, T008, T009 can run in parallel (US2 reference files)
- T012, T013, T014 can run in parallel (US3 reference files)
- T016, T017, T018, T019, T020 can ALL run in parallel (US6 prompt templates)
- T021, T022, T023 can run in parallel (US4 reference files)
- T025, T026, T027, T028 can run in parallel (Polish validation)
- **All user stories (Phases 3-8) can run in parallel** once Foundational completes

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T002)
2. Complete Phase 2: Foundational — AGENTS.md template (T003)
3. Complete Phase 3: User Story 1 — setup scripts (T004-T006)
4. **STOP and VALIDATE**: Run setup script in a test repo, verify symlinks
5. Deploy/demo if ready — team can start using consistent AGENTS.md immediately

### Incremental Delivery

1. Setup + Foundational → AGENTS.md template ready
2. Add US1 (setup scripts) → Deploy (MVP! Teams can bootstrap repos)
3. Add US2 (aperium-spec) + US5 (workflow guide) → Deploy (spec workflow enabled)
4. Add US3 (aperium-mcp-dev) + US6 (prompt library) → Deploy (MCP scaffolding + prompts)
5. Add US4 (aperium-security) → Deploy (full kit complete)
6. Polish → Final validation and cross-references

### Parallel Team Strategy

With multiple developers (or subagents):

1. Team completes Setup + Foundational together (T001-T003)
2. Once Foundational is done:
   - Developer A: US1 (setup scripts) + US5 (workflow guide)
   - Developer B: US2 (aperium-spec) + US3 (aperium-mcp-dev)
   - Developer C: US4 (aperium-security) + US6 (prompt library)
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All deliverables are Markdown + shell scripts — no build step required
