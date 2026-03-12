# GitHub Actions Templates

CI automation templates for syncing specs to Confluence and closing the loop on Jira tickets after PR merge.

## Overview

These reusable workflow templates automate two post-merge processes:

1. **confluence-sync.yml** — Syncs spec files from `specs/` to Confluence pages when PRs merge
2. **close-the-loop.yml** — Transitions Jira tickets to Done and checks Epic completion
3. **confluence-discover/** — Composite action that finds or creates the Confluence page structure

## Installation

### 1. Copy the composite action

```bash
# From your repo root:
mkdir -p .github/actions/confluence-discover
cp <devkit-path>/templates/github-actions/confluence-discover/action.yml \
   .github/actions/confluence-discover/action.yml
```

### 2. Create caller workflows

Create `.github/workflows/spec-sync.yml`:

```yaml
name: Spec Sync
on:
  pull_request:
    types: [closed]
    branches: [develop, main]

jobs:
  sync:
    if: github.event.pull_request.merged == true
    uses: ./.github/workflows/confluence-sync.yml
    with:
      jira_project_key: APER
    secrets:
      ATLASSIAN_API_TOKEN: ${{ secrets.ATLASSIAN_API_TOKEN }}
      ATLASSIAN_EMAIL: ${{ secrets.ATLASSIAN_EMAIL }}
      ATLASSIAN_BASE_URL: ${{ secrets.ATLASSIAN_BASE_URL }}

  close-loop:
    if: github.event.pull_request.merged == true
    uses: ./.github/workflows/close-the-loop.yml
    with:
      jira_project_key: APER
    secrets:
      ATLASSIAN_API_TOKEN: ${{ secrets.ATLASSIAN_API_TOKEN }}
      ATLASSIAN_EMAIL: ${{ secrets.ATLASSIAN_EMAIL }}
      ATLASSIAN_BASE_URL: ${{ secrets.ATLASSIAN_BASE_URL }}
```

### 3. Copy workflow templates

```bash
cp <devkit-path>/templates/github-actions/confluence-sync.yml \
   .github/workflows/confluence-sync.yml
cp <devkit-path>/templates/github-actions/close-the-loop.yml \
   .github/workflows/close-the-loop.yml
```

## Required Secrets

Configure these in your repository settings (Settings > Secrets and variables > Actions):

| Secret | Description | Example |
|--------|-------------|---------|
| `ATLASSIAN_API_TOKEN` | Atlassian API token ([create here](https://id.atlassian.com/manage-profile/security/api-tokens)) | `ABCdef123...` |
| `ATLASSIAN_EMAIL` | Atlassian account email | `dev@company.com` |
| `ATLASSIAN_BASE_URL` | Atlassian instance URL | `https://mycompany.atlassian.net` |

## Confluence Space Setup

**One-time admin step:**

1. Create a Confluence space named "Aperium Specs" (or your preferred name)
2. The workflows will automatically create "Active Specs" and "Completed Specs" parent pages
3. Each epic gets its own page under "Active Specs" with child pages per spec file

**Page structure created automatically:**
```
Aperium Specs (space)
├── Active Specs
│   ├── APER-123: User Profile Management
│   │   ├── APER-123: requirements
│   │   ├── APER-123: design
│   │   ├── APER-123: tasks
│   │   ├── APER-123: decisions
│   │   └── APER-123: review-checklist
│   └── APER-456: Payment Integration
│       └── ...
└── Completed Specs
    └── (moved here on completion)
```

## Customization

### Branch Name Pattern

The workflows extract ticket IDs from branch names matching:
```
(feat|feature|fix|refactor|test|docs|chore|perf|security)/{TICKET_ID}-description
```

Examples: `feat/APER-123-user-profiles`, `fix/APER-456-payment-bug`

### Confluence Space Name

Change the `confluence_space_name` input in your caller workflow to use a different space.

### Jira Project Key

Set the `jira_project_key` input to match your Jira project.

## Markdown-to-Confluence Conversion

The sync workflow converts Markdown to Confluence XHTML storage format. Supported conversions:

| Markdown | Confluence |
|----------|-----------|
| `# Heading` | `<h1>Heading</h1>` |
| `**bold**` | `<strong>bold</strong>` |
| `*italic*` | `<em>italic</em>` |
| `- list item` | `<li>list item</li>` |
| `` `inline code` `` | `<code>inline code</code>` |
| ` ```code block``` ` | Confluence code macro |
| `- [x] task` | Confluence task status |

**Known limitations:**
- Tables are not converted (passed through as-is)
- Nested lists may not render correctly
- Complex Confluence macros are not supported
- Images/attachments are not synced

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `401 Unauthorized` | Invalid or expired API token | Regenerate token at Atlassian account settings |
| `404 Not Found` | Wrong base URL or space doesn't exist | Verify `ATLASSIAN_BASE_URL` and create the Confluence space |
| `403 Forbidden` | Account lacks permissions | Ensure the API token user has space admin rights |
| No ticket ID found | Branch name doesn't match pattern | Use format: `feat/APER-123-description` |
| Pages not updating | Workflow didn't trigger | Check workflow trigger conditions (`pull_request.closed` + `merged == true`) |

## Manual Fallback

For teams without CI or when workflows fail:

1. Use the `aperium-close-spec` skill to add implementation notes manually
2. Copy spec Markdown files to Confluence manually
3. Transition Jira tickets via the Jira UI

The `aperium-close-spec` skill provides the same post-merge workflow that CI automates.
