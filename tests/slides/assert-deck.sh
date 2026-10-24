#!/bin/sh
# assert-deck.sh <lesson-dir> [norender]: assertions for a slides unit (topic -> one Marp deck).
# Asserts on files, frontmatter and counts, never prose. With `norender`, marp and npx were hidden
# from PATH, so also asserts no render exists. Exit = number of failures.
d=${1:?usage: assert-deck.sh <lesson-dir> [norender]}
mode=$2
fails=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fails=$((fails + 1)); }
unit() { sed -n '/^## u1$/,$p' "$p" | sed -n "s/^$1:[[:space:]]*//p" | head -n 1; }

p=$d/plan.md
[ "$(grep -c '^## u' "$p")" -eq 1 ] && ok "plan has exactly one unit" || bad "plan has exactly one unit"
[ "$(unit mode)" = slides ] && ok "unit mode slides" || bad "unit mode slides"
[ "$(unit status)" = done ] && ok "unit status done" || bad "unit status done ($(unit status))"
case $(unit artifact) in *lesson/u1-slides.md) ok "artifact recorded in plan";; *) bad "artifact recorded in plan ($(unit artifact))";; esac
want=$(unit size | sed 's/[^0-9].*//')
[ "$(unit size)" = "$want slides" ] && [ "$want" -ge 3 ] && ok "plan size is $want slides" || bad "plan size is N slides ($(unit size))"
if [ "$mode" = norender ]; then
  [ "$(unit predicted)" = unrendered ] && ok "plan predicted: unrendered" || bad "plan predicted: unrendered ($(unit predicted))"
fi

a=$d/lesson/u1-slides.md
[ -f "$a" ] && ok "deck exists" || { bad "deck exists"; exit "$fails"; }
sed -n 1,5p "$a" | grep -q '^marp: true' && ok "deck has marp: true" || bad "deck has marp: true"
n=$(($(grep -c '^---$' "$a") - 1))
[ "$n" -eq "$want" ] && ok "deck has exactly $want slides" || bad "deck has $n slides, want $want"
grep -q '<!--' "$a" && ok "deck has speaker notes" || bad "deck has speaker notes"
tail -n 12 "$a" | grep -qi '^#.*takeaways' && ok "last slide is Takeaways" || bad "last slide is Takeaways"

# every slide: heading plus at most 7 visible lines (about 5 short lines, with slack), comments excluded;
# a fenced figure counts as one line
over=$(awk '
  BEGIN { fm = 0; n = 0 }
  /^---$/ { if (fm < 2) { fm++; next } if (n > 7) print "slide " s " has " n " lines"; s++; n = 0; incomment = 0; next }
  fm < 2 { next }
  { line = $0
    # a fenced figure (mermaid, math) counts as one line
    if (line ~ /^```/) { if (!infence) n++; infence = !infence; next }
    if (infence) next
    if (incomment) { if (line ~ /-->/) incomment = 0; next }
    if (line ~ /<!--/) { if (line !~ /-->/) incomment = 1; next }
    if (line ~ /[^ \t]/) n++ }
  BEGIN { s = 1 }
  END { if (n > 7) print "slide " s " has " n " lines" }' "$a")
[ -z "$over" ] && ok "every slide within the line limit" || bad "slide over limit: $over"

if [ "$mode" = norender ]; then
  ls "$d"/lesson/u1-slides.html "$d"/lesson/u1-slides.pdf >/dev/null 2>&1 && bad "no render expected" || ok "no render written"
else
  [ -s "$d/lesson/u1-slides.html" ] && ok "html rendered" || bad "html rendered"
fi
[ ! -e "$d/work/u1" ] && ok "work/u1 deleted on done" || bad "work/u1 deleted on done"

[ "$fails" -eq 0 ] && echo "slides: all passed"
exit "$fails"
