PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
SUDOERS := /etc/sudoers.d/x3dctl
SYSTEM_CONFIG := /etc/x3dctl.conf
PROJECT_CONFIG := etc/x3dctl.conf

CC = gcc
CFLAGS = -O2 -Wall -Wextra

all: x3dctl-helper
	@echo ""
	@echo "Build complete."
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "To install system-wide, run: sudo make install"; \
	fi
	@echo ""

x3dctl-helper: x3dctl-helper.c
	$(CC) $(CFLAGS) $< -o $@

install: x3dctl-helper
	# Requires: sudo make install for system paths
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "ERROR: Run 'sudo make install' for system installation."; \
		exit 1; \
	fi

	install -Dm755 x3dctl $(BINDIR)/x3dctl
	install -Dm755 x3dctl-helper $(BINDIR)/x3dctl-helper

	echo "$$SUDO_USER ALL=(root) NOPASSWD: $(BINDIR)/x3dctl-helper" > $(SUDOERS)
	chmod 440 $(SUDOERS)

	if [ ! -f $(SYSTEM_CONFIG) ]; then \
		echo "Installing default config to $(SYSTEM_CONFIG)"; \
		install -Dm644 $(PROJECT_CONFIG) $(SYSTEM_CONFIG); \
	else \
		echo "$(SYSTEM_CONFIG) already exists — leaving untouched"; \
	fi

	@echo "Install complete."

uninstall:
	rm -f $(BINDIR)/x3dctl
	rm -f $(BINDIR)/x3dctl-helper
	rm -f $(SUDOERS)

clean:
	rm -f x3dctl-helper

.PHONY: all install uninstall clean

