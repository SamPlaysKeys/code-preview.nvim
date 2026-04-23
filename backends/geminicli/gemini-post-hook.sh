#!/usr/bin/env bash
# gemini-post-hook.sh — AfterTool hook adapter for Gemini CLI
# Translates Gemini CLI tool names/args and delegates to core-post-tool.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../../bin"

# Read raw input from Gemini CLI
INPUT="$(cat)"

# Translate Gemini tools to internal names
MAPPED_INPUT=$(echo "$INPUT" | jq -c '
  if .tool_name == "replace" then
    .tool_name = "Edit"
  elif .tool_name == "write_file" then
    .tool_name = "Write"
  elif .tool_name == "run_shell_command" then
    .tool_name = "Bash"
  else
    .
  end')

# Delegate to core script
export CODE_PREVIEW_BACKEND="geminicli"
echo "$MAPPED_INPUT" | "$BIN_DIR/core-post-tool.sh" >/dev/null

# Always return success to Gemini CLI
echo "{}"
