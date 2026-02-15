.SILENT:

PREFIX      := /usr/local
DESTDIR     ?=
BINDIR      := $(DESTDIR)$(PREFIX)/bin
SUDOERSDIR  := $(DESTDIR)/etc/sudoers.d
MANDIR      := $(DESTDIR)$(PREFIX)/share/man/man1


BIN_FRONT   := x3dctl
BIN_HELPER  := x3dctl-helper
SRC_HELPER  := x3dctl-helper.c
MANPAGE     := man/x3dctl.1

CC          := gcc
CFLAGS      := -O2 -Wall -Wextra

.PHONY: all install uninstall clean

all:
	echo "[*] Building helper"
	$(CC) $(CFLAGS) $(SRC_HELPER) -o $(BIN_HELPER)

install: all
	echo "[*] Installing frontend"
	sudo install -m 0755 $(BIN_FRONT) $(BINDIR)/$(BIN_FRONT)

	echo "[*] Installing helper"
	sudo install -m 0755 $(BIN_HELPER) $(BINDIR)/$(BIN_HELPER)

	echo "[*] Installing sudoers rule"
	echo "$(USER) ALL=(root) NOPASSWD: $(PREFIX)/bin/$(BIN_HELPER)" | sudo tee $(SUDOERSDIR)/x3dctl > /dev/null
	sudo chmod 0440 $(SUDOERSDIR)/x3dctl

	echo "[*] Installing man page"
	sudo install -Dm 0644 $(MANPAGE) $(MANDIR)/x3dctl.1

	echo "[*] Install complete"

uninstall:
	echo "[*] Removing binaries"
	sudo rm -f $(BINDIR)/$(BIN_FRONT)
	sudo rm -f $(BINDIR)/$(BIN_HELPER)

	echo "[*] Removing man page"
	sudo rm -f $(MANDIR)/x3dctl.1

	echo "[*] Removing sudoers rule"
	sudo rm -f $(SUDOERSDIR)/x3dctl
	
	echo ""
	echo "[*] Uninstall complete"
	echo "[*] NOTE: the x3dctl man page and build files exist only in the source tree."
	echo "    you will need to re-clone the repository to reinstall later."
	echo ""


clean:
	rm -f x3dctl-helper

.PHONY: all install uninstall clean

