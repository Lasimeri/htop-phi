# htop for the Intel Xeon Phi 3120A

htop 3.5.3 cross-built for the Xeon Phi 3120A (Knights Corner, 57 cores,
228 threads) running the mainline Linux port from
[Intel-Phi-3120A](https://github.com/Lasimeri/Intel-Phi-3120A): static
against musl and a wide-character ncurses with the common terminal
descriptions compiled in, restricted to the instruction subset the card
executes (no SSE, no CMOV, x87 floating point), and checked with that
repository's `phi-isa-audit` before it is packaged.

No source patches are needed: htop is portable C over `/proc` and ncurses;
what the port consists of is the toolchain and the audit.

## Build

Requirements: the Intel-Phi-3120A repository with its toolchain built
(phase P2) and `card/userland/components/ncurses.sh` run once, the host's
`tic` for that step. Then:

```
PHI_ROOT=~/Intel\ Phi\ 3120A ./build.sh
```

produces `build/htop-phi.tar.gz`, which unpacks to `/opt/phi/bin/htop`
(716 KB, stripped). The card binary also runs on the host, since the host
executes the same instruction subset; `build.sh` prints its version that
way.

## Run on the card

With the card booted through the main repository's tools (`scripts/phi-up.sh`
or `phictl boot --serve`):

```
./push.sh                         # copies and unpacks the tarball on the card
ssh root@10.9.0.2 -t TERM=xterm-256color /opt/phi/bin/htop
```

htop needs a terminal, so the interactive use is over SSH (the card's
dropbear, with the network bridge up) or on the ring console. Through the
non-interactive control socket, `push.sh` verifies the binary by running it
against the card's console tty for a few seconds and checking the drawn
screen in the console log.

What you see: 228 CPU meters (57 cores, 4 threads each, 1.1 GHz in-order,
no frequency reporting), 5.7 GB of GDDR, the ring devices' kernel threads,
and whatever you started. Sensors, capabilities and delay accounting are
compiled out: the card exposes none of them.

## Files

- `build.sh`: fetch, verify (`SHA256SUMS`), cross-configure, build, audit, package.
- `push.sh`: load onto a running card and smoke-test.
- `patches/`: empty; kept for the day upstream needs a change.
- `docs/results.md`: what was measured on the card.
