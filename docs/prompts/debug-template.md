# Prompt: Debug Template

## Purpose
Provide a structured debugging workflow that produces a root cause analysis, a concrete fix, and verification steps for any issue in the Aperium platform.

## Context
See AGENTS.md for project conventions and forbidden patterns.
The Aperium platform spans FastAPI (async Python), React (TypeScript), and FastMCP servers. Common bug categories include async race conditions, type mismatches caught at runtime, MCP timeout/permission errors, and ORM query issues. Fixes must maintain the same coding standards as new code.

Specs live in `specs/APER-123/` and are committed to git alongside code.

## Prompt
```
Debug the following issue in the Aperium platform.

Error message:
{ERROR_MESSAGE}

Expected behavior:
{EXPECTED_BEHAVIOR}

Context (service, file, recent changes, reproduction steps):
{CONTEXT}

Follow this structured debugging workflow:
1. **Reproduce** — Confirm the error with the provided steps or logs.
2. **Isolate** — Narrow down to the specific module, function, or line.
3. **Root cause** — Explain WHY the bug occurs, not just WHERE.
4. **Fix** — Propose a code change that follows AGENTS.md conventions
   (async-first, strict types, no forbidden patterns).
5. **Verify** — Provide test commands or a test case to confirm the fix.
6. **Prevent** — Suggest a guard (test, type check, lint rule) that would
   have caught this before merge.

Return a structured analysis with all six sections.
```

## Expected Output
- A clear reproduction confirmation or refined reproduction steps
- Identification of the exact module and function at fault
- A root cause explanation covering the underlying mechanism (not just symptoms)
- A code fix that compiles, passes mypy/eslint strict, and follows Aperium conventions
- A pytest or Vitest test case that exercises the fix
- A prevention recommendation (new lint rule, type constraint, or test pattern)

## Example

**Filled-in prompt:**
> Error message: `RuntimeError: Task got Future attached to a different loop`
>
> Expected behavior: The `/api/v1/jobs/{job_id}/status` endpoint returns the
> current job status without errors.
>
> Context: FastAPI backend, `services/jobs.py`. A developer added a sync Redis
> call inside an async handler after the last sprint. The error occurs under
> load when multiple requests hit the endpoint concurrently.

**Snippet of expected output:**

### 1. Reproduce
Confirmed by running `pytest tests/api/test_jobs.py -k test_job_status_concurrent`
with 10 concurrent requests via `httpx.AsyncClient`.

### 2. Isolate
File: `services/jobs.py`, line 47 — `redis_client.get(cache_key)` is a
synchronous call inside `async def get_job_status()`.

### 3. Root cause
The synchronous `redis_client.get()` call blocks the event loop and creates a
new future on the default loop rather than the running loop. Under concurrency,
this causes the `Future attached to a different loop` error because the sync
Redis client is not fork-safe across async tasks.

### 4. Fix
```python
# services/jobs.py — replace sync Redis call with async
-    status = redis_client.get(cache_key)
+    status = await async_redis_client.get(cache_key)
```
Inject `async_redis_client` via `Depends(get_async_redis)` to maintain the
dependency injection pattern.

### 5. Verify
```bash
pytest tests/api/test_jobs.py -k test_job_status_concurrent -v
```
Add a test that spawns 20 concurrent requests and asserts no `RuntimeError`.

### 6. Prevent
- Add a Ruff custom rule or pre-commit hook that flags synchronous Redis
  calls (`redis_client.get`, `.set`, `.delete`) inside `async def` functions.
- Add a concurrency stress test to the CI pipeline for all async endpoints.
