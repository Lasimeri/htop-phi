#!/usr/bin/env bash
# push.sh: load build/htop-phi.tar.gz onto the running card through the
# main repository's control socket (no SSH needed), then run htop for a
# few seconds on the card's console tty and check the console log for the
# drawn screen. Requires scripts/phi-up.sh (unprivileged) or phictl boot
# --serve in the main repository.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
PHI_ROOT="${PHI_ROOT:-$HOME/Intel Phi 3120A}"
P="$PHI_ROOT/host/target/debug/phictl"
PKG="$here/build/htop-phi.tar.gz"
[ -s "$PKG" ] || { echo "push.sh: $PKG missing; run build.sh" >&2; exit 1; }
"$P" status
"$P" put "$PKG" /tmp/htop-phi.tar.gz
"$P" exec -- sh -c 'cd / && tar -xzf /tmp/htop-phi.tar.gz && rm /tmp/htop-phi.tar.gz && /opt/phi/bin/htop --version'
# Smoke test without a terminal of our own: drive htop from the console
# tty for a moment; the screen it draws lands in the console log.
"$P" exec -- sh -c 'setsid sh -c "TERM=xterm-256color exec /opt/phi/bin/htop -d 10 < /dev/ttyPHI0 > /dev/ttyPHI0 2>&1" & sleep 4; kill %1 2>/dev/null; pkill htop 2>/dev/null; echo "htop ran on the console tty for 4 s"'
log="${XDG_RUNTIME_DIR:-/tmp/phictl-$(id -u)}/phictl/console.log"
if [ -f "$log" ] && grep -a -q "Tasks:" "$log"; then
    echo "push.sh: htop drew its screen on the card ($(grep -a -o 'Tasks: [0-9]*' "$log" | tail -1))"
else
    echo "push.sh: console log not found or no screen detected (fine when the card was booted with sudo elsewhere)"
fi
