PREFIX ?= /usr/local
DESTDIR ?=

BINDIR := $(PREFIX)/bin
MANDIR := $(PREFIX)/share/man/man1
SYSTEM_CONFIG := /etc/x3dctl.conf
PROJECT_CONFIG := etc/x3dctl.conf

CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -Werror -std=gnu11 -pedantic
CPPFLAGS ?= -Iinclude
LDFLAGS ?=
LDLIBS ?= -lcap

HELPER_SRCS = \
	src/x3dctl-helper.c \
	src/x3dctl-topology.c \
	src/x3dctl-x3d.c \
	src/x3dctl-irq.c \
	src/x3dctl-config.c \
	src/x3dctl-policy.c \
	src/x3dctl-status.c

HELPER_OBJS = $(HELPER_SRCS:.c=.o)

all: x3dctl-helper

x3dctl-helper: $(HELPER_OBJS)
	$(CC) $(CFLAGS) $(HELPER_OBJS) -o $@ $(LDFLAGS) $(LDLIBS)

src/%.o: src/%.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

install: x3dctl-helper
	@echo "Installing binaries..."
	install -Dm755 x3dctl $(DESTDIR)$(BINDIR)/x3dctl
	install -Dm755 x3dctl-helper $(DESTDIR)$(BINDIR)/x3dctl-helper

	@echo "Installing man page..."
	install -Dm644 man/x3dctl.1 $(DESTDIR)$(MANDIR)/x3dctl.1

	@echo "Installing sudoers file..."
	install -dm750 $(DESTDIR)/etc/sudoers.d
	sed 's|@BINDIR@|$(BINDIR)|g' packaging/x3dctl.sudoers.in \
		> $(DESTDIR)/etc/sudoers.d/x3dctl
	chmod 440 $(DESTDIR)/etc/sudoers.d/x3dctl

	@echo "Installing default config..."
	@if [ -n "$(DESTDIR)" ]; then \
		install -Dm644 "$(PROJECT_CONFIG)" "$(DESTDIR)$(SYSTEM_CONFIG)"; \
		echo "Staged $(DESTDIR)$(SYSTEM_CONFIG)"; \
	else \
		if [ ! -f "$(SYSTEM_CONFIG)" ]; then \
			install -Dm644 "$(PROJECT_CONFIG)" "$(SYSTEM_CONFIG)"; \
			echo "Installed $(SYSTEM_CONFIG)"; \
		else \
			echo "$(SYSTEM_CONFIG) already exists — leaving untouched"; \
		fi; \
	fi

	@if [ -z "$(DESTDIR)" ]; then \
		echo ""; \
		echo "Optional passwordless convenience mode:"; \
		echo "  sudo make pw-install PREFIX=$(PREFIX)"; \
		echo ""; \
		echo "This applies extended capabilities to x3dctl-helper."; \
		echo "Default sudo/sudoers behavior remains the recommended baseline."; \
        fi

	@echo "Install complete."

pw-install: install
	@if [ -n "$(DESTDIR)" ]; then \
		echo "ERROR: pw-install is for live installs only (not DESTDIR packaging)."; \
		exit 1; \
	fi
	@echo "Enabling passwordless convenience mode (advanced / best effort)..."
	setcap 'cap_sys_nice,cap_sys_admin=ep' "$(BINDIR)/x3dctl-helper"
	@echo "Capabilities applied to $(BINDIR)/x3dctl-helper"

pw-uninstall:
	@if [ -n "$(DESTDIR)" ]; then \
		echo "ERROR: pw-uninstall is for live installs only."; \
		exit 1; \
	fi
	@echo "Removing capabilities from $(BINDIR)/x3dctl-helper..."
	setcap -r "$(BINDIR)/x3dctl-helper" || true
	@echo "Capabilities removed."

uninstall:
	@if [ -z "$(DESTDIR)" ] && [ "$$(id -u)" -ne 0 ]; then \
		echo "ERROR: Run 'sudo make uninstall' for system removal."; \
		exit 1; \
	fi

	@echo "Removing installed files..."
	rm -f $(DESTDIR)$(BINDIR)/x3dctl
	rm -f $(DESTDIR)$(BINDIR)/x3dctl-helper
	rm -f $(DESTDIR)$(MANDIR)/x3dctl.1
	rm -f $(DESTDIR)/etc/sudoers.d/x3dctl

	@if [ -n "$(DESTDIR)" ]; then \
		rm -f $(DESTDIR)$(SYSTEM_CONFIG); \
	fi

	@echo "Uninstall complete."

clean:
	rm -f x3dctl-helper $(HELPER_OBJS)

.PHONY: all install pw-install pw-uninstall uninstall clean
