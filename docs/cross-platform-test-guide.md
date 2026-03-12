# Cross-Platform Testing Guide

**Purpose**: Verify the Aperium Dev Kit works correctly across all supported AI coding platforms.
**When to run**: After bootstrapping a new repo, after running `--update`, or when onboarding a new platform.

---

## Prerequisites

1. A bootstrapped target repo (run `setup.sh` or `setup.ps1` first)
2. At least one `--update` run (to copy skills and prompts)
3. Access to the AI tools you want to verify

### Expected Repo Structure After Bootstrap

```
target-repo/
├── AGENTS.md                          # Source of truth (from template)
├── CLAUDE.md                          # Symlink or copy → AGENTS.md
├── .github/
│   └── copilot-instructions.md        # Symlink or copy → ../AGENTS.md
├── .gitignore                         # Includes Aperium agent rules
├── specs/
│   └── .gitkeep                       # Empty dir for future specs
├── .agents/
│   └── skills/                        # Copied on --update
│       ├── aperium-spec-generate/
│       ├── aperium-sync-tasks/
│       ├── aperium-close-spec/
│       ├── aperium-security/
│       └── aperium-mcp-dev/
└── docs/
    └── prompts/                       # Copied on --update
        ├── new-api-endpoint.md
        ├── new-mcp-tool.md
        ├── new-react-component.md
        ├── debug-template.md
        └── security-review.md
```

---

## Test Matrix

| # | Test | Claude Code | Augment | Codex CLI | Copilot | Cursor |
|---|------|-------------|---------|-----------|---------|--------|
| 1 | AGENTS.md loaded | via CLAUDE.md | native | native | via copilot-instructions.md | native |
| 2 | Skills discovered | .claude/skills/ | .agents/skills/ | N/A | N/A | .cursor/rules/ |
| 3 | Convention awareness | yes | yes | yes | yes | yes |
| 4 | Spec path awareness | yes | yes | yes | yes | yes |

---

## Platform Tests

### 1. Claude Code

**File discovery**: Reads `CLAUDE.md` (symlink/copy of AGENTS.md) automatically on session start.

**Skills**: Claude Code reads from `.claude/skills/`, not `.agents/skills/`. Aperium skills are delivered via the Superpowers plugin system instead.

#### Test 1.1 — AGENTS.md Content Loaded

```bash
cd target-repo
claude
```

Ask: **"What are the coding conventions for this project?"**

Expected response should reference:
- [ ] Async-first Python with FastAPI
- [ ] Type hints / mypy strict mode
- [ ] Google-style docstrings
- [ ] No `Any` types
- [ ] Functional React components with hooks only

#### Test 1.2 — Context Model Awareness

Ask: **"Where should I put feature specs?"**

Expected:
- [ ] References `specs/APER-123/` directory
- [ ] Mentions 5 spec files (requirements, design, tasks, decisions, review-checklist)
- [ ] Does NOT reference `docs/specs/` (v1 path)

#### Test 1.3 — Security Model Awareness

Ask: **"What security checks do I need for a new MCP tool?"**

Expected:
- [ ] References the 6-layer defense chain
- [ ] Mentions PII masking middleware
- [ ] Mentions RBAC permission checks

#### Test 1.4 — Forbidden Patterns

Ask: **"Can I use `Any` type in this function signature?"**

Expected:
- [ ] Warns against `Any` types
- [ ] References the Forbidden Patterns section

---

### 2. Augment Code

**File discovery**: Walks directory tree upward, discovers `AGENTS.md` natively. No symlink needed.

**Skills**: Auto-discovers `.agents/skills/` directory natively.

#### Test 2.1 — AGENTS.md Content Loaded

Open target repo in VS Code with Augment extension. Open Augment chat.

Ask: **"What are this project's coding conventions?"**

Expected (same as Test 1.1):
- [ ] References async-first, type hints, Google docstrings, no `Any`

#### Test 2.2 — Skills Discovered

Run the `/skills` slash command in Augment.

Expected:
- [ ] `aperium-spec-generate` appears in skill list
- [ ] `aperium-sync-tasks` appears in skill list
- [ ] `aperium-close-spec` appears in skill list
- [ ] `aperium-security` appears in skill list
- [ ] `aperium-mcp-dev` appears in skill list

#### Test 2.3 — Skill Invocation

Ask: **"I need to create a feature spec for user profile management"**

