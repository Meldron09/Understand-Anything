#!/bin/sh
# Seam-1 tracer test: run the conductor on a canned brief in a scratch dir, then assert on the
# lesson folder. Needs the `claude` CLI and a working login; skips (exit 0) without it.
# Run: sh tests/tracer/run.sh        Keep the scratch dir: KEEP=1
here=$(cd "$(dirname "$0")" && pwd)
plugin=$here/../../learn-anything
command -v claude >/dev/null || { echo "skip: claude CLI not found"; exit 0; }
tmp=$(mktemp -d); [ -n "$KEEP" ] || trap 'rm -rf "$tmp"' EXIT
fixture=${1:-brief.md}   # brief.md (tracer) or brief-ladder.md (also asserts level shaping)
slug=$(sed -n 's/^lesson:[[:space:]]*//p' "$here/fixtures/$fixture" | head -n 1)
mkdir -p "$tmp/learn-anything/$slug"
cp "$here/fixtures/$fixture" "$tmp/learn-anything/$slug/brief.md"
cd "$tmp" || exit 1
# acceptEdits plus an explicit tool list: the scratch dir is the only place it can write.
claude -p "/learn-anything:learn $slug" --plugin-dir "$plugin" --permission-mode acceptEdits \
  --allowedTools Skill Read Write Edit Bash > "$tmp/conductor.out" 2>&1 \
  || { cat "$tmp/conductor.out"; echo "FAIL conductor run"; exit 1; }
echo "lesson folder: $tmp/learn-anything/$slug"
sh "$here/assert-lesson.sh" "$tmp/learn-anything/$slug" || exit 1
if grep -q '| shaky\|| missed' "$here/fixtures/$fixture"; then sh "$here/assert-level.sh" "$tmp/learn-anything/$slug"; fi
