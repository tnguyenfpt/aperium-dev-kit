# MCP Server Scaffold Structure

## Directory Tree

```
mcp-{service-name}/
├── src/
│   ├── __init__.py
│   ├── server.py              # FastMCP server definition and tool registration
│   ├── tools/                 # Tool definitions (one file per tool)
│   │   ├── __init__.py
│   │   └── {tool_name}.py     # Individual tool implementation
│   ├── middleware/
│   │   ├── __init__.py
│   │   ├── pii_masking.py     # PII detection and masking middleware
│   │   └── rbac.py            # Role-based access control middleware
│   └── config.py              # Environment config (HashiCorp Vault integration)
├── tests/
│   ├── __init__.py
│   ├── integration/           # Full tool execution tests
│   │   ├── __init__.py
│   │   └── test_{tool_name}.py
│   └── unit/                  # Middleware and utility unit tests
│       ├── __init__.py
│       ├── test_pii_masking.py
│       ├── test_rbac.py
│       └── test_config.py
├── Dockerfile                 # Multi-stage build for production
├── docker-compose.yml         # Local development + dependency services
├── pyproject.toml             # Project metadata, dependencies, tool config
├── README.md                  # Service documentation
└── .env.example               # Example environment variables (no secrets!)
```

## File Descriptions

### src/server.py
- **Purpose**: Entry point for the MCP server. Initializes FastMCP, registers all tools, and wires up middleware.
- **Key contents**: `FastMCP` instance creation, tool auto-discovery from `tools/`, middleware chain setup, health check endpoint, graceful shutdown handler.
- **Imports**: `fastmcp`, tool modules, middleware modules, `config`.

### src/tools/{tool_name}.py
- **Purpose**: Single tool implementation. Each file exports one async tool function with full type hints.
- **Key contents**: Pydantic input/output models, `@tool` decorator, async implementation, structured error handling with timeouts.
- **Imports**: `fastmcp`, `pydantic`, service-specific SDK clients.

### src/middleware/pii_masking.py
- **Purpose**: Detects and masks PII in tool inputs and outputs before logging or external transmission.
- **Key contents**: Regex and pattern-based detection for emails, phone numbers, SSNs, names. Configurable masking strategies (redact, hash, tokenize).
- **Imports**: `re`, `pydantic`, project config.

### src/middleware/rbac.py
- **Purpose**: Enforces role-based access control before tool execution.
- **Key contents**: Permission check against user roles/scopes, deny-by-default policy, audit log emission on access denied.
- **Imports**: `fastmcp` context, project config, logging.

### src/config.py
- **Purpose**: Loads environment configuration and secrets from HashiCorp Vault.
- **Key contents**: Pydantic `BaseSettings` subclass, Vault client initialization via `hvac`, secret caching with TTL.
- **Imports**: `pydantic_settings`, `hvac`, `functools.lru_cache`.

### tests/integration/test_{tool_name}.py
- **Purpose**: End-to-end tests that invoke tools through the full middleware chain against test fixtures or sandboxed services.
- **Key contents**: `pytest-asyncio` async test functions, fixture setup/teardown, assertion on both outputs and side effects.

### tests/unit/
- **Purpose**: Isolated tests for middleware logic and config loading without external dependencies.
- **Key contents**: Mocked inputs, parameterized PII detection cases, RBAC deny/allow scenarios, Vault client mocking.

## server.py Pattern

The middleware chain executes in this order for every tool invocation:

1. **Input validation** -- Pydantic model parsing, reject malformed requests
2. **PII masking** -- Scan and mask sensitive data in inputs before processing
3. **RBAC check** -- Verify caller has required permissions for the requested tool
4. **Tool execution** -- Run the tool's async handler with timeout enforcement
5. **Output validation** -- Verify response schema, mask PII in outputs, sanitize

The server exposes a `/health` endpoint and handles `SIGTERM`/`SIGINT` for graceful shutdown.

## pyproject.toml Pattern

- **Project name**: `mcp-{service-name}`
- **Dependencies**: `fastmcp>=3.0`, `pydantic>=2.0`, `hvac>=2.0` (Vault client), `structlog`
- **Dev dependencies**: `pytest`, `pytest-asyncio`, `pytest-cov`, `ruff`, `mypy`
- **Ruff config**: `line-length = 120`, `select = ["E", "F", "I", "N", "UP", "RUF"]`
- **Mypy config**: `strict = true`, `plugins = ["pydantic.mypy"]`

## Dockerfile Pattern

- **Stage 1 (builder)**: `python:3.12-slim`, install build deps, `pip install` into virtualenv
- **Stage 2 (runtime)**: `python:3.12-slim`, copy virtualenv from builder, non-root `appuser`
- **HEALTHCHECK**: `CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]`
- **No secrets**: All secrets loaded at runtime from Vault, never baked into the image

## Naming Conventions

| Element              | Convention   | Example                      |
|----------------------|--------------|------------------------------|
| Service directory    | kebab-case   | `mcp-arena-plm/`            |
| Python modules       | snake_case   | `pii_masking.py`            |
| Tool files           | snake_case   | `get_bom.py`, `search_parts.py` |
| Test files           | test_ prefix | `test_get_bom.py`           |
| Pydantic models      | PascalCase   | `GetBomInput`, `GetBomOutput` |
| Environment vars     | UPPER_SNAKE  | `VAULT_ADDR`, `MCP_PORT`    |
