# Prompt: New API Endpoint

## Purpose
Generate a FastAPI endpoint that follows Aperium async-first conventions, with full type safety, dependency injection, and Google-style docstrings.

## Context
See AGENTS.md for project conventions and forbidden patterns.
All endpoints must be async, use Pydantic models for request/response schemas, and inject dependencies via FastAPI's `Depends()` pattern. No `Any` types, no inline SQL, no synchronous I/O.

Specs live in `specs/APER-123/` and are committed to git alongside code.

## Prompt
```
Create a FastAPI endpoint for the {RESOURCE_NAME} resource.

Requirements:
- URL path: {URL_PATH}
- Operations: {OPERATIONS}
- Pydantic model name: {MODEL_NAME}
- All handlers must be async (`async def`)
- Use `Depends()` for database sessions, auth, and service injection
- Add type hints on every function signature (mypy strict compatible)
- Add Google-style docstrings on all public functions
- Use Pydantic models for request bodies and response schemas
- Include proper HTTP status codes and error responses
- No `Any` types, no inline SQL, no synchronous I/O

Follow the conventions defined in AGENTS.md. Return the router module,
the Pydantic schemas module, and any service layer functions needed.
```

## Expected Output
- A router module with `async def` handlers for each operation
- Pydantic request/response models with strict field types
- `Depends()` injection for DB sessions, authentication, and services
- Google-style docstrings on every public function and class
- Proper `HTTPException` usage with meaningful status codes
- Type hints satisfying mypy strict mode

## Example

**Filled-in prompt:**
> Create a FastAPI endpoint for the **UserProfile** resource.
> URL path: `/api/v1/profiles`
> Operations: `GET list, GET by ID, POST create, PATCH update`
> Pydantic model name: `UserProfile`

**Snippet of expected output:**

```python
# routers/profiles.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_async_session
from app.schemas.profiles import (
    UserProfileCreate,
    UserProfileResponse,
    UserProfileUpdate,
)
from app.services.profiles import ProfileService

router = APIRouter(prefix="/api/v1/profiles", tags=["profiles"])


@router.get("/", response_model=list[UserProfileResponse])
async def list_profiles(
    session: AsyncSession = Depends(get_async_session),
    service: ProfileService = Depends(),
) -> list[UserProfileResponse]:
    """List all user profiles.

    Args:
        session: Async database session.
        service: Profile service instance.

    Returns:
        List of user profile response objects.
    """
    return await service.list_all(session)


@router.post("/", response_model=UserProfileResponse, status_code=status.HTTP_201_CREATED)
async def create_profile(
    payload: UserProfileCreate,
    session: AsyncSession = Depends(get_async_session),
    service: ProfileService = Depends(),
) -> UserProfileResponse:
    """Create a new user profile.

    Args:
        payload: Profile creation data.
        session: Async database session.
        service: Profile service instance.

    Returns:
        The newly created user profile.

    Raises:
        HTTPException: 409 if profile already exists.
    """
    return await service.create(session, payload)
```
