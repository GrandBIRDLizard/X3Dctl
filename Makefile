
PREFIX ?= /usr/local
DESTDIR ?=

BINDIR := $(PREFIX)/bin
MANDIR := $(PREFIX)/share/man/man1

CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -Werror -std=gnu11

all: x3dctl-helper

x3dctl-helper: x3dctl-helper.c
	$(CC) $(CFLAGS) $< -o $@

install: x3dctl-helper
	@echo "Installing binaries..."
	install -Dm755 x3dctl $(DESTDIR)$(BINDIR)/x3dctl
	install -Dm755 x3dctl-helper $(DESTDIR)$(BINDIR)/x3dctl-helper

	@echo "Installing man page..."
	install -Dm644 man/x3dctl.1 $(DESTDIR)$(MANDIR)/x3dctl.1

	@echo "Installing sudoers file..."
	install -dm750 $(DESTDIR)/etc/sudoers.d
	sed 's|@BINDIR@|$(BINDIR)|g' packaging/x3dctl.sudoers.in | \
	install -Dm440 /dev/stdin $(DESTDIR)/etc/sudoers.d/x3dctl

	@echo "Install complete."


uninstall:
	@if [ -z "$(DESTDIR)" ] && [ "$$(id -u)" -ne 0 ]; then \
		echo "ERROR: Run 'sudo make uninstall' for system removal."; \
		exit 1; \
	fi

	@echo "Removing installed files..."
	rm -f $(DESTDIR)$(BINDIR)/x3dctl
	rm -f $(DESTDIR)$(BINDIR)/x3dctl-helper
	rm -f $(DESTDIR)$(MANDIR)/x3dctl.1

	@echo "Uninstall complete."

clean:
	.PHONY: all install uninstall clean

.PHONY: all install uninstall clean
