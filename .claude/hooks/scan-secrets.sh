#!/bin/bash
# Claude Code PreToolUse hook: Blocks commits containing credential patterns
# Receives JSON on stdin with tool_input.command
# Exit 0 = allow, Exit 2 = block (stderr shown to Claude)
#
# WHY THIS EXISTS: a shipped title in this studio has a live Git access token
# committed across three manifest files. Rotating it breaks builds; leaving it is
# a live credential leak. Manifests and settings files are the usual carriers
# because they look like configuration, not like secrets.
#
# Input schema (PreToolUse for Bash):
# { "tool_name": "Bash", "tool_input": { "command": "git commit -m ..." } }

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
else
    COMMAND=$(echo "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

# Only process git commit commands
if ! echo "$COMMAND" | grep -qE '^git[[:space:]]+commit'; then
    exit 0
fi

# Need a repo to inspect
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    exit 0
fi

STAGED=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED" ]; then
    exit 0
fi

FINDINGS=""

# Credential patterns. POSIX ERE only -- no \d, no lookarounds.
# Each entry: label|pattern
PATTERNS='GitHub PAT (classic)|ghp_[A-Za-z0-9]{20,}
GitHub PAT (fine-grained)|github_pat_[A-Za-z0-9_]{20,}
GitHub OAuth/refresh token|gh[osur]_[A-Za-z0-9]{20,}
GitLab PAT|glpat-[A-Za-z0-9_-]{16,}
Google API key|AIza[A-Za-z0-9_-]{30,}
AWS access key id|A(KIA|SIA)[A-Z0-9]{16}
Slack token|xox[abprs]-[A-Za-z0-9-]{10,}
Private key block|-----BEGIN[A-Z ]*PRIVATE KEY-----
URL with embedded credentials|https://[A-Za-z0-9_.-]+:[A-Za-z0-9_%.-]{8,}@
Generic assigned secret|(api[_-]?key|secret|password|passwd|token|credential)[\"'"'"' ]*[:=][\"'"'"' ]*[A-Za-z0-9_/+=-]{16,}'

for FILE in $STAGED; do
    # Skip deleted files and anything not readable
    [ -f "$FILE" ] || continue

    # Skip our own hook (it necessarily contains the patterns it looks for)
    case "$FILE" in
        *.claude/hooks/scan-secrets.sh) continue ;;
    esac

    echo "$PATTERNS" | while IFS='|' read -r LABEL PATTERN; do
        [ -n "$PATTERN" ] || continue
        HIT=$(grep -nEI "$PATTERN" "$FILE" 2>/dev/null | head -2)
        if [ -n "$HIT" ]; then
            echo "  $FILE"
            echo "    $LABEL"
            echo "$HIT" | sed 's/^/      /' | cut -c1-160
        fi
    done
done > /tmp/.secret-scan-$$ 2>/dev/null

FINDINGS=$(cat /tmp/.secret-scan-$$ 2>/dev/null)
rm -f /tmp/.secret-scan-$$

if [ -n "$FINDINGS" ]; then
    echo "=== BLOCKED: possible secret in staged files ===" >&2
    echo "$FINDINGS" >&2
    echo "" >&2
    echo "A committed credential is not fixed by a later commit -- it stays in history." >&2
    echo "Move the value to the CI secret store, then unstage the file." >&2
    echo "If this is a false positive, say so and the commit can proceed." >&2
    echo "================================================" >&2
    exit 2
fi

exit 0
