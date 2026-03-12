---
name: aperium-spec
description: Use when creating a new feature specification for any Aperium platform service, when you need architecture context pre-filled and a mandatory security section included
---

# Aperium Specification Skill

## Purpose
Generate feature specifications with Aperium platform architecture context pre-filled and mandatory security considerations included. Produces Speckit-compatible output.

## Prerequisites
- AGENTS.md must exist in the target repository (for convention reference)
- Target repository must be an Aperium platform service

## When to Use
- Starting a new feature that touches Aperium platform services
- Need a spec with architecture context (FastAPI, React, MCP, data stores) pre-filled
- Want security considerations automatically included per the 6-layer defense model
- Want Speckit-compatible output (works with /speckit.plan, /speckit.tasks)

## Workflow

Step-by-step instructions for the AI agent:

1. **Accept feature description** from the developer (command argument or prompt)
2. **Load architecture context** from `references/architecture-context.md`:
   - Platform services (FastAPI backend, React frontend, MCP servers)
   - Data stores (PostgreSQL, Redis, Neo4j)
   - AI/ML pipeline (Vertex AI, BigQuery)
   - Integration patterns
3. **Load security template** from `references/security-template.md`:
   - Zero Trust assessment questions
   - PII handling checklist
   - RBAC requirements template
   - 6-layer defense checklist
4. **Load spec sections template** from `references/spec-sections.md`:
   - Speckit-compatible section structure
   - Aperium-specific placeholders
5. **Generate the specification**:
   - Create feature header with branch name and date
   - Write user scenarios with acceptance criteria (Given/When/Then)
   - Write functional requirements (testable, unambiguous)
   - Fill in architecture context relevant to this feature
   - Complete the security considerations section
   - Define measurable success criteria
   - Identify edge cases
6. **Write output** to `specs/{feature-name}/spec.md`
7. **Report** the file path and suggest next steps (/speckit.clarify or /speckit.plan)

## Output
- **File**: `specs/{feature-name}/spec.md`
- **Format**: Speckit-compatible Markdown
- **Sections**: Feature header, User Scenarios, Requirements, Success Criteria, Security Considerations, Edge Cases

## References
- `references/architecture-context.md` — Aperium platform architecture overview
- `references/security-template.md` — Mandatory security section template
- `references/spec-sections.md` — Speckit-compatible section templates

## Common Mistakes
- Duplicating AGENTS.md conventions in the spec (reference them instead: "See AGENTS.md for coding conventions")
- Skipping the security section for "non-security" features (every feature needs it assessed)
- Using agent-specific syntax (output must be plain Markdown consumable by any agent)
- Writing implementation details instead of requirements (specs describe WHAT, not HOW)

## Quick Reference

| Input | Output |
|-------|--------|
| Feature description (text) | `specs/{feature}/spec.md` |
| Architecture context (auto-loaded) | Pre-filled platform context in spec |
| Security template (auto-loaded) | Completed security considerations section |
