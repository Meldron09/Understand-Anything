#!/bin/sh
# Slides test: run the conductor on a canned slides brief in a scratch dir with `marp` and `npx`
# hidden from PATH (and a preflight.md saying so), then assert on the lesson folder.
# Needs the `claude` CLI and a working login; skips (exit 0) without it.
# Run: sh tests/slides/run.sh        Keep the scratch dir: KEEP=1
#      RENDER=1 sh tests/slides/run.sh   real PATH, no preflight.md; asserts the HTML render (needs marp or npx)
here=$(cd "$(dirname "$0")" && pwd)
plugin=$here/../../learn-anything
command -v claude >/dev/null || { echo "skip: claude CLI not found"; exit 0; }
tmp=$(mktemp -d); [ -n "$KEEP" ] || trap 'rm -rf "$tmp"' EXIT
slug=tcp-handshake
mkdir -p "$tmp/learn-anything/$slug"
cp "$here/fixtures/brief.md" "$tmp/learn-anything/$slug/brief.md"
if [ -z "$RENDER" ]; then
  cp "$here/fixtures/preflight.md" "$tmp/learn-anything/$slug/preflight.md"
  # shim dir: a symlink to every executable on PATH except marp and npx
  mkdir "$tmp/bin"
  oldifs=$IFS; IFS=:
  for dir in $PATH; do
    for f in "$dir"/*; do
      b=${f##*/}
      case $b in marp|npx) continue;; esac
      [ -x "$f" ] && [ ! -e "$tmp/bin/$b" ] && ln -s "$f" "$tmp/bin/$b"
    done
  done
  IFS=$oldifs
  PATH=$tmp/bin
  ! command -v marp >/dev/null && ! command -v npx >/dev/null || { echo "FAIL could not hide marp/npx"; exit 1; }
  mode=norender
fi
cd "$tmp" || exit 1
claude -p "/learn-anything:learn $slug" --plugin-dir "$plugin" --permission-mode acceptEdits \
  --allowedTools Skill Read Write Edit Bash > "$tmp/conductor.out" 2>&1 \
  || { cat "$tmp/conductor.out"; echo "FAIL conductor run"; exit 1; }
echo "lesson folder: $tmp/learn-anything/$slug"
sh "$here/assert-deck.sh" "$tmp/learn-anything/$slug" $mode || exit $?
# the conductor tells the learner how to render, once (norender run only)
if [ "$mode" = norender ]; then
  [ "$(grep -c 'marp-cli' "$tmp/conductor.out")" -ge 1 ] && echo "ok   conductor names the render command" \
    || { echo "FAIL conductor names the render command"; exit 1; }
fi
