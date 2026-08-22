#!/usr/bin/env bash
# Install this Claude Code configuration into an existing Unity project.
#
#   ./tools/install-into-unity-project.sh <target-unity-project> [options]
#
# Options:
#   --code-root <path>   Where first-party C# lives, relative to the project root.
#                        Default: Assets/Scripts
#                        Rule scopes, hook guards, and skill greps are rewritten to
#                        match. Pass Assets/_Game if that is where your code lives.
#   --test-root <path>   Where test assemblies live. Default: Assets/Tests
#   --dry-run            Print what would happen; write nothing.
#   --force              Overwrite colliding files instead of writing them alongside.
#
# What it copies:  .claude/ (agents, skills, rules, hooks, docs, statusline)
#                  CLAUDE.md, docs/registry/, docs/engine-reference/unity/
#                  design/ and production/ skeletons
#
# What it never copies: README.md, LICENSE, UPGRADING.md, CONTRIBUTING.md,
#                       SECURITY.md, .gitignore, and this tools/ directory.
#                       Those belong to this repo, not to your game.
#
# Collisions are never silently overwritten. Without --force, a colliding file is
# written next to the original with a .claudeunity suffix and reported at the end.

set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET=""
CODE_ROOT="Assets/Scripts"
TEST_ROOT="Assets/Tests"
DRY=0
FORCE=0

while [ $# -gt 0 ]; do
    case "$1" in
        --code-root) CODE_ROOT="$2"; shift 2 ;;
        --test-root) TEST_ROOT="$2"; shift 2 ;;
        --dry-run)   DRY=1; shift ;;
        --force)     FORCE=1; shift ;;
        -h|--help)   sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        -*)          echo "Unknown option: $1" >&2; exit 1 ;;
        *)           TARGET="$1"; shift ;;
    esac
done

die() { echo "ERROR: $*" >&2; exit 1; }
say() { echo "$*"; }
run() { if [ "$DRY" = "1" ]; then echo "    would: $*"; else eval "$@"; fi; }

# ── Validate ────────────────────────────────────────────────────────────────
[ -n "$TARGET" ] || die "no target given. Usage: $0 <target-unity-project> [options]"
[ -d "$TARGET" ] || die "target does not exist: $TARGET"
TARGET="$(cd "$TARGET" && pwd)"
[ "$TARGET" != "$SRC" ] || die "target is this repository. Install into a different project."

[ -f "$TARGET/ProjectSettings/ProjectVersion.txt" ] \
    || die "not a Unity project (no ProjectSettings/ProjectVersion.txt): $TARGET"

UNITY_VER=$(grep -m1 'm_EditorVersion:' "$TARGET/ProjectSettings/ProjectVersion.txt" | awk '{print $2}')

if git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
    GIT_ROOT=$(git -C "$TARGET" rev-parse --show-toplevel)
    # Normalise Windows drive paths (git prints D:/x, MSYS uses /d/x) for comparison
    GIT_ROOT_CMP=$(cd "$GIT_ROOT" && pwd)
    GIT_BRANCH=$(git -C "$TARGET" rev-parse --abbrev-ref HEAD)
    DIRTY=$(git -C "$TARGET" status --porcelain | wc -l | tr -d ' ')
else
    GIT_ROOT=""; GIT_ROOT_CMP=""; GIT_BRANCH=""; DIRTY=0
fi

say "=========================================================="
say " Installing Claude Code config into a Unity project"
say "=========================================================="
say "  source      : $SRC"
say "  target      : $TARGET"
say "  unity       : $UNITY_VER"
say "  git         : ${GIT_ROOT:-<not a git repo>} ${GIT_BRANCH:+($GIT_BRANCH)}"
say "  code root   : $CODE_ROOT"
say "  test root   : $TEST_ROOT"
say "  mode        : $([ "$DRY" = 1 ] && echo DRY-RUN || echo WRITE)$([ "$FORCE" = 1 ] && echo ' --force')"
say ""

if [ -n "$GIT_ROOT" ] && [ "$DIRTY" != "0" ] && [ "$DRY" = "0" ]; then
    say "  WARNING: target has $DIRTY uncommitted change(s)."
    say "  Commit or stash first so this install is reviewable as its own diff."
    say ""
    printf "  Continue anyway? [y/N] "
    read -r ans; case "$ans" in [yY]*) ;; *) die "aborted by user"; esac
    say ""
fi

if [ -n "$GIT_ROOT_CMP" ] && [ "$GIT_ROOT_CMP" != "$TARGET" ]; then
    say "  NOTE: the Unity project is not the git root."
    say "        git root: $GIT_ROOT"
    say "        Config is installed at the Unity project root, which is where"
    say "        Claude Code must be started for .claude/ to load."
    say ""
fi

COLLISIONS=()

copy_tree() {  # copy_tree <relative path>
    local rel="$1" s="$SRC/$1" t="$TARGET/$1"
    [ -e "$s" ] || return 0
    if [ -e "$t" ] && [ "$FORCE" = "0" ] && [ -f "$s" ]; then
        COLLISIONS+=("$rel")
        run "mkdir -p \"$(dirname "$t")\""
        run "cp \"$s\" \"$t.claudeunity\""
        say "  collide  $rel  -> wrote $rel.claudeunity"
        return 0
    fi
    run "mkdir -p \"$(dirname "$t")\""
    run "cp -R \"$s\" \"$t\""
    say "  copied   $rel"
}

# ── 1. The config layer ─────────────────────────────────────────────────────
say "-- .claude/ --"
for d in agents skills rules hooks docs; do copy_tree ".claude/$d"; done
copy_tree ".claude/statusline.sh"
copy_tree ".claude/settings.json"

