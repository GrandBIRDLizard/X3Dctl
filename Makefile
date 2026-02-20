PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
SUDOERS := /etc/sudoers.d/x3dctl
SYSTEM_CONFIG := /etc/x3dctl.conf
PROJECT_CONFIG := etc/x3dctl.conf

CC = gcc
CFLAGS = -O2 -Wall -Wextra -Werror -std=gnu11 -D_GNU_SOURCE

all: x3dctl-helper

x3dctl-helper: x3dctl-helper.c
	$(CC) $(CFLAGS) $< -o $@

install: x3dctl-helper
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "ERROR: Run 'sudo make install' for system installation."; \
		exit 1; \
	fi

	@install -Dm755 x3dctl $(BINDIR)/x3dctl
	@install -Dm755 x3dctl-helper $(BINDIR)/x3dctl-helper

	# Install sudoers rule
	@if [ -n "$$SUDO_USER" ]; then \
		echo "Installing sudoers rule for user: $$SUDO_USER"; \
		echo "$$SUDO_USER ALL=(root) NOPASSWD: $(BINDIR)/x3dctl-helper" > $(SUDOERS); \
	else \
		echo "Installed as root directly; granting access to %wheel group"; \
		echo "%wheel ALL=(root) NOPASSWD: $(BINDIR)/x3dctl-helper" > $(SUDOERS); \
	fi
	@chmod 440 $(SUDOERS)

	# Install default config only if missing
	@if [ ! -f $(SYSTEM_CONFIG) ]; then \
		echo "Installing default config to $(SYSTEM_CONFIG)"; \
		install -Dm644 $(PROJECT_CONFIG) $(SYSTEM_CONFIG); \
	else \
		echo "$(SYSTEM_CONFIG) already exists — leaving untouched"; \
	fi

	@echo "Install complete."

uninstall:
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "ERROR: Run 'sudo make uninstall' for system removal."; \
		exit 1; \
	fi

	@rm -f $(BINDIR)/x3dctl
	@rm -f $(BINDIR)/x3dctl-helper
	@rm -f $(SUDOERS)

	@echo "Uninstall complete. Configuration file left intact."

clean:
	@rm -f x3dctl-helper

.PHONY: all install uninstall clean

