# Test Patterns for MCP Servers

## Integration Tests

### Happy-Path Tool Execution

```python
# Template for testing a tool end-to-end
import pytest
from fastmcp.testing import TestClient

@pytest.fixture
def client():
    from src.server import app
    return TestClient(app)

@pytest.mark.asyncio
async def test_{tool_name}_success(client):
    """Test successful tool execution with valid input."""
    result = await client.call_tool("{tool_name}", {
        "param1": "valid_value",
        "param2": 42,
    })
    assert result.status == "success"
    assert "expected_field" in result.data
```

### Error-Path Handling

- Test with invalid inputs (missing required fields, wrong types)
- Test with unauthorized user (RBAC denial)
- Test with external service timeout
- Test with malformed external service response

### Middleware Chain Verification

- Test that PII in input gets masked before tool execution
- Test that PII in output gets masked before response
- Test that RBAC check happens before tool execution
- Test that input validation happens before RBAC check
- Test the full chain order: validate → mask PII → check RBAC → execute → mask output

## Unit Tests

### PII Detection Tests

- Test each pattern type (email, phone, SSN, credit card, etc.)
- Test false positives (strings that look like PII but aren't)
- Test masking output format
- Test allow-list behavior

### RBAC Rule Tests

- Test each role's permissions
- Test permission inheritance
- Test tool-level permission mapping
- Test denial logging

### Config Loading Tests

- Test Vault integration (mock Vault client)
- Test fallback behavior when Vault unavailable
- Test environment variable override (for local dev only)

## Test Configuration

### pytest Configuration (pyproject.toml)

```toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
markers = [
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
]
```

### Fixtures Pattern

```python
# Common fixtures for MCP server tests
import pytest
from unittest.mock import AsyncMock, patch
from fastmcp.testing import TestClient

@pytest.fixture
def authenticated_client():
    """Client with valid auth credentials for integration tests."""
    from src.server import app
    client = TestClient(app)
    client.set_auth_token("test-token-with-admin-role")
    return client

@pytest.fixture
def mock_external_service():
    """Mock an external service (e.g., Odoo, Arena) to isolate MCP logic."""
    with patch("src.integrations.external_client") as mock_client:
        mock_client.fetch = AsyncMock(return_value={"id": 1, "name": "Test"})
        mock_client.create = AsyncMock(return_value={"id": 2})
        mock_client.update = AsyncMock(return_value={"id": 1, "updated": True})
        yield mock_client

@pytest.fixture
async def test_db():
    """Provide a clean test database session, rolled back after each test."""
    from src.database import get_async_session
    async with get_async_session() as session:
        async with session.begin():
            yield session
            await session.rollback()
```