say ""
say "-- project docs --"
copy_tree "CLAUDE.md"
copy_tree "docs/registry"
copy_tree "docs/engine-reference"
copy_tree "design/CLAUDE.md"
copy_tree "design/registry"
copy_tree "docs/COLLABORATIVE-DESIGN-PRINCIPLE.md"

# ── 2. Skeletons ────────────────────────────────────────────────────────────
say ""
say "-- skeleton directories --"
for d in "design/gdd" "design/art" "design/ux" \
         "docs/architecture" \
         "production/epics" "production/sprints" "production/playtests" \
         "production/session-state" "production/session-logs"; do
    if [ -d "$TARGET/$d" ]; then
        say "  exists   $d"
    else
        run "mkdir -p \"$TARGET/$d\""
        run "touch \"$TARGET/$d/.gitkeep\""
        say "  created  $d"
    fi
done

# ── 3. Rewrite path scopes to this project's layout ─────────────────────────
say ""
say "-- path scopes --"
if [ "$CODE_ROOT" = "Assets/Scripts" ] && [ "$TEST_ROOT" = "Assets/Tests" ]; then
    say "  defaults match the shipped config -- nothing to rewrite"
else
    say "  rewriting Assets/Scripts -> $CODE_ROOT"
    say "  rewriting Assets/Tests   -> $TEST_ROOT"
    if [ "$DRY" = "1" ]; then
        say "    would rewrite: .claude/rules/*.md .claude/hooks/*.sh .claude/skills/*/SKILL.md .claude/docs/*.md CLAUDE.md"
    else
        find "$TARGET/.claude/rules" "$TARGET/.claude/hooks" "$TARGET/.claude/skills" \
             "$TARGET/.claude/docs" -type f \( -name '*.md' -o -name '*.sh' -o -name '*.yaml' \) 2>/dev/null \
        | while read -r f; do
            sed -i "s|Assets/Scripts|$CODE_ROOT|g; s|Assets/Tests|$TEST_ROOT|g" "$f"
        done
        [ -f "$TARGET/CLAUDE.md" ] && sed -i "s|Assets/Scripts|$CODE_ROOT|g; s|Assets/Tests|$TEST_ROOT|g" "$TARGET/CLAUDE.md"
        say "  done"
    fi
fi

# ── 3b. Machine-local paths ─────────────────────────────────────────────────
say ""
say "-- machine-local paths --"
LP="$TARGET/.claude/docs/local-paths.md"
LPT="$TARGET/.claude/docs/local-paths.template.md"
if [ -f "$LP" ]; then
    say "  exists   .claude/docs/local-paths.md (left untouched)"
elif [ -f "$LPT" ]; then
    run "cp \"$LPT\" \"$LP\""
    say "  created  .claude/docs/local-paths.md from the template"
    say "  ACTION REQUIRED: fill it in. Reference-project and CuOCore paths differ"
    say "  per machine, so nothing is prefilled. An entry pointing at a missing"
    say "  directory is worse than a blank one."
    NEEDS_LOCAL_PATHS=1
else
    say "  template missing -- skipped"
fi

# ── 4. .gitignore ───────────────────────────────────────────────────────────
say ""
say "-- .gitignore --"
GI="$TARGET/.gitignore"
NEEDED=("production/session-state/active.md" "production/session-logs/" ".claude/settings.local.json" ".claude/docs/local-paths.md")
if [ ! -f "$GI" ]; then
    say "  no .gitignore in target -- skipping (Unity projects should have one)"
else
    for entry in "${NEEDED[@]}"; do
        if grep -qF "$entry" "$GI" 2>/dev/null; then
            say "  present  $entry"
        else
            if [ "$DRY" = "1" ]; then
                say "  would add  $entry"
            else
                printf '\n# Claude Code session state\n%s\n' "$entry" >> "$GI"
                say "  added    $entry"
            fi
        fi
    done
fi

# ── 5. Report ───────────────────────────────────────────────────────────────
say ""
say "=========================================================="
if [ "${#COLLISIONS[@]}" -gt 0 ]; then
    say " MANUAL MERGE REQUIRED -- ${#COLLISIONS[@]} file(s) already existed"
    say "=========================================================="
    for c in "${COLLISIONS[@]}"; do
        say "  $c"
        say "      yours : $TARGET/$c"
        say "      new   : $TARGET/$c.claudeunity"
    done
    say ""
    say "  For .claude/settings.json: merge the \"hooks\" block from the .claudeunity"
    say "  copy into yours. Keep your own permissions. All 15 hooks are needed for"
    say "  the guardrails to fire."
    say ""
    say "  For CLAUDE.md: the new copy is a set of @imports. Merge those import lines"
    say "  into your existing file rather than replacing it."
    say ""
else
    say " No collisions."
    say "=========================================================="
fi

say " NEXT STEPS"
say "=========================================================="
if [ "${NEEDS_LOCAL_PATHS:-0}" = "1" ]; then
    say "  0. Fill in .claude/docs/local-paths.md -- CuOCore checkout and any local"
    say "     reference projects. Leave rows blank if they are not on this machine."
    say ""
fi
say "  1. cd \"$TARGET\" && claude"
say "  2. Run /help -- it reads real project state and names one next step."
say "  3. Run /project-stage-detect for a full audit of what exists."
say ""
say "  Verify the guardrails actually fire (they are path-scoped, so a wrong"
say "  code root silently disables them):"
say ""
say "     /mobile-build-check          expect real findings, not an empty report"
say "     /feature-flag audit          expect it to see your existing flag reads"
say ""
say "  If either comes back suspiciously clean, the code root is wrong. Re-run"
say "  this script with --code-root pointing at where your C# actually lives."
say ""
[ "$DRY" = "1" ] && say "  (dry run -- nothing was written)"
exit 0
