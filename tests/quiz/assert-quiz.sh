#!/bin/sh
# assert-quiz.sh <lesson-dir> <plugin-dir>: seam-1 assertions for a one-unit quiz lesson.
# Asserts on files, counts and the verify-html result, never prose. Exit = number of failures.
d=${1:?usage: assert-quiz.sh <lesson-dir> <plugin-dir>}
plugin=${2:?usage: assert-quiz.sh <lesson-dir> <plugin-dir>}
fails=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fails=$((fails + 1)); }
p=$d/plan.md
unit() { sed -n '/^## u1$/,$p' "$p" | sed -n "s/^$1:[[:space:]]*//p" | head -n 1; }
status=$(unit status)

[ "$(unit mode)" = quiz ] && ok "unit mode quiz" || bad "unit mode quiz"
case $status in done|degraded*) ok "unit status settled ($status)";; *) bad "unit status settled ($status)";; esac
want=$(unit size | sed 's/[^0-9].*//')
[ "$want" = 9 ] && ok "plan size is budget x 1.8 items" || bad "plan size is 9 items ($(unit size))"

items=$d/lesson/u1-quiz.items.json
[ -f "$items" ] && ok "sidecar items file kept" || bad "sidecar items file kept"
n=$(grep -o '"id"' "$items" | wc -l | tr -d ' ')
lo=$((want * 85 / 100)); hi=$((want * 115 / 100 + 1))
[ "$n" -ge "$lo" ] && [ "$n" -le "$hi" ] && ok "$n items near $want" || bad "$n items outside $lo-$hi"
for c in SYN SYN-ACK ACK; do
  k=$(grep -o "\"concept\" *: *\"$c\"" "$items" | wc -l | tr -d ' ')
  [ "$k" -ge 2 ] && ok "concept $c has $k items" || bad "concept $c has $k items"
done
grep -q '"rung"' "$items" && ok "items carry rungs" || bad "items carry rungs"

if [ "$status" = done ]; then
  a=$d/lesson/u1-quiz.html
  [ -f "$a" ] && ok "quiz html exists" || bad "quiz html exists"
  sh "$plugin/scripts/verify-html" "$a" && ok "verify-html passes the built quiz" || bad "verify-html passes the built quiz"
  [ ! -e "$d/work/u1" ] && ok "work/u1 deleted on done" || bad "work/u1 deleted on done"
else
  grep -q '^## Answers' "$d/lesson/u1-quiz.md" 2>/dev/null && ok "degraded markdown with Answers" || bad "degraded markdown with Answers"
fi

[ "$fails" -eq 0 ] && echo "quiz: all passed"
exit "$fails"
