#!/bin/sh
# Script-CLI tests for learn-anything/scripts/verify-html: the real quiz shell built from a
# fixture items file (good), and one deliberately broken file per rule.
# Run: sh tests/verify-html/run.sh
here=$(cd "$(dirname "$0")" && pwd)
plugin=$here/../../learn-anything
v=$plugin/scripts/verify-html
fix=$here/fixtures
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fails=0

# expect <name> <file> <exit 0|1> [message substring] [preflight.md]
expect() {
  out=$(sh "$v" "$2" $5 2>&1); rc=$?
  if [ "$rc" -ne "$3" ]; then echo "FAIL $1: exit $rc, want $3"; echo "$out"; fails=$((fails + 1)); return; fi
  if [ -n "$4" ] && ! printf '%s\n' "$out" | grep -qF "$4"; then
    echo "FAIL $1: output lacks '$4'"; echo "$out"; fails=$((fails + 1)); return
  fi
  echo "ok   $1"
}

cat "$plugin/skills/quiz/quiz-head.html" "$fix/items.json" "$plugin/skills/quiz/quiz-tail.html" > "$tmp/good.html"
expect "built quiz passes"               "$tmp/good.html"          0
expect "external URL fails"              "$fix/bad-url.html"       1 "external URL"
expect "unbalanced script fails"         "$fix/bad-script.html"    1 "unbalanced script"
expect "missing getElementById fails"    "$fix/bad-id.html"        1 "target missing: summary"
expect "missing ready marker fails"      "$fix/bad-ready.html"     1 "ready marker missing"

# browser check: a fake chromium that prints a DOM with, or without, data-ready on <body>
printf '#!/bin/sh\necho "<html><body data-ready=\\"1\\"></body></html>"\n' > "$tmp/chrome-ok"
printf '#!/bin/sh\necho "<html><body></body></html>"\n' > "$tmp/chrome-bad"
chmod +x "$tmp/chrome-ok" "$tmp/chrome-bad"
# preflight.md as scripts/preflight writes it; the fake binary is found via PREFLIGHT_CHROME_APPS
printf '%s\n' "- headless chromium: true" > "$tmp/pre-yes.md"
printf '%s\n' "- headless chromium: false" > "$tmp/pre-none.md"
export PREFLIGHT_CHROME_APPS=$tmp/chrome-ok
expect "browser dom with data-ready passes" "$tmp/good.html" 0 "" "$tmp/pre-yes.md"
export PREFLIGHT_CHROME_APPS=$tmp/chrome-bad
expect "browser dom without it fails"       "$tmp/good.html" 1 "data-ready not set on <body>" "$tmp/pre-yes.md"
expect "no chromium skips the browser step" "$tmp/good.html" 0 "" "$tmp/pre-none.md"

[ "$fails" -eq 0 ] && echo "all passed"
exit "$fails"
