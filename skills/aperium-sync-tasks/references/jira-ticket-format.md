# Jira Ticket Format Reference

## Field Mapping

| tasks.md Field | Jira Field | Notes |
|---------------|------------|-------|
| Task title | Summary | Prefix with ticket key |
| Task description | Description | Markdown converted to Jira markup |
| Complexity S/M/L | Story Points | S=1, M=3, L=5 |
| Dependencies | Blocked By links | Issue links to dependent tickets |
| Test criteria | Acceptance Criteria | Custom field or description section |

## Complexity-to-Story-Points Mapping

| Complexity | Story Points | Typical Duration |
|-----------|-------------|-----------------|
| S (Small) | 1 | < 2 hours |
| M (Medium) | 3 | 2-8 hours |
| L (Large) | 5 | 1-3 days |

## Ticket Template

```
Summary: [{EPIC_KEY}-T{N}] {TASK_TITLE}
Type: Task (or Sub-task if under Epic)
Story Points: {POINTS}
Labels: spec-generated, {feature-name}
Component: {COMPONENT_FROM_DESIGN}

Description:
{TASK_DESCRIPTION}

h3. Acceptance Criteria
{TEST_CRITERIA_FROM_TASKS_MD}

h3. Context
- Spec: specs/{EPIC_KEY}/tasks.md
- Task: #{TASK_NUMBER}
- Dependencies: {DEPENDENCY_LIST_OR_NONE}
```

## Example

**tasks.md entry:**
```markdown
### Task 3: Implement user profile API endpoint (M)

**Dependencies:** Task 1 (database models)

Create FastAPI endpoint for user profile CRUD operations.

**Test criteria:**
- GET /api/v1/profiles returns list
- POST /api/v1/profiles creates new profile
- 401 returned for unauthenticated requests
```

**Resulting Jira ticket:**
```
Summary: [APER-123-T3] Implement user profile API endpoint
Type: Sub-task
Story Points: 3
Labels: spec-generated, user-profiles
Component: Backend

Description:
Create FastAPI endpoint for user profile CRUD operations.

h3. Acceptance Criteria
* GET /api/v1/profiles returns list
* POST /api/v1/profiles creates new profile
* 401 returned for unauthenticated requests

h3. Context
- Spec: specs/APER-123/tasks.md
- Task: #3
- Dependencies: APER-123-T1
```
