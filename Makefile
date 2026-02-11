.SILENT:

PREFIX      := /usr/local
DESTDIR     ?=
BINDIR      := $(DESTDIR)$(PREFIX)/bin
SUDOERSDIR  := $(DESTDIR)/etc/sudoers.d

BIN_FRONT   := x3dctl
BIN_HELPER  := x3dctl-helper
SRC_HELPER  := x3dctl-helper.c

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

	echo "[*] Install complete"

uninstall:
	echo "[*] Removing binaries"
	sudo rm -f $(BINDIR)/$(BIN_FRONT)
	sudo rm -f $(BINDIR)/$(BIN_HELPER)

	echo "[*] Removing sudoers rule"
	sudo rm -f $(SUDOERSDIR)/x3dctl

	echo "[*] Uninstall complete"

clean:
	rm -f $(BIN_HELPER)

