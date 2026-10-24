#!/bin/sh
# assert-lesson.sh <lesson-dir>: seam-1 assertions for the tracer (topic -> one text unit).
# Asserts on files, frontmatter and counts, never prose. Exit = number of failures.
d=${1:?usage: assert-lesson.sh <lesson-dir>}
fails=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fails=$((fails + 1)); }
fm() { sed -n '2,/^---$/p' "$1" | sed '$d'; }          # frontmatter of a file
key() { fm "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -n 1; }
unit() { sed -n '/^## u1$/,$p' "$p" | sed -n "s/^$1:[[:space:]]*//p" | head -n 1; }

# brief
b=$d/brief.md
[ -f "$b" ] && ok "brief.md exists" || bad "brief.md exists"
for k in lesson goal sources level depth budget modes core assumed; do
  [ -n "$(fm "$b" | grep "^$k:")" ] && ok "brief has $k" || bad "brief has $k"
done

# topic source
s=$d/sources/s1/index.md
[ -f "$s" ] && ok "s1 index exists" || bad "s1 index exists"
[ "$(key "$s" kind)" = topic ] && ok "s1 kind topic" || bad "s1 kind topic"
[ "$(key "$s" grounded)" = false ] && ok "s1 grounded false" || bad "s1 grounded false"
[ "$(grep -c '^c[0-9][0-9] |' "$s")" -eq 1 ] && ok "s1 has one chunk entry" || bad "s1 has one chunk entry"

# plan
p=$d/plan.md
[ -f "$p" ] && ok "plan.md exists" || bad "plan.md exists"
[ "$(grep -c '^## u' "$p")" -eq 1 ] && ok "plan has exactly one unit" || bad "plan has exactly one unit"
grep -q '^inputs:.*brief: sha256:' "$p" && ok "plan has inputs hashes" || bad "plan has inputs hashes"
[ "$(unit mode)" = text ] && ok "unit mode text" || bad "unit mode text"
[ "$(unit status)" = done ] && ok "unit status done" || bad "unit status done ($(unit status))"
case $(unit artifact) in *lesson/u1-text.md) ok "artifact recorded in plan";; *) bad "artifact recorded in plan ($(unit artifact))";; esac

# size follows the router rate: budget x 0.9 x 200 words, within 15%
budget=$(key "$b" budget | sed 's/[^0-9].*//')
want=$((budget * 180))
[ "$(unit size)" = "$want words" ] && ok "plan size is budget x 180 words" || bad "plan size is $want words ($(unit size))"

# artifact
a=$d/lesson/u1-text.md
[ -f "$a" ] && ok "artifact exists" || bad "artifact exists"
sed -n '/^## Takeaways/,$p' "$a" | grep -q '^[-*0-9]' && ok "artifact has Takeaways list" || bad "artifact has Takeaways list"
sed -n 1,6p "$a" | grep -qi '^[*_].*not grounded' && ok "artifact has ungrounded line" || bad "artifact has ungrounded line"
words=$(wc -w < "$a" | tr -d ' ')
lo=$((want * 85 / 100)); hi=$((want * 115 / 100))
[ "$words" -ge "$lo" ] && [ "$words" -le "$hi" ] && ok "artifact $words words within 15% of $want" || bad "artifact $words words outside $lo-$hi"

# cleanup on done
[ ! -e "$d/work/u1" ] && ok "work/u1 deleted on done" || bad "work/u1 deleted on done"

[ "$fails" -eq 0 ] && echo "tracer: all passed"
exit "$fails"
