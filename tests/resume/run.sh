#!/bin/sh
# Seam-1 tests for learn-anything/scripts/resume-check on lesson folders built on disk: finished units
# are never re-run, a pending unit re-runs from a cleared work dir, a changed brief or source hash
# archives the plan and lesson as numbered copies, a moved local source is failed. Files-on-disk only.
# Run: sh tests/resume/run.sh
here=$(cd "$(dirname "$0")" && pwd)
rc=$here/../../learn-anything/scripts/resume-check
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fails=0
t() { desc=$1; shift; if "$@"; then echo "ok   $desc"; else echo "FAIL $desc"; fails=$((fails + 1)); fi; }
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
last() { printf '%s\n' "$1" | tail -n 1; }
has() { printf '%s\n' "$1" | grep -q -- "$2"; }
key() { sed -n '2,/^---$/p' "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -n 1; }

# mk <name>: cd into a scratch cwd holding lesson lsn with a local-file source s1 and a topic source s2;
# plan u1 done, u2 pending, u3 degraded, u4 pending (slices s1). `inputs` holds the real hashes.
mk() {
  mkdir -p "$tmp/$1/notes" "$tmp/$1/learn-anything/lsn/sources/s1" "$tmp/$1/learn-anything/lsn/sources/s2" \
    "$tmp/$1/learn-anything/lsn/lesson" "$tmp/$1/learn-anything/lsn/work/u2" "$tmp/$1/learn-anything/lsn/work/u4"
  cd "$tmp/$1" || exit 1
  d=./learn-anything/lsn
  printf '# Notes\ntext\n' > notes/a.md
  printf -- '---\nlesson: lsn\nsources: [./notes/a.md, topic]\n---\n' > $d/brief.md
  printf -- '---\nkind: file\norigin: ./notes/a.md\nhash: sha256:%s\nstatus: ok\n---\nc01 | A | x | 4\nsummary\n' "$(sha notes/a.md)" > $d/sources/s1/index.md
  printf -- '---\nkind: topic\norigin: t\nhash: sha256:00\nstatus: ok\n---\nc01 | T | gk | 0\nsummary\n' > $d/sources/s2/index.md
  printf -- '---\nlesson: lsn\ninputs: {brief: sha256:%s, s1: sha256:%s, s2: sha256:%s}\n---\n' \
    "$(sha $d/brief.md)" "$(sha $d/sources/s1/index.md)" "$(sha $d/sources/s2/index.md)" > $d/plan.md
  printf '## u1\nmode: text\nslices: [s2#c01]\nstatus: done\n\n## u2\nmode: text\nslices: [s2#c01]\nstatus: pending\n\n' >> $d/plan.md
  printf '## u3\nmode: text\nslices: [s2#c01]\nstatus: degraded: short\n\n## u4\nmode: text\nslices: [s1#c01]\nstatus: pending\n' >> $d/plan.md
  echo "text u1" > $d/lesson/u1-text.md; echo "text u3" > $d/lesson/u3-text.md
  echo junk > $d/work/u2/partial.md; echo junk > $d/work/u4/x
}

# unchanged inputs: only pending units run; finished ones and their artifacts are untouched
mk a; before=$(cat $d/plan.md $d/lesson/*)
o=$(sh "$rc" $d)
t "unchanged: resume lists exactly the pending units" test "$(last "$o")" = "resume: units u2 u4"
t "unchanged: nothing archived" test ! -e $d/plan.1.md
t "unchanged: plan and finished artifacts byte-identical" test "$before" = "$(cat $d/plan.md $d/lesson/*)"
t "unchanged: done and degraded units stay as written" sh -c "grep -q '^status: done' $d/plan.md && grep -q '^status: degraded: short' $d/plan.md"
t "unchanged: pending units' work dirs cleared" test ! -e $d/work/u2 -a ! -e $d/work/u4
sed -i.bak 's/^status: pending/status: done/' $d/plan.md; rm $d/plan.md.bak
t "all units finished: resume says done" test "$(last "$(sh "$rc" $d)")" = "resume: done"

# changed brief archives plan and lesson as numbered copies; nothing carried over
mk b; echo "depth: mastery" >> $d/brief.md
o=$(sh "$rc" $d)
t "brief change: plan archived as plan.1.md" test -f $d/plan.1.md
t "brief change: lesson archived as lesson.1/ with its artifact" test -f $d/lesson.1/u1-text.md
t "brief change: no live plan, lesson or work" test ! -e $d/plan.md -a ! -e $d/lesson -a ! -e $d/work
t "brief change: report names the input" has "$o" '^archived: plan.1.md lesson.1 (changed: brief)'
t "brief change: next step is the router" test "$(last "$o")" = "resume: router"
t "brief change: archived plan keeps its old hashes" grep -q '^inputs:' $d/plan.1.md
printf -- '---\nlesson: lsn\ninputs: {brief: sha256:x}\n---\n## u1\nstatus: done\n' > $d/plan.md; mkdir $d/lesson; echo new > $d/lesson/u1-text.md
sh "$rc" $d > /dev/null
t "second change: numbered copies never overwrite" test -f $d/plan.2.md -a -f $d/lesson.2/u1-text.md -a -f $d/plan.1.md -a -f $d/lesson.1/u1-text.md

# an edited source index archives too, naming the source
mk c; echo "edited" >> $d/sources/s2/index.md
o=$(sh "$rc" $d)
t "index edit: archived, names s2 only" has "$o" '^archived: plan.1.md lesson.1 (changed: s2)'
t "index edit: lesson.1/ holds the old artifacts" test -f $d/lesson.1/u3-text.md

# a local file edited since ingest: re-ingest and archive
mk e; echo "more" >> notes/a.md
o=$(sh "$rc" $d)
t "source file edited: re-ingest requested" has "$o" '^reingest: s1'
t "source file edited: old index removed, plan archived" test ! -e $d/sources/s1 -a -f $d/plan.1.md
t "source file edited: next step is ingest of s1" test "$(last "$o")" = "resume: ingest s1"

# a moved local source: failed and listed; plan stays, its pending units fail, others still run
mk m; rm notes/a.md
o=$(sh "$rc" $d)
t "moved source: listed with its path" has "$o" '^moved: s1 ./notes/a.md'
t "moved source: index status failed" test "$(key $d/sources/s1/index.md status)" = failed
t "moved source: plan not archived, inputs follow the new index" sh -c "test -f $d/plan.md && test ! -e $d/plan.1.md && grep -q 's1: sha256:$(sha $d/sources/s1/index.md)' $d/plan.md"
t "moved source: pending unit slicing it failed" sh -c "sed -n '/^## u4/,\$p' $d/plan.md | grep -q '^status: failed: source s1 moved'"
t "moved source: other pending unit still runs" test "$(last "$o")" = "resume: units u2"
t "moved source: a second resume does not re-report it" sh -c "! sh '$rc' $d | grep -q '^moved'"

# first missing artifact
mk n; rm $d/plan.md $d/sources/s2/index.md
t "no plan, s2 index missing: ingest s2" test "$(last "$(sh "$rc" $d)")" = "resume: ingest s2"
rm $d/brief.md
t "no brief: intake" test "$(last "$(sh "$rc" $d)")" = "resume: intake"

# argument classification and the unfinished list
mk l; mkdir -p learn-anything/done-one
printf -- '---\nlesson: d\n---\n' > learn-anything/done-one/brief.md
printf -- '---\nlesson: d\n---\n## u1\nstatus: done\n' > learn-anything/done-one/plan.md
printf -- 'declined: true\n' > learn-anything/done-one/check.md
mkdir -p learn-anything/no-check; cp learn-anything/done-one/brief.md learn-anything/done-one/plan.md learn-anything/no-check/
t "exact folder name matches" sh "$rc" match lsn
t "a topic is not a folder" sh -c "! sh '$rc' match 'eigenvalues'"
t "a path is not a folder name" sh -c "! sh '$rc' match ./learn-anything/lsn && ! sh '$rc' match learn-anything/lsn && ! sh '$rc' match .."
t "no argument does not match" sh -c "! sh '$rc' match ''"
o=$(sh "$rc" list)
t "list shows the unfinished lesson with counts" has "$o" '^lsn | 2 of 4 units pending'
t "list omits the finished lesson" sh -c "! sh '$rc' list | grep -q done-one"
t "list shows an all-done lesson whose check.md is missing" has "$o" '^no-check | check pending'

[ "$fails" -eq 0 ] && echo "all passed"
exit "$fails"
