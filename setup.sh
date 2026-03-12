#!/usr/bin/env bash
# =============================================================================
# Aperium Dev Kit — Bootstrap Script
# Sets up a target repository with consistent AI agent instructions.
#
# Usage:
#   ./setup.sh [TARGET_REPO_PATH] [--update]
#
# If TARGET_REPO_PATH is omitted, the current working directory is used.
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Color helpers (disabled when stdout is not a terminal)
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  GREEN='' YELLOW='' RED='' BOLD='' RESET=''
fi

info()    { printf "${GREEN}[OK]${RESET}    %s\n" "$1"; }
warn()    { printf "${YELLOW}[WARN]${RESET}  %s\n" "$1"; }
error()   { printf "${RED}[ERROR]${RESET} %s\n" "$1" >&2; }

# ---------------------------------------------------------------------------
# Counters for the summary
# ---------------------------------------------------------------------------
STEPS_OK=0
STEPS_WARN=0
STEPS_FAIL=0

step_ok()   { info "$1";  ((STEPS_OK++))   || true; }
step_warn() { warn "$1";  ((STEPS_WARN++)) || true; }
step_fail() { error "$1"; ((STEPS_FAIL++)) || true; }

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------
PLATFORM="unix"
USING_COPIES=false
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
esac

# ---------------------------------------------------------------------------
# Resolve dev-kit root (the directory this script lives in)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVKIT_ROOT="${SCRIPT_DIR}"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
UPDATE_MODE=false

args=()
for arg in "$@"; do
  case "${arg}" in
    --update) UPDATE_MODE=true ;;
    *)        args+=("${arg}") ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve target repository path
# ---------------------------------------------------------------------------
TARGET_REPO="${args[0]:-$(pwd)}"
TARGET_REPO="$(cd "${TARGET_REPO}" && pwd)"  # normalize to absolute path

if [[ ! -d "${TARGET_REPO}/.git" ]]; then
  error "'${TARGET_REPO}' is not a git repository (no .git directory found)."
  exit 1
fi

printf "\n${BOLD}Aperium Dev Kit - Bootstrap${RESET}\n"
printf "  Dev-kit root : %s\n" "${DEVKIT_ROOT}"
printf "  Target repo  : %s\n" "${TARGET_REPO}"
printf "  Platform     : %s\n\n" "${PLATFORM}"

# ---------------------------------------------------------------------------
# Helper: prompt before overwriting an existing non-symlink file
# Returns 0 if we should proceed, 1 if the user declines.
# ---------------------------------------------------------------------------
confirm_overwrite() {
  local filepath="$1"
  if [[ -e "${filepath}" && ! -L "${filepath}" ]]; then
    # If stdin is not a terminal, refuse to overwrite silently
    if [[ ! -t 0 ]]; then
      step_warn "Skipped ${filepath} (existing file; run interactively to confirm overwrite)"
      return 1
    fi
    printf "${YELLOW}[WARN]${RESET}  '%s' already exists and is not a symlink.\n" "${filepath}"
    read -r -p "         Overwrite? [y/N] " answer
    case "${answer}" in
      [yY]|[yY][eE][sS]) return 0 ;;
      *) step_warn "Skipped ${filepath} (user declined overwrite)"; return 1 ;;
    esac
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Step 1: Copy AGENTS.md.template -> AGENTS.md and stamp version
# ---------------------------------------------------------------------------
TEMPLATE_FILE="${DEVKIT_ROOT}/templates/AGENTS.md.template"
AGENTS_TARGET="${TARGET_REPO}/AGENTS.md"

if [[ ! -f "${TEMPLATE_FILE}" ]]; then
  step_fail "Template not found: ${TEMPLATE_FILE}"
  exit 1
fi

# Resolve dev-kit git SHA for version stamping (BUG 5 fix)
DEVKIT_SHA="unknown"
if git -C "${DEVKIT_ROOT}" rev-parse --short HEAD &>/dev/null; then
  DEVKIT_SHA="$(git -C "${DEVKIT_ROOT}" rev-parse --short HEAD)"
fi

