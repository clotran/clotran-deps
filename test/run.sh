#!/bin/sh
# test/run.sh -- clotran-deps against small projects it builds in a
# scratch directory: a local root, a pinned git sha (this machine's
# clotran-nrepl, over file://), dependencies of dependencies, a conflict,
# the project settling it, a refused Maven jar, and an alias. Prints each
# check; exits 1 if any fails.
D=$(cd "$(dirname "$0")/.." && pwd)/bin/clotran-deps
# the clotran to run on, fixed before HOME is changed for the git cache
export CLOTRAN="${CLOTRAN:-$HOME/jborden/clotran}"
T=$(mktemp -d) || exit 1
trap 'rm -rf "$T"' EXIT
fails=0
check() { if [ "$2" = "$3" ]; then echo "ok   - $1"; else echo "FAIL - $1"; echo "  got:  $2"; echo "  want: $3"; fails=$((fails+1)); fi; }
rel() { printf '%s\n' "$1" | tr ':' '\n' | sed "s|^$T/||" | tr '\n' ' '; }

mkdir -p "$T/a/src" "$T/b/src" "$T/c1/src" "$T/c2/src" "$T/p1" "$T/p2" "$T/p3" "$T/mvn" "$T/al" "$T/g/lib/src" "$T/gp"
echo '{:deps {c/c {:local/root "../c1"}}}' > "$T/a/deps.edn"
echo '{:deps {c/c {:local/root "../c2"}}}' > "$T/b/deps.edn"
echo '{}' > "$T/c1/deps.edn"; echo '{}' > "$T/c2/deps.edn"
echo '{:deps {org.clojure/clojure {:mvn/version "1.12.6"} a/a {:local/root "../a"}}}' > "$T/p1/deps.edn"
echo '{:deps {a/a {:local/root "../a"} b/b {:local/root "../b"}}}' > "$T/p2/deps.edn"
echo '{:deps {a/a {:local/root "../a"} b/b {:local/root "../b"} c/c {:local/root "../c2"}}}' > "$T/p3/deps.edn"
echo '{:deps {cheshire/cheshire {:mvn/version "5.12.0"}}}' > "$T/mvn/deps.edn"
echo '{:aliases {:dev {:extra-paths ["dev"]}}}' > "$T/al/deps.edn"

check "a local root, its own dependency, clojure provided" "$(rel "$($D "$T/p1")")" "p1/src a/src c1/src "
check "a conflict nobody settled is an error" "$($D "$T/p2" 2>&1 >/dev/null | sed "s|$T/||g")" \
  "clotran-deps: c/c is wanted at two places: c1 (by a) and c2 (by b)"
check "the project settles it" "$(rel "$($D "$T/p3")")" "p3/src a/src b/src c2/src "
check "a Maven jar is refused by name" "$($D "$T/mvn" 2>&1 >/dev/null)" \
  "clotran-deps: cheshire/cheshire is a Maven jar, which is JVM bytecode; give it a :git/url or :local/root"
$D "$T/mvn" >/dev/null 2>&1; check "and the status says so" "$?" "1"
check "an alias adds its paths" "$(rel "$($D -A:dev "$T/al")")" "al/src al/dev "

# a git dependency, pinned by sha, checked out once into the cache
( cd "$T/g/lib" && git init -q && echo '{}' > deps.edn && git add -A && git -c user.name=t -c user.email=t@t commit -q -m one )
sha=$(git -C "$T/g/lib" rev-parse HEAD)
echo "{:deps {t/lib {:git/url \"file://$T/g/lib\" :git/sha \"$sha\"}}}" > "$T/gp/deps.edn"
HOME="$T/home" check "a git sha is checked out into the cache" "$(HOME="$T/home" "$D" "$T/gp" | tr ':' '\n' | tail -1 | sed "s|^$T/||")" \
  "home/.cache/clotran/gitlibs/t/lib/$sha/src"
echo "{:deps {t/lib {:git/url \"file://$T/g/lib\" :git/sha \"abc\"}}}" > "$T/gp/deps.edn"
check "a short sha is refused" "$(HOME="$T/home" "$D" "$T/gp" 2>&1 >/dev/null)" "clotran-deps: t/lib needs a full 40-character :git/sha"

[ $fails -eq 0 ] && echo "CLOTRAN-DEPS TESTS PASSED" || { echo "CLOTRAN-DEPS TESTS FAILED: $fails"; exit 1; }
