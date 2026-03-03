PREFIX ?= /usr/local
DESTDIR ?=

BINDIR := $(PREFIX)/bin
MANDIR := $(PREFIX)/share/man/man1

SUDOERS := /etc/sudoers.d/x3dctl
SYSTEM_CONFIG := /etc/x3dctl.conf
PROJECT_CONFIG := etc/x3dctl.conf

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

	@echo "Installing sudoers policy..."
	@install -Dm440 packaging/x3dctl.sudoers $(DESTDIR)$(SUDOERS)

	@# Only install default config during real system install
	@if [ -z "$(DESTDIR)" ]; then \
		if [ ! -f $(SYSTEM_CONFIG) ]; then \
			echo "Installing default config to $(SYSTEM_CONFIG)"; \
			install -Dm644 $(PROJECT_CONFIG) $(SYSTEM_CONFIG); \
		else \
			echo "$(SYSTEM_CONFIG) already exists — leaving untouched"; \
		fi \
	fi

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
	@rm -f $(DESTDIR)$(SUDOERS)
	@echo "Uninstall complete. Configuration file left intact."

clean:
	@rm -f x3dctl-helper

.PHONY: all install uninstall clean
