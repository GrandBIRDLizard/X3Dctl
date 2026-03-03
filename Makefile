PREFIX ?= /usr/local
DESTDIR ?=

BINDIR := $(PREFIX)/bin
MANDIR := $(PREFIX)/share/man/man1

CC = gcc
CFLAGS = -O2 -Wall -Wextra -Werror -std=gnu11 -D_GNU_SOURCE

all: x3dctl-helper

x3dctl-helper: x3dctl-helper.c
	$(CC) $(CFLAGS) $< -o $@
	@echo -e "Local build complete.\nFor system install, run 'sudo make install'."

install: x3dctl-helper
	@echo "Installing binaries..."
	@install -Dm755 x3dctl $(DESTDIR)$(BINDIR)/x3dctl
	@install -Dm755 x3dctl-helper $(DESTDIR)$(BINDIR)/x3dctl-helper

	@echo "Installing man page..."
	@install -Dm644 man/x3dctl.1 $(DESTDIR)$(MANDIR)/x3dctl.1

	@echo "Install complete."

uninstall:
	@if [ -z "$(DESTDIR)" ] && [ "$$(id -u)" -ne 0 ]; then \
		echo "ERROR: Run 'sudo make uninstall' for system removal."; \
		exit 1; \
	fi

	@echo "Removing installed files..."
	@rm -f $(DESTDIR)$(BINDIR)/x3dctl
	@rm -f $(DESTDIR)$(BINDIR)/x3dctl-helper
	@rm -f $(DESTDIR)$(MANDIR)/x3dctl.1
	@echo "Uninstall complete."

clean:
	@rm -f x3dctl-helper

.PHONY: all install uninstall clean