if confirm_overwrite "${AGENTS_TARGET}"; then
  if cp "${TEMPLATE_FILE}" "${AGENTS_TARGET}"; then
    # Replace {GIT_SHA} placeholder with actual commit hash
    sed -i "s/{GIT_SHA}/${DEVKIT_SHA}/g" "${AGENTS_TARGET}"
    step_ok "Copied AGENTS.md.template -> AGENTS.md (version: ${DEVKIT_SHA})"
  else
    step_fail "Failed to copy AGENTS.md.template -> AGENTS.md"
  fi
fi

# ---------------------------------------------------------------------------
# Step 2: Create symlinks (with copy verification on Windows)
# ---------------------------------------------------------------------------
create_symlink() {
  local link_path="$1"   # path of the symlink to create (relative to repo)
  local link_target="$2" # what the symlink points to (relative)
  local full_path="${TARGET_REPO}/${link_path}"

  # Ensure parent directory exists
  local parent_dir
  parent_dir="$(dirname "${full_path}")"
  if [[ ! -d "${parent_dir}" ]]; then
    if mkdir -p "${parent_dir}"; then
      step_ok "Created directory: $(basename "${parent_dir}")/"
    else
      step_fail "Failed to create directory: ${parent_dir}"
      return 1
    fi
  fi

  # Check for existing non-symlink file
  if ! confirm_overwrite "${full_path}"; then
    return 0
  fi

  # Attempt symlink
  if ln -sfn "${link_target}" "${full_path}" 2>/dev/null; then
    # BUG 1 fix: Verify the symlink is real (Git Bash on Windows creates copies)
    if [[ -L "${full_path}" ]]; then
      step_ok "Symlinked ${link_path} -> ${link_target}"
    else
      USING_COPIES=true
      step_warn "Copied ${link_path} (symlinks unavailable - enable Developer Mode or run as admin)"
    fi
  else
    # Explicit fallback: copy the file
    USING_COPIES=true
    if cp "${AGENTS_TARGET}" "${full_path}"; then
      step_warn "Copied ${link_path} (symlink failed - enable Developer Mode or run as admin)"
    else
      step_fail "Failed to create ${link_path}"
    fi
  fi
}

create_symlink "CLAUDE.md"                       "AGENTS.md"
create_symlink ".github/copilot-instructions.md" "../AGENTS.md"

# ---------------------------------------------------------------------------
# Step 2b: Create specs/ directory for standardized spec storage
# ---------------------------------------------------------------------------
SPECS_DIR="${TARGET_REPO}/specs"
if [[ ! -d "${SPECS_DIR}" ]]; then
  if mkdir -p "${SPECS_DIR}"; then
    # Create .gitkeep so empty directory is tracked in git
    touch "${SPECS_DIR}/.gitkeep"
    step_ok "Created specs/ directory for standardized spec storage"
  else
    step_fail "Failed to create specs/ directory"
  fi
fi

# ---------------------------------------------------------------------------
# Step 3: Check for files already tracked by git (BUG 2 & 3 fix)
# ---------------------------------------------------------------------------
TRACKED_FILES=()
for f in "CLAUDE.md" ".github/copilot-instructions.md"; do
  if git -C "${TARGET_REPO}" ls-files --error-unmatch "${f}" &>/dev/null; then
    TRACKED_FILES+=("${f}")
  fi
done

