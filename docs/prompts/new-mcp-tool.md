# Prompt: New MCP Tool

## Purpose
Create an MCP server tool with full security middleware, following Aperium's FastMCP patterns for enterprise integration.

## Context
See AGENTS.md for project conventions and forbidden patterns.
Every MCP tool must implement PII masking middleware, RBAC permission checks before execution, input validation, structured error handling, and timeout configuration. Tools integrate with external services (Odoo ERP, Arena PLM, Malbek CLM) and must never expose raw credentials or unmasked PII.

Specs live in `specs/APER-123/` and are committed to git alongside code.

## Prompt
```
Create an MCP server tool for the {SERVICE_NAME} integration.

Requirements:
- Tool name: {TOOL_NAME}
- Description: {DESCRIPTION}
- Use FastMCP patterns for tool definition
- Add PII masking middleware on all fields that may contain user data
- Add RBAC permission check before tool execution
- Validate all inputs with explicit schemas and bounds checking
- Handle errors with structured responses (no raw tracebacks)
- Configure a timeout appropriate for the external service call
- Add Google-style docstrings
- Include an integration test skeleton

Follow the MCP server development conventions in AGENTS.md.
Return the tool module, its input/output schemas, and a test file.
```

## Expected Output
- A FastMCP tool definition with typed input/output schemas
- PII masking middleware applied to fields containing names, emails, or IDs
- RBAC check verifying the caller has the required permission before execution
- Input validation with clear error messages for invalid data
- Try/except with structured error responses (no stack traces leaked)
- Explicit timeout on the external service call
- An integration test skeleton with mocked external service

## Example

**Filled-in prompt:**
> Create an MCP server tool for the **Odoo ERP** integration.
> Tool name: `get_purchase_order`
> Description: Retrieve a purchase order by ID from Odoo, including line items and approval status.

**Snippet of expected output:**

```python
# mcp_servers/odoo/tools/get_purchase_order.py
from fastmcp import Tool, ToolError
from pydantic import BaseModel, Field, field_validator

from mcp_servers.odoo.client import OdooAsyncClient
from mcp_servers.odoo.middleware import mask_pii, require_permission

TOOL_TIMEOUT_SECONDS = 30


class GetPurchaseOrderInput(BaseModel):
    """Input schema for retrieving an Odoo purchase order."""

    order_id: int = Field(..., gt=0, description="Odoo purchase order ID.")

    @field_validator("order_id")
    @classmethod
    def validate_order_id(cls, v: int) -> int:
        if v > 10_000_000:
            raise ValueError("order_id exceeds maximum expected range")
        return v


class PurchaseOrderLineItem(BaseModel):
    """A single line item on a purchase order."""

    product_name: str
    quantity: float = Field(..., ge=0)
    unit_price: float = Field(..., ge=0)


class GetPurchaseOrderOutput(BaseModel):
    """Output schema for an Odoo purchase order."""

    order_id: int
    vendor_name: str
    status: str
    line_items: list[PurchaseOrderLineItem]
    total_amount: float


@Tool(
    name="get_purchase_order",
    description="Retrieve a purchase order by ID from Odoo ERP.",
    timeout=TOOL_TIMEOUT_SECONDS,
)
@require_permission("odoo:purchase_orders:read")
@mask_pii(fields=["vendor_name"])
async def get_purchase_order(
    params: GetPurchaseOrderInput,
    client: OdooAsyncClient,
) -> GetPurchaseOrderOutput:
    """Retrieve a purchase order from Odoo by its ID.

    Args:
        params: Validated input containing the order ID.
        client: Async Odoo API client.

    Returns:
        Purchase order details including line items.

    Raises:
        ToolError: If the order is not found or the service is unavailable.
    """
    try:
        raw = await client.get_purchase_order(params.order_id)
    except client.NotFoundError:
        raise ToolError(f"Purchase order {params.order_id} not found.")
    except client.TimeoutError:
        raise ToolError("Odoo service timed out. Retry later.")

    return GetPurchaseOrderOutput(**raw)
```
