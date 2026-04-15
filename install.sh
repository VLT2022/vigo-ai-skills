#!/usr/bin/env bash
#
# vigo-ai-skills installer
#
# Detects installed AI tools (Claude Code / Claude Desktop / Cursor / Codex CLI /
# OpenCode / OpenClaw / Windsurf) and copies the vigo-find-house Skill to the
# correct directory for each selected target. Then prints next steps for wiring
# up the MCP config with an X-API-Key.
#
# Usage:
#   ./install.sh              # interactive picker
#   ./install.sh --all        # install to every detected tool without prompting
#   ./install.sh --dry-run    # show what would happen, don't touch disk
#   NO_COLOR=1 ./install.sh   # disable ANSI colors
#
# Compatible with macOS / Linux / WSL. Pure bash (no zsh features).

set -euo pipefail

# ---------- Config ----------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="${SCRIPT_DIR}/skills/vigo-find-house"
SKILL_NAME="vigo-find-house"
MCP_CONFIG_SRC="${SKILL_SRC}/mcp-config.json"

DRY_RUN=0
ALL=0

# ---------- Colors ----------

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RED="$(printf '\033[31m')"
  C_GREEN="$(printf '\033[32m')"
  C_YELLOW="$(printf '\033[33m')"
  C_BLUE="$(printf '\033[34m')"
  C_BOLD="$(printf '\033[1m')"
  C_DIM="$(printf '\033[2m')"
  C_RESET="$(printf '\033[0m')"
else
  C_RED=""
  C_GREEN=""
  C_YELLOW=""
  C_BLUE=""
  C_BOLD=""
  C_DIM=""
  C_RESET=""
fi

info()    { printf '%s[info]%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()      { printf '%s[ ok ]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()    { printf '%s[warn]%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
err()     { printf '%s[err ]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
hr()      { printf '%s\n' "$C_DIM----------------------------------------$C_RESET"; }

# ---------- Platform detection ----------

detect_platform() {
  local uname_out
  uname_out="$(uname -s 2>/dev/null || echo unknown)"
  case "$uname_out" in
    Darwin*)   echo "macos" ;;
    Linux*)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    MINGW*|CYGWIN*|MSYS*) echo "windows-git-bash" ;;
    *) echo "unknown" ;;
  esac
}

# ---------- Tool detection ----------
#
# Each tool gets a detection function and a target Skill directory function.
# Detection returns 0 (found) or 1 (not found).
# Target dir function prints the destination directory for the Skill (without
# the trailing vigo-find-house segment — that is appended by do_install).
#
# Tools tested (by canonical id):
#   claude-code
#   claude-desktop
#   cursor
#   windsurf
#   codex-cli
#   opencode
#   cline           (VSCode extension — uses global MCP config, no skills dir)
#   continue        (no skills dir)

# --- Claude Code ---

detect_claude_code() {
  [ -d "$HOME/.claude" ] && return 0
  command -v claude >/dev/null 2>&1 && return 0
  return 1
}

target_claude_code() {
  printf '%s\n' "$HOME/.claude/skills"
}

# --- Claude Desktop ---

detect_claude_desktop() {
  local platform
  platform="$(detect_platform)"
  case "$platform" in
    macos)
      [ -d "$HOME/Library/Application Support/Claude" ] && return 0
      [ -d "/Applications/Claude.app" ] && return 0
      ;;
    linux|wsl)
      [ -d "$HOME/.config/Claude" ] && return 0
      ;;
    windows-git-bash)
      [ -d "${APPDATA:-$HOME/AppData/Roaming}/Claude" ] && return 0
      ;;
  esac
  return 1
}

target_claude_desktop() {
  local platform
  platform="$(detect_platform)"
  case "$platform" in
    macos)
      printf '%s\n' "$HOME/Library/Application Support/Claude/skills"
      ;;
    linux|wsl)
      printf '%s\n' "$HOME/.config/Claude/skills"
      ;;
    windows-git-bash)
      printf '%s\n' "${APPDATA:-$HOME/AppData/Roaming}/Claude/skills"
      ;;
    *)
      printf '%s\n' "$HOME/.claude-desktop/skills"
      ;;
  esac
}

# --- Cursor ---

detect_cursor() {
  local platform
  platform="$(detect_platform)"
  case "$platform" in
    macos)
      [ -d "/Applications/Cursor.app" ] && return 0
      [ -d "$HOME/Library/Application Support/Cursor" ] && return 0
      ;;
    linux|wsl)
      [ -d "$HOME/.config/Cursor" ] && return 0
      ;;
  esac
  command -v cursor >/dev/null 2>&1 && return 0
  return 1
}

