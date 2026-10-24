#!/bin/sh
# assert-level.sh <lesson-dir>: level-shaping assertions on a brief with `## Level evidence`.
# Every core concept has its own `##` section; sections for concepts a shaky/missed rung touches
# are longer than those only solid rungs touch. Asserts on counts, never prose. Exit = failures.
d=${1:?usage: assert-level.sh <lesson-dir>}
b=$d/brief.md; a=$d/lesson/u1-text.md
fails=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fails=$((fails + 1)); }
core=$(sed -n 's/^core:[[:space:]]*\[\(.*\)\].*/\1/p' "$b" | tr ',' '\n' | sed 's/^ *//;s/ *$//')
ev=$(sed -n '/^## Level evidence/,$p' "$b" | grep '|')
# words in the section whose heading starts with the concept (case-insensitive, whole token)
words() { awk -v c="$(echo "$1" | tr 'A-Z' 'a-z')" '
  /^## / { on = 0; h = tolower(substr($0, 4)); n = length(c)
           if (substr(h, 1, n) == c && substr(h, n + 1, 1) !~ /[a-z-]/) on = 1 }
  on { w += NF } END { print w + 0 }' "$a"; }
# grades of evidence lines naming the concept as a whole token (SYN is not SYN-ACK)
grade() { echo "$ev" | awk -F'|' -v c="$1" '
  { q = " " $2 " "; while ((i = index(q, c)) > 0) {
      pre = substr(q, i - 1, 1); post = substr(q, i + length(c), 1)
      if (pre !~ /[A-Za-z-]/ && post !~ /[A-Za-z-]/) { g = $3; gsub(/ /, "", g); print g; break }
      q = substr(q, i + 1) } }' | sort -u | tr '\n' ' '; }
hi=0; lo=999999; solid_n=0; weak_n=0
IFS='
'
for c in $core; do
  w=$(words "$c")
  [ "$w" -gt 0 ] && ok "core '$c' has its own section ($w words)" || bad "core '$c' has its own section"
  case $(grade "$c") in
    *missed*|*shaky*) weak_n=$((weak_n + 1)); [ "$w" -lt "$lo" ] && lo=$w ;;
    *solid*) solid_n=$((solid_n + 1)); [ "$w" -gt "$hi" ] && hi=$w ;;
  esac
done
[ "$weak_n" -gt 0 ] && [ "$solid_n" -gt 0 ] && ok "fixture has solid and shaky/missed concepts" || bad "fixture has solid and shaky/missed concepts"
[ "$lo" -gt "$hi" ] && ok "shaky/missed sections ($lo words min) longer than solid ($hi max)" \
  || bad "shaky/missed sections ($lo words min) longer than solid ($hi max)"
[ "$fails" -eq 0 ] && echo "level: all passed"
exit "$fails"
