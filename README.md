# clotran-deps

The package manager for [clotran](../clotran): it reads a project's
`deps.edn` -- the same file, with the same keys, a Clojure project has --
fetches what it names, and prints the source path clotran searches
(`CLOTRAN_PATH`), as tools.deps computes clj's classpath. clotran
itself knows only that path; everything here is a separate program, run
by clotran. The design is clotran's `PACKAGES.md`.

    CLOTRAN_PATH=$(clotran-deps) clotran app.cljf
    clotran-deps -A:dev:test path/to/project

## What a deps.edn may name

| coordinate | here |
|---|---|
| `{:local/root "dir"}` | that directory, and its own `deps.edn` |
| `{:git/url "..." :git/sha "<40 hex>"}` | checked out once into `~/.cache/clotran/gitlibs/<lib>/<sha>` and never changed; a short or missing sha is refused |
| `{:mvn/version "..."}` | `org.clojure/clojure`, `spec.alpha`, `core.specs.alpha` are PROVIDED -- clotran is the Clojure; any other jar is refused by name, being compiled for another host |

`:paths` (default `["src"]`), `:deps` and `:aliases` with `:extra-paths`
and `:extra-deps` mean what they mean in tools.deps. Dependencies are
walked breadth first; a library wanted at two different places is an
error naming both, unless the project's own `:deps` names it -- the
project always wins.

The `clotran` launcher runs this itself in a directory with a
`deps.edn` (a leading `-A:alias` is passed on), so a project needs no
`CLOTRAN_PATH` by hand. The answer is cached in `.clotran-cache/` beside
the `deps.edn`, with a checksum of every `deps.edn` it read, and reused
while none has changed; add `.clotran-cache/` to a project's
`.gitignore`.

## Not yet

- `:git/tag` checked against `:git/sha`
- native packages (a Fortran or C library with a build recipe)
- `-main` and `*command-line-args*` in clotran (its PLAN step 22), which
  will replace the one-line driver `bin/clotran-deps` writes

## Install

    make install                 # ~/.local: ~/.local/bin/clotran-deps
    make install PREFIX=/usr/local
    make uninstall

The same `PREFIX` layout as clotran's own `make install`, so the two sit
side by side and each finds the other. The clotran it runs on is
`CLOTRAN` if set, else a clotran beside it (a checkout, or the installed
one), else the `clotran` on PATH.

## Tests

    make test        # test/run.sh; CLOTRAN=<clotran> to choose which