target_cursor() {
  # Cursor uses .cursor/rules/ per-project. For global we use ~/.cursor/rules/.
  # The Skill is copied as a directory under rules/. Cursor loads .mdc files —
  # our SKILL.md also works but with a slight format difference. See docs.
  printf '%s\n' "$HOME/.cursor/rules"
}

# --- Windsurf ---

detect_windsurf() {
  local platform
  platform="$(detect_platform)"
  case "$platform" in
    macos)
      [ -d "/Applications/Windsurf.app" ] && return 0
      [ -d "$HOME/Library/Application Support/Windsurf" ] && return 0
      ;;
    linux|wsl)
      [ -d "$HOME/.config/Windsurf" ] && return 0
      ;;
  esac
  command -v windsurf >/dev/null 2>&1 && return 0
  return 1
}

target_windsurf() {
  printf '%s\n' "$HOME/.codeium/windsurf/skills"
}

# --- Codex CLI ---

detect_codex_cli() {
  [ -d "$HOME/.codex" ] && return 0
  command -v codex >/dev/null 2>&1 && return 0
  return 1
}

target_codex_cli() {
  printf '%s\n' "$HOME/.codex/skills"
}

# --- OpenCode / OpenClaw ---

detect_opencode() {
  [ -d "$HOME/.opencode" ] && return 0
  [ -d "$HOME/.openclaw" ] && return 0
  command -v opencode >/dev/null 2>&1 && return 0
  return 1
}

target_opencode() {
  if [ -d "$HOME/.openclaw" ]; then
    printf '%s\n' "$HOME/.openclaw/skills"
  else
    printf '%s\n' "$HOME/.opencode/skills"
  fi
}

# ---------- Tool registry ----------
#
# Parallel arrays keep bash 3.2 compatible (macOS default).

TOOL_IDS=(
  "claude-code"
  "claude-desktop"
  "cursor"
  "windsurf"
  "codex-cli"
  "opencode"
)

TOOL_LABELS=(
  "Claude Code (Anthropic CLI)"
  "Claude Desktop (Anthropic macOS/Windows app)"
  "Cursor (Cursor IDE)"
  "Windsurf (Codeium IDE)"
  "Codex CLI (OpenAI)"
  "OpenCode / OpenClaw"
)

# ---------- Installation logic ----------

do_install() {
  local tool_id="$1"
  local dest_dir
  case "$tool_id" in
    claude-code)     dest_dir="$(target_claude_code)" ;;
    claude-desktop)  dest_dir="$(target_claude_desktop)" ;;
    cursor)          dest_dir="$(target_cursor)" ;;
    windsurf)        dest_dir="$(target_windsurf)" ;;
    codex-cli)       dest_dir="$(target_codex_cli)" ;;
    opencode)        dest_dir="$(target_opencode)" ;;
    *)
      err "Unknown tool: $tool_id"
      return 1
      ;;
  esac

  local dest_skill="$dest_dir/$SKILL_NAME"

  info "Installing to $tool_id"
  info "  source: $SKILL_SRC"
  info "  dest:   $dest_skill"

  if [ "$DRY_RUN" -eq 1 ]; then
    warn "  [dry-run] skipped actual copy"
    return 0
  fi

  mkdir -p "$dest_dir"

  if [ -d "$dest_skill" ]; then
    warn "  destination already exists, overwriting: $dest_skill"
    rm -rf "$dest_skill"
  fi

  # Use cp -R (works on both BSD and GNU cp).
  cp -R "$SKILL_SRC" "$dest_skill"

  ok "  installed $SKILL_NAME → $dest_skill"
}

print_next_steps() {
  hr
  printf '%s%sNext steps%s\n' "$C_BOLD" "$C_GREEN" "$C_RESET"
  hr
  cat <<'EOF'

1. Get an API Key from vigolive:

   - Open the vigolive 小程序 on WeChat
   - Go to 我的 → AI 接入 → 生成新的 API Key
   - Copy the full vgk_live_xxx key (shown only once!)

2. Add MCP config to your AI tool:

   The template is at:
     skills/vigo-find-house/mcp-config.json

   Copy the "mcpServers.vigo-mcp" block into your tool's MCP config file and
   replace <PASTE_YOUR_VGK_LIVE_KEY_HERE> with your real key.

   Common config file locations:

   - Claude Code:        ~/.claude/.mcp.json or <project>/.mcp.json
   - Claude Desktop:
       macOS             ~/Library/Application Support/Claude/claude_desktop_config.json
       Linux             ~/.config/Claude/claude_desktop_config.json
       Windows           %APPDATA%\Claude\claude_desktop_config.json
   - Cursor:             ~/.cursor/mcp.json or <project>/.cursor/mcp.json
   - Windsurf:           ~/.codeium/windsurf/mcp_config.json
   - Codex CLI:          ~/.codex/config.toml  (MCP section)
   - OpenCode:           ~/.opencode/config.json

3. Restart the AI tool.

4. Try: "帮我在北京望京 SOHO 附近找 5000 以下整租，通勤 30 分钟内"

Full docs:  docs/how-to-install.md
API Key:    docs/api-key.md
Troubles:   docs/troubleshooting.md
EOF
  hr
}

