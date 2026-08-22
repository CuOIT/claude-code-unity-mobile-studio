#!/bin/bash
# Claude Code PostToolUse hook: Flags feature-flag reads that are not declared
# Fires when a file under Assets/Scripts/ is written or edited.
#
# Exit behavior:
#   exit 0 = advisory only (non-blocking) -- the write already happened
#
# WHY THIS EXISTS: a shipped title in this studio reads a flag key that is absent
# from its registry. It silently returns false on Android, so the feature is
# simply off and nothing reports why. An undeclared flag is not a style problem;
# it is a feature that does not work.
#
# Input schema (PostToolUse for Write|Edit):
# { "tool_name": "Write", "tool_input": { "file_path": "...", "content": "..." } }

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
    FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

FILE_PATH=$(echo "$FILE_PATH" | sed 's|\\|/|g')

# Only act on C# under Assets/Scripts/
if ! echo "$FILE_PATH" | grep -qE '(^|/)Assets/Scripts/.*\.cs$'; then
    exit 0
fi

[ -f "$FILE_PATH" ] || exit 0

REGISTRY=".claude/../docs/registry/feature-flags.yaml"
[ -f "docs/registry/feature-flags.yaml" ] && REGISTRY="docs/registry/feature-flags.yaml"

if [ ! -f "$REGISTRY" ]; then
    echo "=== Feature flag registry missing ===" >&2
    echo "Expected docs/registry/feature-flags.yaml. Run /feature-flag add to create entries." >&2
    exit 0
fi

# Collect flag ids read in this file: IsEnabled("x") / GetMode("x")
LITERALS=$(grep -oE '(IsEnabled|GetMode)[[:space:]]*\([[:space:]]*"[A-Za-z0-9_.]+"' "$FILE_PATH" 2>/dev/null \
           | grep -oE '"[A-Za-z0-9_.]+"' | tr -d '"' | sort -u)

# Any read at all (including via a constant) -- used to advise on the enum rule
ANY_READ=$(grep -cE '(IsEnabled|GetMode)[[:space:]]*\(' "$FILE_PATH" 2>/dev/null)

UNDECLARED=""
for ID in $LITERALS; do
    if ! grep -qE "event_id:[[:space:]]*$ID([[:space:]]|$)" "$REGISTRY" 2>/dev/null; then
        UNDECLARED="$UNDECLARED $ID"
    fi
done

if [ -n "$UNDECLARED" ]; then
    echo "=== Undeclared feature flag(s) in $FILE_PATH ===" >&2
    for ID in $UNDECLARED; do
        echo "  ERROR: '$ID' is read here but has no entry in docs/registry/feature-flags.yaml" >&2
    done
    echo "" >&2
    echo "An undeclared flag resolves to false on device with no error. Fix with:" >&2
    for ID in $UNDECLARED; do
        echo "  /feature-flag add $ID" >&2
    done
    echo "=================================================" >&2
    exit 0
fi

# Advisory: string literals at read sites are how typos become silent false returns
if [ -n "$LITERALS" ]; then
    echo "=== Feature flag read via string literal ===" >&2
    echo "  $FILE_PATH passes a bare string to a flag read." >&2
    echo "  Use a stable id constant instead -- see .claude/rules/feature-flags.md" >&2
    echo "===========================================" >&2
fi

exit 0
