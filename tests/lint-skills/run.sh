#!/bin/sh
# Script-CLI tests for learn-anything/scripts/lint-skills: good and deliberately broken fixtures,
# plus the real plugin tree. Run: sh tests/lint-skills/run.sh
here=$(cd "$(dirname "$0")" && pwd)
lint="$here/../../learn-anything/scripts/lint-skills"
fails=0

# expect <name> <tree> <exit 0|1> [message substring]
expect() {
  out=$(sh "$lint" "$2" 2>&1); rc=$?
  if [ "$rc" -ne "$3" ]; then echo "FAIL $1: exit $rc, want $3"; echo "$out"; fails=$((fails + 1)); return; fi
  if [ -n "$4" ] && ! printf '%s\n' "$out" | grep -qF "$4"; then
    echo "FAIL $1: output lacks '$4'"; echo "$out"; fails=$((fails + 1)); return
  fi
  echo "ok   $1"
}

expect "clean fixture passes"            "$here/fixtures/good"         0 "lint-skills: ok"
expect "real plugin tree passes"         "$here/../../learn-anything"  0 "lint-skills: ok"
expect "SKILL.md over its cap fails"     "$here/fixtures/over-cap"     1 "cap 80"
expect "description over 250 fails"      "$here/fixtures/long-desc"    1 "max 250"
expect "missing prefix phrase fails"     "$here/fixtures/bad-prefix"   1 "must start"
expect "missing ending phrase fails"     "$here/fixtures/bad-ending"   1 "must end with"
expect "missing plugin-root path fails"  "$here/fixtures/missing-path" 1 "missing path \${CLAUDE_PLUGIN_ROOT}/shared/nope.md"
expect "hidden skill still invocable"    "$here/fixtures/not-hidden"   1 "user-invocable: false"

[ "$fails" -eq 0 ] && echo "all passed"
exit "$fails"