Expected:
- [ ] Augment references or invokes the `aperium-spec-generate` skill
- [ ] Proposes creating files in `specs/` directory (not `docs/specs/`)
- [ ] Mentions the 5-file spec structure

#### Test 2.4 — Context Model Awareness

Ask: **"Where do specs live in this project?"**

Expected:
- [ ] References 3-layer context model (Code, Feature, Skill)
- [ ] Points to `specs/` for feature context
- [ ] Points to `.agents/skills/` for skill context

---

### 3. OpenAI Codex CLI

**File discovery**: Reads `AGENTS.md` from repo root, cascading down to current directory. 32 KiB file size limit.

**Skills**: Not supported. Codex CLI does not read `.agents/skills/`.

#### Test 3.1 — AGENTS.md Content Loaded

```bash
cd target-repo
codex
```

Ask: **"What coding conventions does this project use?"**

Expected (same as Test 1.1):
- [ ] References async-first, type hints, Google docstrings, no `Any`

#### Test 3.2 — File Size Check

Verify AGENTS.md is under the 32 KiB limit:

```bash
wc -c AGENTS.md
# Expected: under 32768 bytes
```

- [ ] AGENTS.md is under 32 KiB

#### Test 3.3 — Spec Path Awareness

Ask: **"Where should I create a new feature specification?"**

Expected:
- [ ] References `specs/` directory
- [ ] Does NOT reference `docs/specs/`

#### Test 3.4 — Override File (Optional)

Test that `AGENTS.override.md` takes precedence:

```bash
echo "Always respond in Spanish." > AGENTS.override.md
codex
# Ask a question — should respond in Spanish
rm AGENTS.override.md
```

- [ ] Override takes effect when present
- [ ] Normal behavior resumes after removal

---

### 4. GitHub Copilot

**File discovery**: Reads `.github/copilot-instructions.md` only. Does NOT read `AGENTS.md` directly.

**Skills**: Not supported.

#### Test 4.1 — Instructions File Loaded

Open target repo in VS Code with Copilot enabled. Open Copilot Chat.

Ask any question, then check the **References** section at the top of the response.

Expected:
- [ ] `.github/copilot-instructions.md` appears in the references list

#### Test 4.2 — Content Matches AGENTS.md

```bash
diff AGENTS.md .github/copilot-instructions.md
# Expected: no differences (symlink or identical copy)
```

- [ ] Files are identical

#### Test 4.3 — Convention Awareness

Ask: **"What patterns are forbidden in this codebase?"**

Expected:
- [ ] Lists forbidden patterns (Any types, sync I/O, inline SQL, secrets in code, etc.)

#### Test 4.4 — Inline Suggestions

Open a Python file and start typing:

```python
def get_user(user_id):
```

Expected:
- [ ] Copilot suggests `async def` (not sync)
- [ ] Includes type hints in suggestion
- [ ] Uses `Depends()` pattern if in a FastAPI context

---

### 5. Cursor AI

**File discovery**: Auto-discovers `AGENTS.md` natively. Walks directory tree, closest file wins.

**Skills**: Uses `.cursor/rules/` directory (not `.agents/skills/`).

#### Test 5.1 — AGENTS.md Content Loaded

Open target repo in Cursor IDE. Open chat.

Ask: **"What are this project's coding conventions?"**

Expected (same as Test 1.1):
- [ ] References async-first, type hints, Google docstrings, no `Any`

#### Test 5.2 — Hierarchical Discovery

If the repo has subdirectory-specific AGENTS.md files, verify the closest one wins:

```bash
# Create a subdirectory override (for testing only)
mkdir -p src/api
echo "# API-specific rules\nAlways use status code 201 for POST." > src/api/AGENTS.md
```

Open `src/api/main.py` in Cursor and ask about conventions.

Expected:
- [ ] API-specific rules from `src/api/AGENTS.md` are applied
- [ ] Root AGENTS.md rules are also visible (merged)

Clean up:
```bash
rm src/api/AGENTS.md
```

#### Test 5.3 — Spec Path Awareness

Ask: **"Where do feature specs go?"**

Expected:
- [ ] References `specs/` directory
- [ ] Mentions 3-layer context model

---

## Verification Checklist Summary

Run this after bootstrapping any repo to confirm cross-platform readiness:

