PREFIX ?= /usr/local
DESTDIR ?=

BINDIR := $(PREFIX)/bin
MANDIR := $(PREFIX)/share/man/man1
SYSTEM_CONFIG := /etc/x3dctl.conf
PROJECT_CONFIG := etc/x3dctl.conf

CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -Werror -Wmissing-prototypes -Wstrict-prototypes -Werror=implicit-function-declaration -std=gnu11
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

	@echo "Applying capabilities (best effort)..."
	@if [ -z "$(DESTDIR)" ]; then \
		if command -v setcap >/dev/null 2>&1; then \
			setcap 'cap_sys_nice,cap_sys_admin=ep' "$(BINDIR)/x3dctl-helper" || \
				echo "Warning: setcap failed; sudoers fallback remains available."; \
		else \
			echo "Warning: setcap not found; sudoers fallback remains available."; \
		fi; \
	else \
		echo "Skipping setcap under DESTDIR/fakeroot packaging."; \
	fi

	@echo "Installing default config (if missing)..."
	@if [ -z "$(DESTDIR)" ]; then \
		if [ ! -f "$(SYSTEM_CONFIG)" ]; then \
			install -Dm644 "$(PROJECT_CONFIG)" "$(SYSTEM_CONFIG)"; \
			echo "Installed $(SYSTEM_CONFIG)"; \
		else \
			echo "$(SYSTEM_CONFIG) already exists — leaving untouched"; \
		fi; \
	else \
		echo "Skipping live config install under DESTDIR/fakeroot packaging."; \
	fi

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
	rm -f $(DESTDIR)/etc/sudoers.d/x3dctl

	@echo "Uninstall complete."

clean:
	rm -f x3dctl-helper $(HELPER_OBJS)

.PHONY: all install uninstall clean
