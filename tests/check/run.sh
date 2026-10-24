#!/bin/sh
# Seam-1 check test: conductor on a canned quiz brief, with the learner's check answers scripted in the
# prompt (headless runs cannot ask). Scenario "miss": take the check, answer "I don't know" to every item,
# accept the re-explanation, answer "I don't know" again. Scenario "decline": decline the check.
# Needs the `claude` CLI and a working login; skips (exit 0) without it.
# Run: sh tests/check/run.sh [miss|decline]        Keep the scratch dir: KEEP=1
here=$(cd "$(dirname "$0")" && pwd)
plugin=$here/../../learn-anything
command -v claude >/dev/null || { echo "skip: claude CLI not found"; exit 0; }
scen=${1:-miss}
tmp=$(mktemp -d); [ -n "$KEEP" ] || trap 'rm -rf "$tmp"' EXIT
slug=tcp-handshake
mkdir -p "$tmp/learn-anything/$slug"
cp "$here/../quiz/fixtures/brief.md" "$tmp/learn-anything/$slug/brief.md"
case $scen in
  miss) script="Scripted learner for the closing check: accept the check; answer \"I don't know\" to every item; accept the re-explanation if offered, say you are ready, and answer \"I don't know\" to every re-asked item." ;;
  decline) script="Scripted learner for the closing check: decline the check." ;;
  *) echo "usage: run.sh [miss|decline]"; exit 2 ;;
esac
cd "$tmp" || exit 1
# acceptEdits plus an explicit tool list: the scratch dir is the only place it can write.
claude -p "/learn-anything:learn $slug

$script Nobody can reply interactively: act on this script and never wait." --plugin-dir "$plugin" \
  --permission-mode acceptEdits --allowedTools Skill Agent Read Write Edit Bash > "$tmp/conductor.out" 2>&1 \
  || { cat "$tmp/conductor.out"; echo "FAIL conductor run"; exit 1; }
echo "lesson folder: $tmp/learn-anything/$slug"
sh "$here/assert-check.sh" "$tmp/learn-anything/$slug" "$scen"
