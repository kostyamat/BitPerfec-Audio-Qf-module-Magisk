#!/bin/sh
# PreCompact watchman.
#
# The global SessionStart hook (C:/scripts/agents/after_compact.py) already prints the slice,
# git log -6 and git status after a compaction. The one thing it cannot know is whether the
# slice was still current when the window was summarised. This records exactly that.
#
# Writes .agents/.compact-state and returns a systemMessage so the owner sees it fired.

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || ROOT=$(pwd)
cd "$ROOT" 2>/dev/null || exit 0

SLICE=.agents/HANDOFF.md
NOW=$(date '+%Y-%m-%d %H:%M:%S')
HEAD=$(git rev-parse --short HEAD 2>/dev/null || echo '?')
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

if [ -f "$SLICE" ]; then
    AGE=$(( $(date +%s) - $(stat -c %Y "$SLICE" 2>/dev/null || echo 0) ))
else
    AGE=-1
fi

mkdir -p .agents 2>/dev/null
printf '%s | %s %s | брудних %s | зріз: %s\n' \
    "$NOW" "$BRANCH" "$HEAD" "$DIRTY" \
    "$( [ "$AGE" -lt 0 ] && echo 'ВІДСУТНІЙ' || echo "оновлено ${AGE} с тому" )" \
    >> .agents/.compact-state

if [ "$AGE" -lt 0 ]; then
    MSG="PreCompact: зрізу .agents/HANDOFF.md НЕМАЄ — після компакту стан доведеться збирати з git"
elif [ "$AGE" -gt 1800 ]; then
    MSG="PreCompact: зріз старший за 30 хв (${AGE} с) — після компакту звір його з git status, могло щось не потрапити"
else
    MSG="PreCompact: зріз свіжий (${AGE} с), знімок у .agents/.compact-state"
fi

printf '{"systemMessage":"%s"}\n' "$MSG"
