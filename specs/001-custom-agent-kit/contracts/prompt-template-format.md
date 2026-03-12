# Contract: Prompt Template Format

**Version**: 1.0
**Date**: 2026-03-11

## Overview

Defines the structure for all prompt templates in the starter
prompt library (`docs/prompts/`).

## File Format

Each prompt template is a standalone Markdown file.

### Required Sections

```markdown
# Prompt: {Task Name}

## Purpose
[1-2 sentences: what this prompt helps accomplish]

## Context
See AGENTS.md for project conventions and forbidden patterns.
[Additional context specific to this task type]

## Prompt
[The actual prompt template with {PLACEHOLDER} variables]

## Expected Output
[Description of what good output looks like — structure, sections,
conventions that should be present]

## Example
[One concrete example showing the prompt filled in and a snippet
of expected output]
```

### Placeholder Format

Use `{VARIABLE_NAME}` for all placeholders in the Prompt section:

```markdown
Create a new FastAPI endpoint for {RESOURCE_NAME} that handles
{OPERATIONS} operations. The endpoint should be located at
{URL_PATH} and use the {MODEL_NAME} model.
```

## Constraints

- Templates MUST reference AGENTS.md for conventions, not duplicate
  them
- Templates MUST be agent-agnostic (no Claude-specific or
  Copilot-specific syntax)
- Templates MUST include at least one concrete example
- Placeholders MUST use `{UPPER_SNAKE_CASE}` format
- File naming: `{task-name}.md` using kebab-case

## Prompt Library Inventory

| Template | Purpose | Key Placeholders |
|----------|---------|-----------------|
| new-api-endpoint.md | FastAPI endpoint generation | {RESOURCE_NAME}, {OPERATIONS}, {URL_PATH} |
| new-mcp-tool.md | MCP server tool creation | {SERVICE_NAME}, {TOOL_NAME}, {DESCRIPTION} |
| new-react-component.md | React component with tests | {COMPONENT_NAME}, {PROPS}, {PURPOSE} |
| debug-template.md | Structured debugging | {ERROR_MESSAGE}, {EXPECTED_BEHAVIOR}, {CONTEXT} |
| security-review.md | AI-assisted security review | {FEATURE_NAME}, {FILES_TO_REVIEW}, {SCOPE} |
