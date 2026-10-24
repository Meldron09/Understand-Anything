#!/bin/sh
# assert-interactive.sh <lesson-dir> <plugin-dir>: seam-1 assertions for a one-unit interactive lesson.
# Asserts on files, counts and the verify-html result, never prose. Exit = number of failures.
d=${1:?usage: assert-interactive.sh <lesson-dir> <plugin-dir>}
plugin=${2:?usage: assert-interactive.sh <lesson-dir> <plugin-dir>}
fails=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fails=$((fails + 1)); }
p=$d/plan.md
unit() { sed -n '/^## u1$/,$p' "$p" | sed -n "s/^$1:[[:space:]]*//p" | head -n 1; }
status=$(unit status)
a=$d/lesson/u1-interactive.html

[ "$(unit mode)" = interactive ] && ok "unit mode interactive" || bad "unit mode interactive"
case $status in done|degraded*|failed*) ok "unit status settled ($status)";; *) bad "unit status settled ($status)";; esac
want=$(unit size | sed 's/[^0-9].*//')
[ "$want" = 3 ] && ok "plan size is 3 widgets" || bad "plan size is 3 widgets ($(unit size))"

if [ "$status" = done ]; then
  [ -f "$a" ] && ok "interactive html exists" || bad "interactive html exists"
  sh "$plugin/scripts/verify-html" "$a" && ok "verify-html passes the built page" || bad "verify-html passes the built page"
  n=$(grep -o 'class="widget"' "$a" | wc -l | tr -d ' ')
  [ "$n" -ge 3 ] && [ "$n" -le 5 ] && ok "$n widgets (3 core concepts, max 5)" || bad "$n widgets outside 3-5"
  for c in SYN SYN-ACK ACK; do
    grep -q "<h2>[^<]*$c" "$a" && ok "widget for $c" || bad "widget for $c"
  done
  grep -q 'Sources:' "$a" && ok "chunk-id footer in page" || bad "chunk-id footer in page"
  [ ! -e "$d/work/u1" ] && ok "work/u1 deleted on done" || bad "work/u1 deleted on done"
else
  [ ! -e "$a" ] && ok "no partial html left" || bad "no partial html left"
fi

[ "$fails" -eq 0 ] && echo "interactive: all passed"
exit "$fails"
