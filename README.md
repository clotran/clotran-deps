# clotran-deps

The package manager for [clotran](https://github.com/clotran/clotran): it reads a project's
`deps.edn` -- the same file, with the same keys, a Clojure project has --
fetches what it names, and prints the source path clotran searches
(`CLOTRAN_PATH`), as tools.deps computes clj's classpath. clotran
itself knows only that path; everything here is a separate program, run
by clotran. The design is clotran's `PACKAGES.md`.

    clotran deps                 # fetch what deps.edn names
    clotran app.cljf

or by hand, in a POSIX shell (`clotran-deps.cmd` on Windows prints the same path):

    CLOTRAN_PATH=$(clotran-deps) clotran app.cljf
    clotran-deps -A:dev:test path/to/project

## What a deps.edn may name

| coordinate | here |
|---|---|
| `{:local/root "dir"}` | that directory, and its own `deps.edn` |
| `{:git/url "..." :git/sha "<40 hex>"}` | fetched once into the cache, `~/.clotran/cache/tree/<group>/<name>/<sha>` (`CLOTRAN_CACHE` moves the cache), and never changed: only that tree, no history -- from GitHub its archive of the sha (curl and tar; no git needed), else git fetching that one commit at depth 1; a short or missing sha is refused, and an optional `:git/tag` beside it must name that sha |
| `{:mvn/version "..."}` | `org.clojure/clojure`, `spec.alpha`, `core.specs.alpha` are PROVIDED -- clotran is the Clojure; any other jar is refused by name, being compiled for another host |

`:paths` (default `["src"]`), `:deps` and `:aliases` with `:extra-paths`
and `:extra-deps` mean what they mean in tools.deps. Dependencies are
walked breadth first; a library wanted at two different places is an
error naming both, unless the project's own `:deps` names it -- the
project always wins.

`clotran deps [-A:alias] [dir]` fetches what the project names and says
which libraries are ready; it is the one clotran command that downloads.
The others -- `clotran`, `clotran -m`, `clotran test`, the REPL -- run
this themselves in a directory with a `deps.edn` (a leading `-A:alias` is
passed on), so a project needs no `CLOTRAN_PATH` by hand, but refuse a
library not in the cache yet: `` <lib> is not fetched yet: `clotran deps`
fetches what deps.edn names ``. The answer is cached in `.clotran-cache/deps.edn` beside
the `deps.edn`, with a checksum of every `deps.edn` it read and each
library's directory (`:libs`, for a tool that wants to know where a
dependency's sources are), and reused while none has changed; add `.clotran-cache/` to a project's
`.gitignore`.

## Not yet

- native packages (a Fortran or C library with a build recipe)

## Install

A clotran release carries this: `bin/clotran-deps` (`clotran-deps.cmd`
on Windows) beside `clotran`, so an installed clotran needs nothing more.
From a checkout:

    make install                 # ~/.local: ~/.local/bin/clotran-deps
    make install PREFIX=/usr/local
    make uninstall

The same `PREFIX` layout as clotran's own `make install`, so the two sit
side by side and each finds the other. The clotran it runs on is
`CLOTRAN` if set, else a clotran beside it (a checkout, or the installed
one), else the `clotran` on PATH.

## Tests

    make test        # test/run.sh; CLOTRAN=<clotran> to choose which
