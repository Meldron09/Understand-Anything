#!/bin/sh
# Seam-1 quiz test: conductor on a canned brief with modes [quiz], then assert on the lesson folder.
# Needs the `claude` CLI and a working login; skips (exit 0) without it.
# Run: sh tests/quiz/run.sh        Keep the scratch dir: KEEP=1
here=$(cd "$(dirname "$0")" && pwd)
plugin=$here/../../learn-anything
command -v claude >/dev/null || { echo "skip: claude CLI not found"; exit 0; }
tmp=$(mktemp -d); [ -n "$KEEP" ] || trap 'rm -rf "$tmp"' EXIT
slug=tcp-handshake
mkdir -p "$tmp/learn-anything/$slug"
cp "$here/fixtures/brief.md" "$tmp/learn-anything/$slug/brief.md"
cd "$tmp" || exit 1
claude -p "/learn-anything:learn $slug" --plugin-dir "$plugin" --permission-mode acceptEdits \
  --allowedTools Skill Read Write Edit Bash > "$tmp/conductor.out" 2>&1 \
  || { cat "$tmp/conductor.out"; echo "FAIL conductor run"; exit 1; }
echo "lesson folder: $tmp/learn-anything/$slug"
sh "$here/assert-quiz.sh" "$tmp/learn-anything/$slug" "$plugin"
