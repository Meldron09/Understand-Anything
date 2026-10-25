#!/bin/sh
# assert-check.sh <lesson-dir> <miss|decline>: seam-1 assertions for the comprehension check.
# Asserts on files, frontmatter and counts, never prose. Exit = number of failures.
d=${1:?usage: assert-check.sh <lesson-dir> <miss|decline>}
scen=${2:?usage: assert-check.sh <lesson-dir> <miss|decline>}
fails=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fails=$((fails + 1)); }
c=$d/check.md
key() { sed -n '2,/^---$/p' "$c" | sed '$d' | sed -n "s/^$1:[[:space:]]*//p" | head -n 1; }
qs() { grep -hoE '"(q|alt)" *: *"([^"\\]|\\.)*"' "$@" | sed 's/" *: *"/":"/' | sort -u; }

[ -f "$c" ] && ok "check.md exists at the stable path" || { bad "check.md exists"; exit 1; }
[ "$(grep -c '^## u' "$d/plan.md")" -eq 1 ] && ok "check is not a plan unit" || bad "plan has exactly one unit"
grep -q '^mode: check' "$d/plan.md" && bad "plan never lists the check" || ok "plan never lists the check"
grep -qE '[0-9]+ *(/|of|out of) *[0-9]+|[0-9]+ *%' "$c" && bad "check.md has no numeric score" || ok "check.md has no numeric score"

if [ "$scen" = decline ]; then
  [ "$(key declined)" = true ] && ok "declined: true" || bad "declined: true"
  [ ! -e "$d/reexplain.md" ] && ok "no reexplain.md" || bad "no reexplain.md"
  [ "$fails" -eq 0 ] && echo "check: all passed"
  exit "$fails"
fi

[ "$(key declined)" = false ] && ok "declined: false" || bad "declined: false"
[ "$(key items)" = 2 ] && ok "gist depth gives 2 items" || bad "gist depth gives 2 items ($(key items))"
items=$d/work/check/items.json
[ -f "$items" ] && ok "work/check/items.json written" || bad "work/check/items.json written"
[ "$(grep -o '"rubric"' "$items" | wc -l | tr -d ' ')" -eq 2 ] && ok "each item has a rubric" || bad "each item has a rubric"
[ "$(grep -o '"alt"' "$items" | wc -l | tr -d ' ')" -eq 2 ] && ok "each item has an alt" || bad "each item has an alt"
grep -qE '"type" *: *"(mcq|flip|explain)"' "$items" && bad "check items are short only at gist" || ok "check items are short only at gist"
tmpq=$(mktemp)
qs "$d"/lesson/*-quiz.items.json > "$tmpq"
dups=$(qs "$items" | grep -Fxf "$tmpq"); rm -f "$tmpq"
[ -z "$dups" ] && ok "no check item repeats a quiz question" || bad "check repeats a quiz question: $dups"
grep -q '^## Gap list' "$c" && ok "has Gap list" || bad "has Gap list"
grep -q '| missed |' "$c" && ok "a missed concept is reported" || bad "a missed concept is reported"
grep -q '| missed | core |' "$c" && ok "missed core concept flagged" || bad "missed core concept flagged"
[ "$(key reexplained)" = true ] && ok "reexplained: true" || bad "reexplained: true"
[ -f "$d/reexplain.md" ] && ok "reexplain.md exists" || bad "reexplain.md exists"
grep -qi 'study' "$c" && ok "still-missed names what to study" || bad "still-missed names what to study"
[ "$fails" -eq 0 ] && echo "check: all passed"
exit "$fails"
