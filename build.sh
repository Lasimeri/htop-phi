#!/usr/bin/env bash
# build.sh: cross-build htop for the Intel Xeon Phi 3120A (Knights Corner)
# with the card toolchain from the Intel Phi 3120A repository, audit it,
# and package it. Requires that repository's toolchain (knc-cc, the musl
# sysroot with libncursesw from card/userland/components/ncurses.sh) and
# its phi-isa-audit tool. Set PHI_ROOT to the repository (default:
# ~/Intel Phi 3120A). Output: build/htop-phi.tar.gz (installs /opt/phi/bin/htop).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
PHI_ROOT="${PHI_ROOT:-$HOME/Intel Phi 3120A}"
. "$PHI_ROOT/toolchain/env.sh"
VER="${HTOP_VERSION:-3.5.3}"
URL="https://github.com/htop-dev/htop/releases/download/$VER/htop-$VER.tar.xz"
DL="$here/build/downloads"
SRC="$here/build/htop-$VER"
PKG="$here/build/root/opt/phi"
AUDIT="$PHI_ROOT/host/target/debug/phi-isa-audit"
mkdir -p "$DL"
tarball="$DL/htop-$VER.tar.xz"
if [ ! -s "$tarball" ]; then
    echo "== fetching $URL"
    curl -fL --retry 3 -o "$tarball.part" "$URL" && mv "$tarball.part" "$tarball"
fi
echo "$(sha256sum "$tarball" | awk '{print $1}')  htop-$VER.tar.xz" > "$DL/SHA256SUMS.new"
if [ -f "$here/SHA256SUMS" ] && grep -q "htop-$VER.tar.xz" "$here/SHA256SUMS"; then
    diff <(grep "htop-$VER.tar.xz" "$here/SHA256SUMS") "$DL/SHA256SUMS.new" > /dev/null || { echo "SHA-256 mismatch for htop-$VER.tar.xz" >&2; exit 1; }
else
    cat "$DL/SHA256SUMS.new" >> "$here/SHA256SUMS"
fi
rm -rf "$SRC"; mkdir -p "$SRC"
tar -xJf "$tarball" -C "$SRC" --strip-components=1
for p in "$here"/patches/*.patch; do [ -e "$p" ] && (cd "$SRC" && patch -p1 < "$p"); done
cd "$SRC"
echo "== configuring"
# Static link against the card's musl and libncursesw (terminfo built in);
# no sensors, no capabilities, no delay accounting (nothing on the card
# provides them); unicode on, as the ncurses build is the wide one.
./configure --host=x86_64-linux-musl --build=x86_64-pc-linux-gnu \
    CC=knc-cc AR=llvm-ar RANLIB=llvm-ranlib STRIP=llvm-strip \
    CFLAGS="-O2 -I$PHI_SYSROOT/usr/include/ncursesw" LDFLAGS="-static" \
    --enable-static --enable-unicode --disable-sensors --disable-capabilities \
    --disable-delayacct --disable-hwloc --disable-affinity > configure.log 2>&1 || { tail -20 configure.log; exit 1; }
echo "== building"
make -j"$(nproc)" > make.log 2>&1 || { tail -20 make.log; exit 1; }
llvm-strip htop
echo "== audit (must be clean)"
"$AUDIT" htop
rm -rf "$here/build/root"; mkdir -p "$PKG/bin"
cp htop "$PKG/bin/htop"
(cd "$here/build/root" && tar -czf "$here/build/htop-phi.tar.gz" opt)
ls -l "$PKG/bin/htop" "$here/build/htop-phi.tar.gz"
echo "== the card binary runs on the host too"
./htop --version | head -1
