# Middleware Patterns

Reference templates for FastMCP server middleware. Apply these patterns to every MCP tool that handles user data, enforces access control, or accepts external input.

---

## 1. PII Masking Middleware

### Purpose

Detect and mask personally identifiable information before it reaches LLM context or logs.

### Detection Patterns

| PII Type | Regex / Method |
|---|---|
| Email addresses | `r"[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+"` |
| Phone numbers (US/intl) | `r"\+?1?[-.\s]?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}"` |
| Social Security Numbers | `r"\b\d{3}-?\d{2}-?\d{4}\b"` |
| Credit card numbers | `r"\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b"` + Luhn check |
| IP addresses | `r"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"` |
| Physical addresses | `r"\b\d+\s+[\w\s]+(Street|St|Avenue|Ave|Road|Rd|Blvd|Drive|Dr)\b"` |

### Masking Rules

- Replace detected PII with typed placeholders: `[EMAIL_MASKED]`, `[PHONE_MASKED]`, `[SSN_MASKED]`, `[CC_MASKED]`, `[IP_MASKED]`, `[ADDRESS_MASKED]`.
- Log the masking action (type and count masked, never the original value).
- Configurable allow-list for fields that should not be masked.
- Applied to both tool inputs and tool outputs.

### Implementation Pattern

```python
import re
import logging
from typing import Any

logger = logging.getLogger("mcp.middleware.pii")

PII_PATTERNS: dict[str, tuple[str, str]] = {
    "EMAIL":   (r"[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+", "[EMAIL_MASKED]"),
    "PHONE":   (r"\+?1?[-.\s]?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}", "[PHONE_MASKED]"),
    "SSN":     (r"\b\d{3}-?\d{2}-?\d{4}\b", "[SSN_MASKED]"),
    "CC":      (r"\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b", "[CC_MASKED]"),
    "IP":      (r"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b", "[IP_MASKED]"),
    "ADDRESS": (r"\b\d+\s+[\w\s]+(Street|St|Avenue|Ave|Road|Rd|Blvd|Drive|Dr)\b", "[ADDRESS_MASKED]"),
}

ALLOW_LIST_FIELDS: set[str] = {"public_email", "business_phone"}


def mask_pii(data: dict[str, Any], allow_list: set[str] | None = None) -> dict[str, Any]:
    """Scan tool input/output and replace PII with typed placeholders."""
    allow = allow_list or ALLOW_LIST_FIELDS
    masked = {}
    for field, value in data.items():
        if field in allow or not isinstance(value, str):
            masked[field] = value
            continue
        result = value
        for pii_type, (pattern, placeholder) in PII_PATTERNS.items():
            original = result
            result = re.sub(pattern, placeholder, result, flags=re.IGNORECASE)
            if result != original:
                logger.info("Masked %s in field '%s'", pii_type, field)
        masked[field] = result
    return masked
```

---

## 2. RBAC Permission Check Middleware

### Purpose

Verify the caller has the required permissions before tool execution proceeds.

### Permission Model

| Role | Permissions |
|---|---|
| admin | read, write, delete, execute, admin |
| developer | read, write, execute |
| viewer | read |
| service-account | read, execute |

Each tool declares its required permissions via a `required_permissions` attribute.

### Implementation Pattern

```python
import logging
from typing import Any
from fastapi import HTTPException, Request

logger = logging.getLogger("mcp.middleware.rbac")

ROLE_PERMISSIONS: dict[str, set[str]] = {
    "admin":           {"read", "write", "delete", "execute", "admin"},
    "developer":       {"read", "write", "execute"},
    "viewer":          {"read"},
    "service-account": {"read", "execute"},
}


async def check_permissions(
    request: Request,
    required_permissions: set[str],
) -> dict[str, Any]:
    """Extract user context, verify role grants required permissions."""
    user_id: str = request.state.user_id
    roles: list[str] = request.state.roles  # populated by auth middleware

    granted: set[str] = set()
    for role in roles:
        granted |= ROLE_PERMISSIONS.get(role, set())

    missing = required_permissions - granted
    if missing:
        logger.warning(
            "ACCESS DENIED user=%s roles=%s missing=%s",
            user_id, roles, missing,
        )
        raise HTTPException(status_code=403, detail="Insufficient permissions")

    logger.info("ACCESS GRANTED user=%s roles=%s", user_id, roles)
    return {"user_id": user_id, "roles": roles, "permissions": granted}
```

---

## 3. Input Validation Middleware

### Purpose

Validate and sanitize all tool inputs before processing to prevent injection attacks and malformed data.

### Validation Rules

- Type checking via Pydantic strict models.
- Length limits on all string inputs.
- Injection pattern detection (SQL, command, path traversal).
- Required field enforcement.
- Format validation for dates, IDs, and URLs.

### Implementation Pattern

```python
import re
import logging
from pydantic import BaseModel, Field, field_validator

logger = logging.getLogger("mcp.middleware.validation")

INJECTION_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r"(--|;|\bDROP\b|\bUNION\b|\bSELECT\b.*\bFROM\b)", re.IGNORECASE),  # SQL
    re.compile(r"(\||&&|`|\$\()"),                                                    # command
    re.compile(r"(\.\./|\.\.\\)"),                                                    # path traversal
]


class ToolInput(BaseModel):
    """Base model for MCP tool inputs. Extend per tool."""

    query: str = Field(..., min_length=1, max_length=2000)
    resource_id: str = Field(..., pattern=r"^[a-zA-Z0-9_-]+$", max_length=128)
    limit: int = Field(default=50, ge=1, le=500)

    @field_validator("query")
    @classmethod
    def reject_injection(cls, v: str) -> str:
        for pattern in INJECTION_PATTERNS:
            if pattern.search(v):
                logger.warning("Injection pattern detected in query input")
                raise ValueError("Input contains disallowed patterns")
        return v


async def validate_tool_input(raw_input: dict) -> ToolInput:
    """Parse and validate raw tool input against the schema."""
    validated = ToolInput(**raw_input)
    logger.info("Input validated for resource_id=%s", validated.resource_id)
    return validated
```
