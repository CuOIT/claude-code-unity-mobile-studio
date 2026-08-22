#!/bin/bash
# Claude Code PostToolUse hook: Validates the UPM manifest after a write
# Fires when Packages/manifest.json is written or edited.
#
# Exit behavior:
#   exit 0 = advisory only (non-blocking)
#
# WHY THIS EXISTS: the CuOCore consumer manifest currently resolves five packages
# from local filesystem paths. That contradicts its own dependency policy, makes
# two of its integration tests unpassable, and means the project builds on exactly
# one machine. A local path in a shared manifest is not a preference violation --
# it is a build that only works for one person.
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

# Only act on a UPM manifest
if ! echo "$FILE_PATH" | grep -qE '(^|/)Packages/manifest\.json$'; then
    exit 0
fi

[ -f "$FILE_PATH" ] || exit 0

ISSUES=0

# JSON validity first -- an invalid manifest fails Unity's package resolution outright
if command -v python >/dev/null 2>&1; then
    if ! python -m json.tool "$FILE_PATH" >/dev/null 2>&1; then
        echo "=== UPM manifest is not valid JSON ===" >&2
        echo "  $FILE_PATH" >&2
        echo "  Unity will fail package resolution. Fix before anything else." >&2
        echo "======================================" >&2
        exit 0
    fi
fi

echo "=== UPM manifest check: $FILE_PATH ===" >&2

# 1. Local filesystem references
LOCAL_REFS=$(grep -nE '"file:' "$FILE_PATH" 2>/dev/null)
if [ -n "$LOCAL_REFS" ]; then
    COUNT=$(echo "$LOCAL_REFS" | wc -l | tr -d ' ')
    echo "  ERROR: $COUNT local 'file:' reference(s) -- resolves on this machine only" >&2
    echo "$LOCAL_REFS" | sed 's/^/    /' | cut -c1-140 >&2
    echo "    Acceptable only on an unshared branch during local package work." >&2
    echo "    See .claude/rules/upm-consumption.md" >&2
    ISSUES=$((ISSUES + 1))
fi

# 2. Credentials embedded in dependency URLs
CREDS=$(grep -nE 'https://[A-Za-z0-9_.-]+:[A-Za-z0-9_%.-]{8,}@|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|glpat-[A-Za-z0-9_-]{16,}' "$FILE_PATH" 2>/dev/null)
if [ -n "$CREDS" ]; then
    echo "  ERROR: credential embedded in a dependency URL" >&2
    echo "$CREDS" | sed 's/^/    /' | cut -c1-100 >&2
    echo "    A committed token stays in git history. Use the CI secret store." >&2
    ISSUES=$((ISSUES + 1))
fi

# 3. Duplicate package keys -- last one silently wins
DUPES=$(grep -oE '"(com|org)\.[A-Za-z0-9_.-]+"[[:space:]]*:' "$FILE_PATH" 2>/dev/null \
        | sed 's/[[:space:]]*:$//' | sort | uniq -d)
if [ -n "$DUPES" ]; then
    echo "  ERROR: duplicate package key(s) -- the last occurrence silently wins" >&2
    echo "$DUPES" | sed 's/^/    /' >&2
    ISSUES=$((ISSUES + 1))
fi

# 4. Addressables added without call sites (advisory)
if grep -qE '"com\.unity\.addressables"' "$FILE_PATH" 2>/dev/null; then
    SITES=0
    if [ -d src ]; then
        SITES=$(grep -rlE '\bAddressables\.' src 2>/dev/null | wc -l | tr -d ' ')
    fi
    if [ "$SITES" = "0" ]; then
        echo "  WARNING: Addressables is declared but Assets/Scripts/ has no call sites" >&2
        echo "    Two reference titles carry it unused. Do not install it until there is" >&2
        echo "    remote content to update -- see .claude/rules/mobile-code.md" >&2
    fi
fi

# 5. Testables coverage (advisory)
if grep -qE '"testables"' "$FILE_PATH" 2>/dev/null; then
    :
else
    echo "  WARNING: no 'testables' array -- package tests will not run" >&2
fi

if [ "$ISSUES" = "0" ]; then
    echo "  OK" >&2
fi
echo "=======================================" >&2

exit 0
