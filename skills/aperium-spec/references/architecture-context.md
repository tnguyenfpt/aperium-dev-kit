# Aperium Platform Architecture Context

> This file is loaded by the aperium-spec skill as pre-filled context when generating
> feature specifications. Keep it concise and current.

## Platform Overview

Aperium is a multi-service enterprise agentic system designed for AI-powered business
process automation. It connects business applications (ERP, PLM, CLM) through an
intelligent orchestration layer that enables autonomous and human-in-the-loop workflows.

## Service Architecture

### Backend — FastAPI (Python 3.11+, async-first)

- Central business logic and API gateway
- Async-first design for all I/O-bound operations
- Dependency injection via FastAPI `Depends()` pattern
- Type-checked with mypy strict mode

### Frontend — React (TypeScript, strict mode)

- Web application and operational dashboards
- Functional components with hooks (no class components)
- Zustand for state management, TanStack Query for server state

### MCP Servers — FastMCP (Integration Layer)

Each MCP server wraps an external system and exposes tools via the MCP protocol:

- **Odoo ERP**: Procurement, inventory, manufacturing operations
- **Arena PLM**: Product lifecycle management, BOM management, change orders
- **Malbek CLM**: Contract lifecycle management, clause extraction, approval workflows

All MCP servers enforce PII masking middleware and RBAC permission checks on every tool.

### AI/ML Pipeline

- **Vertex AI**: Model serving and inference (LLM orchestration, embeddings)
- **BigQuery**: Analytics pipelines, usage metrics, business intelligence
- **Cloud Functions**: Event-driven processing, async job execution

## Data Stores

| Store          | Role                                                    |
|----------------|---------------------------------------------------------|
| **PostgreSQL** | Primary relational data (users, configs, business entities) |
| **Redis**      | Caching, session management, real-time state            |
| **Neo4j**      | Knowledge graphs, relationship mapping, entity resolution |

## Infrastructure

- **Secrets Management**: HashiCorp Vault — no env vars, no in-code secrets
- **Deployment**: Docker containers orchestrated via CI/CD with GitHub Actions
- **Monitoring**: Structured logging (JSON), distributed tracing across services
- **Environments**: Development, staging (E2E-gated), production

## Service Interaction Patterns

```
Frontend  <--REST + WebSocket-->  Backend (FastAPI)
                                     |
                          MCP Protocol (tool invocation)
                                     |
                     +---------------+---------------+
                     |               |               |
                  Odoo MCP       Arena MCP      Malbek MCP
                     |               |               |
                  Odoo ERP      Arena PLM      Malbek CLM
```

- **Frontend to Backend**: REST API for CRUD, WebSocket for real-time updates
- **Backend to MCP Servers**: Tool invocation via MCP protocol with structured payloads
- **MCP Servers to External Systems**: Authenticated HTTP/REST with timeout and retry
- **All inter-service communication** uses structured error handling and correlation IDs

## Key Conventions

- See `AGENTS.md` in each repository for coding standards — do not duplicate here
- All new services follow the architecture patterns described above
- Every MCP server includes PII masking + RBAC middleware as non-negotiable baseline
- Security model enforces 6-layer defense: input validation, prompt injection detection,
  tool permission check, output validation, human approval for destructive actions, audit log