# ---------- CLI ----------

usage() {
  cat <<EOF
vigo-ai-skills installer

USAGE:
  $0 [OPTIONS]

OPTIONS:
  --all         Install to every detected AI tool without prompting
  --dry-run     Print actions but don't touch disk
  -h, --help    Show this help

ENV:
  NO_COLOR=1    Disable ANSI colors
EOF
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --all)     ALL=1 ;;
      --dry-run) DRY_RUN=1 ;;
      -h|--help) usage; exit 0 ;;
      *)
        err "Unknown argument: $1"
        usage
        exit 2
        ;;
    esac
    shift
  done
}

# ---------- Main ----------

main() {
  parse_args "$@"

  printf '%s%svigo-ai-skills installer%s\n' "$C_BOLD" "$C_BLUE" "$C_RESET"
  printf '%sSkill:%s %s\n' "$C_DIM" "$C_RESET" "$SKILL_NAME"
  printf '%sSource:%s %s\n' "$C_DIM" "$C_RESET" "$SKILL_SRC"
  printf '%sPlatform:%s %s\n' "$C_DIM" "$C_RESET" "$(detect_platform)"
  hr

  if [ ! -d "$SKILL_SRC" ]; then
    err "Skill source not found: $SKILL_SRC"
    err "Run this script from the vigo-ai-skills repo root."
    exit 1
  fi

  if [ ! -f "$MCP_CONFIG_SRC" ]; then
    err "MCP config template not found: $MCP_CONFIG_SRC"
    exit 1
  fi

  # Detect tools
  local detected_ids=()
  local detected_labels=()
  local i
  for i in "${!TOOL_IDS[@]}"; do
    local tid="${TOOL_IDS[$i]}"
    local tlabel="${TOOL_LABELS[$i]}"
    local detect_fn="detect_${tid//-/_}"
    if $detect_fn; then
      detected_ids+=("$tid")
      detected_labels+=("$tlabel")
      ok "Detected: $tlabel"
    fi
  done

  if [ "${#detected_ids[@]}" -eq 0 ]; then
    warn "No supported AI tools detected on this machine."
    warn "You can still install manually — see docs/how-to-install.md"
    exit 0
  fi

  hr

  # Pick targets
  local selected=()
  if [ "$ALL" -eq 1 ]; then
    selected=("${detected_ids[@]}")
    info "--all specified, installing to every detected tool."
  else
    printf '%sSelect tools to install%s\n' "$C_BOLD" "$C_RESET"
    printf '%s  Enter numbers separated by space, or "a" for all%s\n' "$C_DIM" "$C_RESET"
    printf '\n'
    for i in "${!detected_ids[@]}"; do
      printf '  %s%d)%s %s\n' "$C_BLUE" "$((i+1))" "$C_RESET" "${detected_labels[$i]}"
    done
    printf '\n'
    printf 'Choice [a]: '
    local choice
    # Read from stdin; handle non-interactive gracefully.
    if ! IFS= read -r choice; then
      warn "Non-interactive shell detected, defaulting to --all"
      selected=("${detected_ids[@]}")
    else
      if [ -z "$choice" ] || [ "$choice" = "a" ] || [ "$choice" = "A" ]; then
        selected=("${detected_ids[@]}")
      else
        for num in $choice; do
          case "$num" in
            ''|*[!0-9]*)
              warn "Ignoring non-numeric input: $num"
              continue
              ;;
          esac
          if [ "$num" -ge 1 ] && [ "$num" -le "${#detected_ids[@]}" ]; then
            selected+=("${detected_ids[$((num-1))]}")
          else
            warn "Ignoring out-of-range index: $num"
          fi
        done
      fi
    fi
  fi

  if [ "${#selected[@]}" -eq 0 ]; then
    warn "No tools selected. Exiting."
    exit 0
  fi

  hr

  local tool
  for tool in "${selected[@]}"; do
    if ! do_install "$tool"; then
      err "Failed installing to $tool"
    fi
  done

  print_next_steps
}

main "$@"