if [[ ${#TRACKED_FILES[@]} -gt 0 ]]; then
  warn "The following files are already tracked by git."
  warn ".gitignore rules will NOT take effect until they are untracked:"
  for f in "${TRACKED_FILES[@]}"; do
    printf "  ${YELLOW}->  git rm --cached %s${RESET}\n" "${f}"
  done
  printf "  Then commit the removal before .gitignore rules apply.\n"
  ((STEPS_WARN++)) || true
fi

# ---------------------------------------------------------------------------
# Step 4: Append .gitignore rules (agent-specific only if .gitignore exists)
# ---------------------------------------------------------------------------
GITIGNORE_TEMPLATE="${DEVKIT_ROOT}/templates/.gitignore.template"
GITIGNORE_TARGET="${TARGET_REPO}/.gitignore"

# Minimal agent-specific rules (used when repo already has a .gitignore)
read -r -d '' AGENT_GITIGNORE_BLOCK <<'GITIGNORE_EOF' || true

# --- Aperium Dev Kit: Agent Instructions ---
# AGENTS.md is the source of truth and MUST be tracked.
# These files are symlinks/copies managed by the dev-kit setup script.
CLAUDE.md
.github/copilot-instructions.md
# --- End Aperium Dev Kit ---
GITIGNORE_EOF

if [[ ! -f "${GITIGNORE_TEMPLATE}" ]]; then
  step_warn ".gitignore.template not found; skipping .gitignore update"
else
  SENTINEL="Aperium Dev Kit"

  if [[ -f "${GITIGNORE_TARGET}" ]] && grep -qF "${SENTINEL}" "${GITIGNORE_TARGET}" 2>/dev/null; then
    step_warn ".gitignore already contains Aperium Dev Kit rules; skipping"
  elif [[ -f "${GITIGNORE_TARGET}" ]]; then
    # BUG 4 fix: Existing .gitignore - only append agent-specific rules
    printf "%s\n" "${AGENT_GITIGNORE_BLOCK}" >> "${GITIGNORE_TARGET}"
    step_ok "Appended agent-specific .gitignore rules (existing .gitignore preserved)"
  else
    # No .gitignore exists - use the full template
    cp "${GITIGNORE_TEMPLATE}" "${GITIGNORE_TARGET}"
    step_ok "Created .gitignore from template"
  fi
fi

# ---------------------------------------------------------------------------
# Update mode: refresh FIXED sections and copy updated skills/prompts
# ---------------------------------------------------------------------------
if [[ "${UPDATE_MODE}" == true ]]; then
  printf "\n${BOLD}Running in update mode...${RESET}\n"

  if [[ ! -f "${AGENTS_TARGET}" ]]; then
    step_fail "AGENTS.md not found in target repo - run without --update first"
  else
    # BUG 7 fix: Pre-parse template FIXED sections into indexed arrays.
    # This avoids the bug where identical FIXED markers always match the
    # first section instead of the correct one by position.
    declare -a FIXED_SECTIONS=()
    current_fixed=""
    in_fixed=false

    while IFS= read -r tline; do
      if [[ "${tline}" == *"<!-- FIXED:"* ]]; then
        # Save previous FIXED section if any
        if [[ "${in_fixed}" == true ]]; then
          FIXED_SECTIONS+=("${current_fixed}")
        fi
        in_fixed=true
        current_fixed=""
      elif [[ "${in_fixed}" == true ]]; then
        if [[ "${tline}" == *"<!-- CUSTOMIZABLE:"* ]] || [[ "${tline}" == "<!-- aperium-dev-kit"* ]]; then
          FIXED_SECTIONS+=("${current_fixed}")
          in_fixed=false
          current_fixed=""
        else
          current_fixed+="${tline}"$'\n'
        fi
      fi
    done < "${TEMPLATE_FILE}"
    # Catch trailing FIXED section at EOF
    if [[ "${in_fixed}" == true ]] && [[ -n "${current_fixed}" ]]; then
      FIXED_SECTIONS+=("${current_fixed}")
    fi

    # Replace FIXED sections in target AGENTS.md by index order
    TEMP_FILE="$(mktemp)"
    fixed_index=0
    skip_until_next_marker=false

    while IFS= read -r line; do
      if [[ "${line}" == *"<!-- FIXED:"* ]]; then
        echo "${line}" >> "${TEMP_FILE}"
        if [[ ${fixed_index} -lt ${#FIXED_SECTIONS[@]} ]]; then
          printf "%s" "${FIXED_SECTIONS[${fixed_index}]}" >> "${TEMP_FILE}"
        fi
        ((fixed_index++)) || true
        skip_until_next_marker=true
      elif [[ "${skip_until_next_marker}" == true ]]; then
        if [[ "${line}" == *"<!-- CUSTOMIZABLE:"* ]] || [[ "${line}" == "<!-- aperium-dev-kit"* ]]; then
          skip_until_next_marker=false
          echo "${line}" >> "${TEMP_FILE}"
        elif [[ "${line}" == *"<!-- FIXED:"* ]]; then
          # Adjacent FIXED section
          echo "${line}" >> "${TEMP_FILE}"
          if [[ ${fixed_index} -lt ${#FIXED_SECTIONS[@]} ]]; then
            printf "%s" "${FIXED_SECTIONS[${fixed_index}]}" >> "${TEMP_FILE}"
          fi
          ((fixed_index++)) || true
        fi
        # else skip old FIXED content
      else
        echo "${line}" >> "${TEMP_FILE}"
      fi
    done < "${AGENTS_TARGET}"

    # Stamp version on updated file
    sed -i "s/{GIT_SHA}/${DEVKIT_SHA}/g" "${TEMP_FILE}"

    mv "${TEMP_FILE}" "${AGENTS_TARGET}"
    step_ok "Updated FIXED sections in AGENTS.md from template (version: ${DEVKIT_SHA})"

    # Refresh copies if not using real symlinks
    if [[ "${USING_COPIES}" == true ]] || [[ "${PLATFORM}" == "windows" ]]; then
      for f in "CLAUDE.md" ".github/copilot-instructions.md"; do
        local_path="${TARGET_REPO}/${f}"
        if [[ -f "${local_path}" && ! -L "${local_path}" ]]; then
          cp "${AGENTS_TARGET}" "${local_path}"
        fi
      done
      step_ok "Refreshed agent config copies from updated AGENTS.md"
    fi
  fi

  # Copy updated skills if they exist
  SKILLS_SRC="${DEVKIT_ROOT}/skills"
  if [[ -d "${SKILLS_SRC}" ]]; then
    SKILLS_DEST="${TARGET_REPO}/.agents/skills"
    mkdir -p "${SKILLS_DEST}"
    cp -r "${SKILLS_SRC}"/* "${SKILLS_DEST}/" 2>/dev/null && \
      step_ok "Updated skills in .agents/skills/" || \
      step_warn "No skills to copy or copy failed"
  fi

  # Copy updated prompt templates if they exist
  PROMPTS_SRC="${DEVKIT_ROOT}/docs/prompts"
  if [[ -d "${PROMPTS_SRC}" ]]; then
    PROMPTS_DEST="${TARGET_REPO}/docs/prompts"
    mkdir -p "${PROMPTS_DEST}"
    cp -r "${PROMPTS_SRC}"/* "${PROMPTS_DEST}/" 2>/dev/null && \
      step_ok "Updated prompt templates in docs/prompts/" || \
      step_warn "No prompt templates to copy or copy failed"
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
printf "\n${BOLD}--- Summary ---${RESET}\n"
printf "  ${GREEN}Succeeded${RESET} : %d\n" "${STEPS_OK}"
printf "  ${YELLOW}Warnings${RESET}  : %d\n" "${STEPS_WARN}"
printf "  ${RED}Failures${RESET}  : %d\n\n" "${STEPS_FAIL}"

if [[ "${STEPS_FAIL}" -gt 0 ]]; then
  error "Bootstrap completed with errors. Review the output above."
  exit 1
fi

# BUG 6 fix: Platform-aware next steps
printf "${BOLD}Next steps:${RESET}\n"
printf "  1. Open ${BOLD}AGENTS.md${RESET} in your target repo and customize the\n"
printf "     sections marked ${YELLOW}CUSTOMIZABLE${RESET}:\n"
printf "       - Project Identity (repo name, purpose, users, domain)\n"
printf "       - Architecture Overview (your actual services)\n"
printf "       - Build & Test Commands (your actual commands)\n"
printf "  2. Commit AGENTS.md and .gitignore to your repository.\n"

if [[ "${USING_COPIES}" == true ]] || [[ "${PLATFORM}" == "windows" ]]; then
  printf "  3. ${YELLOW}NOTE:${RESET} Agent config files may be copies (not symlinks).\n"
  printf "     After editing AGENTS.md, re-run with ${BOLD}--update${RESET} to refresh copies.\n"
  if [[ "${PLATFORM}" == "windows" ]]; then
    printf "     To enable real symlinks: Settings > System > For developers > Developer Mode\n"
  fi
else
  printf "  3. Verify symlinks work: ${BOLD}cat CLAUDE.md${RESET} should show AGENTS.md content.\n"
fi

printf "\n"
exit 0
