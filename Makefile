PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
SUDOERS := /etc/sudoers.d/x3dctl

CC = gcc
CFLAGS = -O2 -Wall -Wextra

all: x3dctl-helper

x3dctl-helper: x3dctl-helper.c
	$(CC) $(CFLAGS) $< -o $@

install: x3dctl-helper
	# Install binaries (requires root if PREFIX is system path)
	install -Dm755 x3dctl $(DESTDIR)$(BINDIR)/x3dctl
	install -Dm755 x3dctl-helper $(DESTDIR)$(BINDIR)/x3dctl-helper

	# Only install sudoers rule for real system installs
	# (Skip when DESTDIR is set for packaging)
	@if [ -z "$(DESTDIR)" ]; then \
		if [ -z "$$SUDO_USER" ]; then \
			echo "ERROR: Run 'sudo make install' for system installation."; \
			exit 1; \
		fi; \
		echo "Installing sudoers rule for user: $$SUDO_USER"; \
		echo "$$SUDO_USER ALL=(root) NOPASSWD: $(BINDIR)/x3dctl-helper" > $(SUDOERS); \
		chmod 440 $(SUDOERS); \
	fi

	@echo "Ensure /etc/x3dctl.conf exists (create manually if needed)."

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/x3dctl
	rm -f $(DESTDIR)$(BINDIR)/x3dctl-helper

	# Remove sudoers rule only for real system installs
	@if [ -z "$(DESTDIR)" ]; then \
		rm -f $(SUDOERS); \
	fi

clean:
	rm -f x3dctl-helper

.PHONY: all install uninstall clean

