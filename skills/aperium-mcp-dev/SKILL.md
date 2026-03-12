---
name: aperium-mcp-dev
description: Use when creating a new MCP server for a third-party integration, when a FastMCP scaffold with PII masking, RBAC, tests, and Docker configuration following Aperium patterns is needed
---

# Aperium MCP Server Development Skill

## Purpose

Scaffold a complete FastMCP server with PII masking middleware, RBAC permission checks, integration test suite, and Docker configuration following Aperium patterns defined in AGENTS.md.

## Prerequisites

- AGENTS.md must exist in the target repository
- Python 3.11+ environment
- Target integration service identified (e.g., Odoo ERP, Arena PLM)

## When to Use

- Creating a new MCP server for any third-party integration
- Need a FastMCP scaffold with security middleware pre-configured
- Want PII masking and RBAC patterns from existing Aperium servers
- Starting an integration with Odoo, Arena, Malbek, or any new service

## Workflow

1. **Accept service name** from the developer (e.g., "arena-plm", "odoo-erp")
2. **Load scaffold structure** from `references/scaffold-structure.md`
3. **Generate project directory** `mcp-{service-name}/`:
   - `src/server.py` — FastMCP server definition with middleware chain
   - `src/middleware/pii_masking.py` — patterns from `references/middleware-patterns.md`
   - `src/middleware/rbac.py` — patterns from `references/middleware-patterns.md`
   - `src/config.py` — HashiCorp Vault integration pattern
   - `src/tools/` — sample tool file
4. **Generate test suite** using `references/test-patterns.md`:
   - `tests/integration/` — tool execution test templates
   - `tests/unit/` — middleware unit test templates
5. **Generate configuration files**:
   - `pyproject.toml` — fastmcp>=3.0, pydantic, hvac, pytest, ruff, mypy
   - `Dockerfile` — multi-stage build, non-root user, health check
   - `docker-compose.yml` — local development setup
   - `README.md` — service documentation
   - `.env.example` — required environment variables (no secrets)
6. **Register** the server in MCP registry if applicable
7. **Report** scaffolded directory and suggest next steps

## Output

| Input | Output |
|-------|--------|
| Service name (e.g., "arena-plm") | `mcp-arena-plm/` directory with ~15 files |
| Middleware patterns (auto-loaded) | PII masking + RBAC pre-configured |
| Test patterns (auto-loaded) | Integration + unit test suite |

## References

- `references/scaffold-structure.md` — directory tree and file descriptions
- `references/middleware-patterns.md` — PII masking, RBAC, input validation
- `references/test-patterns.md` — integration and unit test templates

## Common Mistakes

- Forgetting PII masking middleware on tools handling user data
- Hardcoding secrets instead of using Vault integration
- Skipping RBAC checks on "internal-only" tools
- Not creating integration tests for the middleware chain
- Using synchronous I/O in async tool handlers