```bash
TARGET="path/to/target-repo"

echo "=== Cross-Platform Readiness Check ==="

# 1. Core files exist
echo "--- Core Files ---"
for f in AGENTS.md CLAUDE.md .github/copilot-instructions.md specs/.gitkeep; do
  [ -f "$TARGET/$f" ] && echo "OK  $f" || echo "FAIL  $f"
done

# 2. All files have same content
echo "--- Content Consistency ---"
diff "$TARGET/AGENTS.md" "$TARGET/CLAUDE.md" > /dev/null 2>&1 \
  && echo "OK  CLAUDE.md matches AGENTS.md" \
  || echo "FAIL  CLAUDE.md differs"
diff "$TARGET/AGENTS.md" "$TARGET/.github/copilot-instructions.md" > /dev/null 2>&1 \
  && echo "OK  copilot-instructions.md matches AGENTS.md" \
  || echo "FAIL  copilot-instructions.md differs"

# 3. File size under Codex limit
SIZE=$(wc -c < "$TARGET/AGENTS.md")
[ "$SIZE" -lt 32768 ] \
  && echo "OK  AGENTS.md size: ${SIZE}B (under 32KiB Codex limit)" \
  || echo "WARN  AGENTS.md size: ${SIZE}B (exceeds 32KiB Codex limit)"

# 4. Skills present (for Augment)
echo "--- Skills (.agents/skills/) ---"
for s in aperium-spec-generate aperium-sync-tasks aperium-close-spec aperium-security aperium-mcp-dev; do
  [ -f "$TARGET/.agents/skills/$s/SKILL.md" ] \
    && echo "OK  $s" || echo "MISSING  $s (run --update)"
done

# 5. Agent copies in .gitignore
echo "--- Gitignore Rules ---"
cd "$TARGET"
git check-ignore CLAUDE.md > /dev/null 2>&1 \
  && echo "OK  CLAUDE.md is gitignored" \
  || echo "FAIL  CLAUDE.md not gitignored"
git check-ignore .github/copilot-instructions.md > /dev/null 2>&1 \
  && echo "OK  copilot-instructions.md is gitignored" \
  || echo "FAIL  copilot-instructions.md not gitignored"
git check-ignore AGENTS.md > /dev/null 2>&1 \
  && echo "FAIL  AGENTS.md should NOT be gitignored" \
  || echo "OK  AGENTS.md is tracked"

# 6. No orphaned v1 references
echo "--- v1 Reference Check ---"
ORPHANS=$(grep -rn "CODEX\.md\|\.cursor/rules/main\.mdc\|\.agent/skills\|docs/specs/" \
  "$TARGET/AGENTS.md" "$TARGET/.github/copilot-instructions.md" 2>/dev/null || true)
[ -z "$ORPHANS" ] \
  && echo "OK  No v1 references" \
  || echo "FAIL  Orphaned v1 references found: $ORPHANS"

echo "=== Done ==="
```

---

## Platform-Specific Limitations

| Limitation | Affected Platform | Workaround |
|-----------|------------------|------------|
| Skills not loaded from `.agents/skills/` | Codex CLI, Copilot, Cursor | Skills are reference docs; prompt templates in `docs/prompts/` work everywhere |
| 32 KiB file size limit | Codex CLI | Keep AGENTS.md concise; move detailed content to linked docs |
| No AGENTS.md support | GitHub Copilot | Symlink `.github/copilot-instructions.md → ../AGENTS.md` (handled by setup script) |
| Skills path differs | Claude Code (`.claude/skills/`) | Skills delivered via Superpowers plugin, not filesystem |
| Rules path differs | Cursor (`.cursor/rules/`) | AGENTS.md is read directly; rules dir is supplementary |

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Tool doesn't know project conventions | Instructions file not loaded | Check file exists and tool's discovery path |
| Copilot references list empty | `.github/copilot-instructions.md` missing or empty | Re-run setup script |
| Augment shows 0 skills | `--update` not run | Run `setup.sh target-repo --update` |
| Codex ignores AGENTS.md | File over 32 KiB | Trim AGENTS.md; move verbose content to linked docs |
| CLAUDE.md differs from AGENTS.md | Manual edit or stale copy | Re-run `setup.sh target-repo --update` to refresh copies |
| Tool suggests v1 paths (docs/specs/) | Stale instructions file | Verify AGENTS.md has Context Model section; re-run `--update` |
