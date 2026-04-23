#!/usr/bin/env bash
# gemini-pre-hook.sh — BeforeTool hook adapter for Gemini CLI
# Translates Gemini CLI tool names/args and delegates to core-pre-tool.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../../bin"

# Read raw input from Gemini CLI
INPUT="$(cat)"

# Translate Gemini tools to internal names
# replace -> Edit
# write_file -> Write
# run_shell_command -> Bash
MAPPED_INPUT=$(echo "$INPUT" | jq -c '
  if .tool_name == "replace" then
    .tool_name = "Edit" | .tool_input.replace_all = (.tool_input.allow_multiple // false)
  elif .tool_name == "write_file" then
    .tool_name = "Write"
  elif .tool_name == "run_shell_command" then
    .tool_name = "Bash"
  else
    .
  end')

# Delegate to core script, suppressing its stdout as Gemini CLI requires strictly valid JSON output
export CODE_PREVIEW_BACKEND="geminicli"
echo "$MAPPED_INPUT" | "$BIN_DIR/core-pre-tool.sh" >/dev/null

# Always return success to Gemini CLI to allow the tool to proceed.
# Users should use Gemini policies (decision = "ask_user") if they want a pause.
echo "{}"
