# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

This is the **Aperium Dev Kit** — a reference workspace containing process documentation for the Aperium AI Agent Platform engineering team. It is NOT a code repository. It contains:

- `aperium_dev_process.docx` — The team's spec-driven vibe coding standard (development workflow, quality gates, automation strategy)
- `cross_agent_consistency_mcp_dlc.docx` — CTO advisory on cross-agent consistency, MCP-driven development lifecycle, and custom skill architecture

These documents define how all Aperium repositories should be developed and maintained.

## Aperium Platform Architecture

The platform is a multi-service enterprise agentic system:

- **Backend**: FastAPI (Python, async-first)
- **Frontend**: React (TypeScript, strict mode)
- **MCP Servers**: FastMCP — integrations with Odoo ERP, Arena PLM, Malbek CLM
- **Data Stores**: PostgreSQL, Redis, Neo4j
- **AI/ML**: Vertex AI, BigQuery pipelines, Cloud Functions

## Coding Conventions (All Aperium Repos)

### Python (FastAPI Backend)
- Async-first (`async def` for all I/O-bound operations)
- Type hints on all function signatures (mypy strict mode)
- Google-style docstrings on public functions/classes
- No `Any` types unless genuinely unavoidable
- Dependency injection via FastAPI's `Depends()` pattern
- Ruff for linting and formatting (PEP 8)

### TypeScript / React (Frontend)
- `"strict": true` in tsconfig
- Functional components with hooks only (no class components)
- Zustand for state management, TanStack Query for server state
- One component per file, co-located tests
- No `any` types; use `unknown` and type narrowing

### MCP Server Development
- FastMCP patterns for tool definitions
- PII masking middleware on all tools handling user data
- RBAC permission checks before tool execution
- Input validation, error handling, timeout configuration on every tool
- Each MCP server has its own integration test suite

### Forbidden Patterns
- `Any`/`any` types (except where genuinely unavoidable)
- Synchronous I/O in async code paths
- Inline SQL (use ORM/query builder)
- Secrets in code or environment variables (use HashiCorp Vault)
- Class components in React
- `localStorage` usage

## Build & Test Commands (Platform Repos)

```bash
# Python backend
ruff check . && ruff format --check .   # lint + format check
mypy .                                   # type checking
pytest --cov                             # tests with coverage

# Frontend
npm run lint && npm run typecheck        # lint + TS check
npm run test                             # unit tests (Vitest)

# E2E
npx playwright test                      # end-to-end tests
```

Coverage requirements: 80% for new code, 95% for critical paths (auth, payments, data integrity).

## Spec-Driven Development Workflow

Every non-trivial task produces three Markdown files in `docs/specs/<feature-name>/`:

1. **`requirements.md`** — User story, acceptance criteria, edge cases, out-of-scope
2. **`design.md`** — Architecture decisions, component interactions, data model changes, security considerations
3. **`tasks.md`** — Numbered task list with complexity (S/M/L), dependencies, test criteria, suggested AI tool

Specs are committed to the feature branch before coding begins.

## Cross-Agent Consistency Strategy

All Aperium repos use **AGENTS.md** as the single source of truth, symlinked to agent-specific config files:

```bash
ln -sfn AGENTS.md CLAUDE.md
ln -sfn AGENTS.md CODEX.md
mkdir -p .github && ln -sfn ../AGENTS.md .github/copilot-instructions.md
mkdir -p .cursor/rules && ln -sfn ../../AGENTS.md .cursor/rules/main.mdc
```

## Git Conventions

- Branch naming: `feature/<ticket-id>-<short-description>` or `fix/<ticket-id>-<short-description>`
- Commit format: conventional commits — `type(scope): description`
- Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `security`
- Squash-merge to develop; deploy to staging; E2E; then production

## AI Tool Selection

| Task | Primary Tool |
|------|-------------|
| Complex features | Augment Code + Claude Code for architecture |
| Simple features | Copilot Agent Mode or Augment |
| Spec generation | Claude Chat or Speckit |
| Deep debugging | Claude Code |
| Test generation | Codex (async) or Copilot |
| Security audit | Claude Code with security skill |
| Refactoring | Augment Code (multi-file awareness) |
| Urgent hotfix | Copilot Agent Mode + express review |

## Custom Skills (Planned/In Progress)

- **aperium-spec** — Aperium-specific spec templates + Jira MCP integration
- **aperium-mcp-dev** — MCP server scaffolding with PII/RBAC/test patterns
- **aperium-security** — Zero Trust assessment, OWASP Agentic Top 10 compliance
- **aperium-jira-sync** — Bidirectional spec-to-Jira synchronization

## Security Model (6-Layer Defense)

All agentic features must implement: input validation -> prompt injection detection -> tool permission check -> output validation -> human approval for destructive actions -> audit log. Any PR touching auth, authorization, MCP permissions, or data access requires mandatory security review.
