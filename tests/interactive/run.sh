#!/bin/sh
# Interactive-mode tests. Part 1 (always): the real shell around a fixture body, checked with
# verify-html (and a real headless Chrome when one is installed), plus a broken body.
# Part 2 (needs the `claude` CLI and a login; skipped otherwise): conductor on a canned brief with
# modes [interactive], then assert-interactive.sh on the lesson folder.
# Run: sh tests/interactive/run.sh        Keep the scratch dir: KEEP=1
here=$(cd "$(dirname "$0")" && pwd)
plugin=$here/../../learn-anything
sk=$plugin/skills/interactive
v=$plugin/scripts/verify-html
tmp=$(mktemp -d); [ -n "$KEEP" ] || trap 'rm -rf "$tmp"' EXIT
fails=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fails=$((fails + 1)); }

cat "$sk/shell-head.html" "$here/fixtures/body.html" "$sk/shell-tail.html" > "$tmp/good.html"
sh "$v" "$tmp/good.html" && ok "built page passes verify-html" || bad "built page passes verify-html"

# too many widgets: static check passes, but the runtime must not set data-ready
{ cat "$sk/shell-head.html"; for i in 1 2 3 4 5 6; do echo '<section class="widget"></section>'; done; cat "$sk/shell-tail.html"; } > "$tmp/six.html"

printf '%s\n' "- headless chromium: true" > "$tmp/pre.md"
chrome=
for a in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" /Applications/Chromium.app/Contents/MacOS/Chromium; do
  [ -z "$chrome" ] && [ -x "$a" ] && chrome=$a
done
for c in google-chrome chromium chromium-browser; do
  [ -z "$chrome" ] && command -v "$c" >/dev/null 2>&1 && chrome=$c
done
if [ -n "$chrome" ]; then
  export PREFLIGHT_CHROME_APPS=$chrome
  sh "$v" "$tmp/good.html" "$tmp/pre.md" && ok "real browser sets data-ready" || bad "real browser sets data-ready"
  sh "$v" "$tmp/six.html" "$tmp/pre.md" >/dev/null && bad "six widgets must not be ready" || ok "six widgets never become ready"
  unset PREFLIGHT_CHROME_APPS
else
  echo "skip: no headless Chromium, browser checks not run"
fi

{ cat "$sk/shell-head.html"; echo '<img src="https://example.com/x.png">'; cat "$sk/shell-tail.html"; } > "$tmp/url.html"
sh "$v" "$tmp/url.html" >/dev/null && bad "external URL body fails verify-html" || ok "external URL body fails verify-html"

command -v claude >/dev/null || { echo "skip: claude CLI not found, e2e not run"; [ "$fails" -eq 0 ] && echo "all passed"; exit "$fails"; }
slug=tcp-handshake
mkdir -p "$tmp/e2e/learn-anything/$slug"
cp "$here/fixtures/brief.md" "$tmp/e2e/learn-anything/$slug/brief.md"
cd "$tmp/e2e" || exit 1
claude -p "/learn-anything:learn $slug" --plugin-dir "$plugin" --permission-mode acceptEdits \
  --allowedTools Skill Read Write Edit Bash > "$tmp/conductor.out" 2>&1 \
  || { cat "$tmp/conductor.out"; echo "FAIL conductor run"; exit 1; }
echo "lesson folder: $tmp/e2e/learn-anything/$slug"
sh "$here/assert-interactive.sh" "$tmp/e2e/learn-anything/$slug" "$plugin" || fails=$((fails + $?))
exit "$fails"
