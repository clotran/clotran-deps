# clotran-deps: `make install` puts it beside clotran, in the same PREFIX
# layout clotran's own `make install` uses -- the program under
# PREFIX/lib/clotran-deps, and PREFIX/bin/clotran-deps running it -- so an
# installed clotran finds it on PATH. `make test` runs test/run.sh.
UNAME_S := $(shell uname -s)
ifneq ($(filter MINGW% MSYS% CYGWIN%,$(UNAME_S)),)
PREFIX ?= $(subst \,/,$(LOCALAPPDATA))/Programs/clotran
else
PREFIX ?= $(HOME)/.local
endif
LIBDIR = $(PREFIX)/lib/clotran-deps
BINDIR = $(PREFIX)/bin

.PHONY: install uninstall test

install:
	rm -rf "$(LIBDIR)"
	mkdir -p "$(LIBDIR)" "$(BINDIR)"
	cp -R bin src deps.edn "$(LIBDIR)/"
	printf '#!/bin/sh\n# clotran-deps, installed by make install\nexec "%s/bin/clotran-deps" "$$@"\n' "$(LIBDIR)" > "$(BINDIR)/clotran-deps"
	chmod +x "$(BINDIR)/clotran-deps"
	@echo "clotran-deps is installed: $(BINDIR)/clotran-deps"

uninstall:
	rm -rf "$(LIBDIR)" "$(BINDIR)/clotran-deps"

test:
	test/run.sh
