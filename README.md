# clotran-deps

The package manager for [clotran](../clotran): it reads a project's
`deps.edn` -- the same file, with the same keys, a Clojure project has --
fetches what it names, and prints the source path clotran searches
(`CLOTRAN_PATH`), as tools.deps computes the JVM's classpath. clotran
itself knows only that path; everything here is a separate program, run
by clotran. The design is clotran's `PACKAGES.md`.

    CLOTRAN_PATH=$(clotran-deps) clotran app.cljf
    clotran-deps -A:dev:test path/to/project

## What a deps.edn may name

| coordinate | here |
|---|---|
| `{:local/root "dir"}` | that directory, and its own `deps.edn` |
| `{:git/url "..." :git/sha "<40 hex>"}` | checked out once into `~/.cache/clotran/gitlibs/<lib>/<sha>` and never changed; a short or missing sha is refused |
| `{:mvn/version "..."}` | `org.clojure/clojure`, `spec.alpha`, `core.specs.alpha` are PROVIDED -- clotran is the Clojure; any other jar is refused by name, being JVM bytecode |

`:paths` (default `["src"]`), `:deps` and `:aliases` with `:extra-paths`
and `:extra-deps` mean what they mean in tools.deps. Dependencies are
walked breadth first; a library wanted at two different places is an
error naming both, unless the project's own `:deps` names it -- the
project always wins.

## Not yet

- caching the resolved path (`.clotran-cache/path`, keyed by a hash of
  every `deps.edn` read), and the `clotran` launcher calling this itself
  in a directory with a `deps.edn`
- `:git/tag` checked against `:git/sha`
- native packages (a Fortran or C library with a build recipe)
- `-main` and `*command-line-args*` in clotran (its PLAN step 22), which
  will replace the one-line driver `bin/clotran-deps` writes

## Tests

    test/run.sh      # CLOTRAN=<clotran checkout>, default ~/jborden/clotran
