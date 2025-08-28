#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Debug mode (set DEBUG=1 to enable)
DEBUG="${DEBUG:-0}"

# ---- helpers ---------------------------------------------------------------
append_block () {
  # $1 = filepath; $2 = output file
  local fp="$1" out="$2"
  printf "\n---FILE: %s---\n" "$fp" >> "$out"
  cat "$fp" >> "$out"
  printf "\n" >> "$out"
}

# ---- build dynamic prompt --------------------------------------------------
PROMPT_FILE="$(mktemp)"
echo "[iterate] Building prompt from specs and fix_plan..."
{
  printf "SYSTEM\nYou are the single iteration of the Ralph loop.\n\n"
  printf "STACK (verbatim contents follow):\n"
} > "$PROMPT_FILE"

# 1) dynamically include ALL specs/*
if [ -d specs ]; then
  # find is portable on macOS; sort for deterministic order
  while IFS= read -r fp; do
    append_block "$fp" "$PROMPT_FILE"
  done < <(find specs -type f -name "*.md" -maxdepth 1 2>/dev/null | sort)
fi

# 2) include fix_plan.md (required)
if [ -f fix_plan.md ]; then
  append_block "fix_plan.md" "$PROMPT_FILE"
fi

# 3) include CLAUDE.md as SIGNS if present
if [ -f CLAUDE.md ]; then
  printf "\nSIGNS (binding rules from CLAUDE.md):\n" >> "$PROMPT_FILE"
  append_block "CLAUDE.md" "$PROMPT_FILE"
fi

# 4) closing instructions + strict output contract
cat >> "$PROMPT_FILE" <<'EOF'

INSTRUCTIONS
- Follow SIGNS strictly (no placeholders; search before write; minimal compiling diffs).
- Select the first unblocked task from fix_plan.md.
- You may use tools to read files, search the codebase, and write code as needed.
- After completing your implementation, return STRICT JSON with: selected_task_id, why_this_task, plan, diffs[], validator{}, fix_plan_updates[].
- Diffs must be unified patches that apply cleanly with `git apply`.

OUTPUT
After using any necessary tools to complete the task, return ONLY the JSON object (no fences, no extra text) as your final message.
EOF

# ---- run Claude Code (headless) -------------------------------------------
echo "[iterate] Calling Claude to process iteration..."

# Save prompt for debugging
if [ "$DEBUG" = "1" ]; then
  cp "$PROMPT_FILE" .claude/last-prompt.md
  echo "[iterate] Prompt saved to .claude/last-prompt.md"
fi

# Note: We don't specify --max-turns to allow Claude to use as many turns as needed
# We use --allowedTools to permit file operations without permission prompts
# The final response should be the JSON object after completing the implementation
ITER_RESPONSE="$(claude -p "$(cat "$PROMPT_FILE")" \
  --allowedTools Read,Write,Edit,MultiEdit,Grep,Glob,LS,Bash 2>&1 || echo '{}')"

mkdir -p .claude

# Save raw response for debugging
if [ "$DEBUG" = "1" ]; then
  echo "$ITER_RESPONSE" > .claude/last-response-raw.txt
  echo "[iterate] Raw response saved to .claude/last-response-raw.txt"
fi

# Try to parse as JSON, fall back to extracting from response
# Claude may output tool usage logs before the final JSON, so we look for the last JSON object
if echo "$ITER_RESPONSE" | jq empty 2>/dev/null; then
  ITER_JSON="$ITER_RESPONSE"
  echo "[iterate] Response is valid JSON"
else
  echo "[iterate] Response contains non-JSON text, extracting JSON object..."
  # Try to extract the last JSON object from the response (Claude's final output)
  # This handles cases where tool usage is logged before the JSON
  ITER_JSON=$(echo "$ITER_RESPONSE" | tac | grep -m1 -o '{.*}' | tac || echo '{}')
  
  # If still no valid JSON, try to find a more complex JSON structure
  if [ "$ITER_JSON" = "{}" ] || ! echo "$ITER_JSON" | jq empty 2>/dev/null; then
    # Extract everything between first { and last } (handles multiline JSON)
    ITER_JSON=$(echo "$ITER_RESPONSE" | awk '/^{/{p=1} p{print} /^}/{if(p) exit}' || echo '{}')
  fi
  
  if [ "$ITER_JSON" = "{}" ] || ! echo "$ITER_JSON" | jq empty 2>/dev/null; then
    echo "[iterate] ERROR: Could not extract valid JSON from response"
    echo "[iterate] Run with DEBUG=1 to see the full response"
    exit 1
  fi
  echo "[iterate] Successfully extracted JSON from response"
fi

echo "${ITER_JSON}" > .claude/.last-iteration.json

# ---- apply diffs safely ----------------------------------------------------
# Guard against missing or null .diffs
if jq -e '.diffs and (.diffs | length > 0)' .claude/.last-iteration.json >/dev/null 2>&1; then
  jq -r '.diffs[] | @base64' .claude/.last-iteration.json | while read -r row; do
    _jq() { echo "$row" | base64 --decode | jq -r "$1"; }
    diff=$(_jq '.unified_diff')
    # Apply; allow empty in case the agent chose a plan-only turn
    printf "%s" "$diff" | git apply --index --allow-empty
  done
