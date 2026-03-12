# Aperium Dev Kit

Cross-agent consistency toolkit for the Aperium AI Agent Platform. Bootstrap any repo with shared coding conventions, spec-driven workflow, and CI automation — works with Claude Code, Augment, Codex, Copilot, and Cursor.

## Quick Start

### 1. Clone this kit

```bash
git clone <this-repo-url> aperium-dev-kit
cd aperium-dev-kit
```

### 2. Bootstrap your project

```bash
# Linux / macOS / Git Bash on Windows
./setup.sh /path/to/your-repo

# PowerShell on Windows
.\setup.ps1 -RepoPath C:\path\to\your-repo
```

This creates:

| File | Purpose |
|------|---------|
| `AGENTS.md` | Single source of truth for coding conventions |
| `CLAUDE.md` | Symlink/copy of AGENTS.md (for Claude Code) |
| `.github/copilot-instructions.md` | Symlink/copy of AGENTS.md (for GitHub Copilot) |
| `specs/.gitkeep` | Directory for feature specs |
| `.gitignore` | Updated with agent file rules |

### 3. Customize AGENTS.md

Open `AGENTS.md` in your repo and fill in the sections marked `<!-- CUSTOMIZABLE -->`:

- **Project Identity** — repo name, purpose, users, domain
- **Architecture Overview** — your actual services and how they connect
- **Build & Test Commands** — your actual lint/test/build commands

Sections marked `<!-- FIXED -->` are managed by the dev kit. Don't edit them.

### 4. Copy skills and prompts

```bash
./setup.sh /path/to/your-repo --update
```

This copies:
- **5 agent skills** to `.agents/skills/` (for Augment, Codex)
- **5 prompt templates** to `docs/prompts/`
- Refreshes all `FIXED` sections from the latest template

### 5. Commit

```bash
cd /path/to/your-repo
git add AGENTS.md .gitignore specs/
git commit -m "chore: bootstrap Aperium Dev Kit"
```

## What You Get

### Agent Skills (`.agents/skills/`)

| Skill | Purpose |
|-------|---------|
| `aperium-spec-generate` | Generate feature specs to `specs/APER-123/` (5 files) |
| `aperium-sync-tasks` | Create Jira tickets from `tasks.md` |
| `aperium-close-spec` | Post-merge: add implementation notes, transition Jira |
| `aperium-security` | Security audit using 6-layer defense model |
| `aperium-mcp-dev` | Scaffold MCP servers with PII/RBAC/test patterns |

### Spec Structure (`specs/APER-123/`)

Every feature gets 5 spec files committed to git:

```
specs/APER-123/
├── requirements.md       # User stories, acceptance criteria, edge cases
├── design.md             # Architecture decisions, component interactions
├── tasks.md              # Task breakdown with complexity (S/M/L)
├── decisions.md          # Key decisions with rationale and trade-offs
└── review-checklist.md   # Pre-populated review checklist
```

### CI Templates (`templates/github-actions/`)

| Template | Purpose |
|----------|---------|
| `confluence-sync.yml` | Sync specs to Confluence on PR merge |
| `close-the-loop.yml` | Transition Jira tickets to Done on merge |
| `confluence-discover/` | Composite action: find/create Confluence pages |

See [templates/github-actions/README.md](templates/github-actions/README.md) for setup.

### Cross-Agent Compatibility

| AI Tool | How it reads conventions | Skills support |
|---------|------------------------|----------------|
| Claude Code | `CLAUDE.md` (symlink) | Via Superpowers plugin |
| Augment | `AGENTS.md` (native) | `.agents/skills/` (native) |
| Codex CLI | `AGENTS.md` (native) | N/A |
| Copilot | `.github/copilot-instructions.md` (symlink) | N/A |
| Cursor | `AGENTS.md` (native) | N/A |

## Updating

When the dev kit is updated, re-run with `--update` to refresh your repo:

```bash
./setup.sh /path/to/your-repo --update
```

This updates `FIXED` sections in AGENTS.md while preserving your `CUSTOMIZABLE` content, and copies the latest skills and prompts.

## Repository Layout

```
aperium-dev-kit/
├── setup.sh                  # Bootstrap script (Bash)
├── setup.ps1                 # Bootstrap script (PowerShell)
├── templates/
│   ├── AGENTS.md.template    # AGENTS.md source template
│   ├── .gitignore.template   # Full .gitignore for new repos
│   └── github-actions/       # CI workflow templates + README
├── skills/                   # Agent skills (5 skills with references)
├── docs/
│   ├── workflow-guide.md     # Full development workflow guide
│   ├── cross-platform-test-guide.md
│   └── prompts/              # 5 reusable prompt templates
└── specs/                    # Specs for this repo's own features
```

## Documentation

- [Workflow Guide](docs/workflow-guide.md) — Full spec-driven development process
- [Cross-Platform Test Guide](docs/cross-platform-test-guide.md) — Verify setup across AI tools
- [GitHub Actions README](templates/github-actions/README.md) — CI template setup and troubleshooting
