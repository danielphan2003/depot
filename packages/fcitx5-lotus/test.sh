#!/bin/sh
# Smoke test, run by scripts/install-test.sh after a clean install from the
# repository. DEPOT_VERSION is the version from package.env. The server
# needs /dev/uinput and a fcitx5 peer, so this checks the installed pieces.
set -eu
[ -f /usr/lib/fcitx5/liblotus.so ]
grep -q '^Library=liblotus' /usr/share/fcitx5/addon/lotus.conf
grep -q 'User=uinput_proxy' /usr/lib/systemd/system/fcitx5-lotus-server@.service
grep -q 'setfacl -m u:uinput_proxy:rw /dev/uinput' /usr/lib/udev/rules.d/99-lotus.rules
grep -rq "$DEPOT_VERSION" /usr/share/fcitx5-lotus/settings-gui/version.py
echo "fcitx5-lotus $DEPOT_VERSION: addon, server unit, udev rule and settings GUI installed"