else
  echo "[iterate] no diffs returned."
fi

# ---- prepare validator payload --------------------------------------------
VAL_PAYLOAD="$(jq -c '.validator // {}' .claude/.last-iteration.json)"
echo "$VAL_PAYLOAD" > .claude/.validator-input.json

# ---- run validator with real commands --------------------------------------
echo "[validate] Running actual build/test commands..."

# Initialize validation results
VAL_JSON='{"format": {}, "build": {}, "tests": {}, "lint": {}, "overall_ok": true}'

# 1. Format check (if swift-format is available and format_after has files)
FORMAT_FILES=$(echo "$VAL_PAYLOAD" | jq -r '.format_after[]?' 2>/dev/null)
if command -v swift-format >/dev/null 2>&1 && [ -n "$FORMAT_FILES" ]; then
  echo "[validate] Running swift-format..."
  FORMAT_OK=true
  for file in $FORMAT_FILES; do
    if [ -f "$file" ]; then
      swift-format format -i "$file" 2>&1 || FORMAT_OK=false
    fi
  done
  VAL_JSON=$(echo "$VAL_JSON" | jq ".format = {\"ok\": $FORMAT_OK, \"details\": []}")
else
  VAL_JSON=$(echo "$VAL_JSON" | jq '.format = {"ok": true, "details": [], "skipped": true}')
fi

# 2. Build (only if Package.swift exists)
if [ -f "Package.swift" ]; then
  echo "[validate] Running swift build..."
  BUILD_OUTPUT=$(swift build 2>&1)
  BUILD_EXIT=$?
  if [ $BUILD_EXIT -eq 0 ]; then
    VAL_JSON=$(echo "$VAL_JSON" | jq '.build = {"ok": true, "details": []}')
  else
    # Extract first few error lines for context
    BUILD_ERRORS=$(echo "$BUILD_OUTPUT" | grep -E "error:|warning:" | head -5 | jq -Rs .)
    VAL_JSON=$(echo "$VAL_JSON" | jq --argjson errs "$BUILD_ERRORS" '.build = {"ok": false, "details": [$errs]} | .overall_ok = false')
  fi
else
  VAL_JSON=$(echo "$VAL_JSON" | jq '.build = {"ok": true, "details": [], "skipped": "No Package.swift"}')
fi

# 3. Tests (only if Package.swift exists and build succeeded)
if [ -f "Package.swift" ] && [ "$(echo "$VAL_JSON" | jq -r '.build.ok')" = "true" ]; then
  echo "[validate] Running swift test..."
  TEST_OUTPUT=$(swift test 2>&1)
  TEST_EXIT=$?
  
  # Parse test output for summary
  PASSED=$(echo "$TEST_OUTPUT" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+' | head -1 || echo 0)
  FAILED=$(echo "$TEST_OUTPUT" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' | head -1 || echo 0)
  
  if [ $TEST_EXIT -eq 0 ]; then
    VAL_JSON=$(echo "$VAL_JSON" | jq --arg p "$PASSED" '.tests = {"ok": true, "summary": {"passed": ($p | tonumber), "failed": 0, "skipped": 0}, "failures": []}')
  else
    TEST_FAILURES=$(echo "$TEST_OUTPUT" | grep -A2 "XCTAssert" | head -10 | jq -Rs .)
    VAL_JSON=$(echo "$VAL_JSON" | jq --arg p "$PASSED" --arg f "$FAILED" --argjson fail "$TEST_FAILURES" \
      '.tests = {"ok": false, "summary": {"passed": ($p | tonumber), "failed": ($f | tonumber), "skipped": 0}, "failures": [$fail]} | .overall_ok = false')
  fi
else
  VAL_JSON=$(echo "$VAL_JSON" | jq '.tests = {"ok": true, "summary": {"passed": 0, "failed": 0, "skipped": 0}, "skipped": true}')
fi

# 4. Lint (if swiftlint is available)
if command -v swiftlint >/dev/null 2>&1 && [ -f "Package.swift" ]; then
  echo "[validate] Running swiftlint..."
  LINT_OUTPUT=$(swiftlint --quiet 2>&1 || true)
  LINT_ISSUES=$(echo "$LINT_OUTPUT" | grep -E "warning:|error:" | wc -l | tr -d ' ')
  
  if [ "$LINT_ISSUES" -eq 0 ]; then
    VAL_JSON=$(echo "$VAL_JSON" | jq '.lint = {"ok": true, "issues": []}')
  else
    # Get first few lint issues
    LINT_DETAILS=$(echo "$LINT_OUTPUT" | grep -E "warning:|error:" | head -5 | jq -Rs .)
    VAL_JSON=$(echo "$VAL_JSON" | jq --argjson issues "$LINT_DETAILS" '.lint = {"ok": true, "issues": [$issues], "count": '"$LINT_ISSUES"'}')
  fi
else
  VAL_JSON=$(echo "$VAL_JSON" | jq '.lint = {"ok": true, "issues": [], "skipped": true}')
fi

echo "$VAL_JSON" > .claude/.last-validation.json
echo "[validate] Overall result: $(echo "$VAL_JSON" | jq -r '.overall_ok')"
jq '.overall_ok' .claude/.last-validation.json
