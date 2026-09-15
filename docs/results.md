# Results

## 2026-09-14: first build

- Toolchain: Intel-Phi-3120A at commit `6395bb5` (clang 22 patched for the
  knc64-x87 ABI, musl, ncurses 6.5 wide with fallbacks).
- `build.sh`: configure with `--host=x86_64-linux-musl`, static, unicode,
  sensors/capabilities/delayacct/hwloc/affinity disabled; builds without a
  patch.
- Audit: 143862 instructions, 0 illegal, 0 suspect.
- Binary: 715664 bytes stripped; `htop --version` on the host prints
  `htop 3.5.3-3.5.3`.
- On the card: pending (see the commit that follows the first `push.sh`).

## 2026-09-14: on the card

Card booted unattended (`scripts/phi-up.sh` in the main repository, no
sudo), `./push.sh`:

```
phictl put: 334493 bytes
htop 3.5.3-3.5.3                       (on the card)
htop ran on the console tty for 4 s
```

htop's screen, recovered from the console log with the escape sequences
stripped:

```
Tasks: 7, 2 thr, 1477 kthr; 1 running
Mem[||||301M/5.55G]   Load average: 0.00 0.00 0.00
```

1477 kernel threads is what 228 CPUs cost in per-CPU workers; 5.55 GB is
the GDDR left after the kernel's reservations. Interactive use is over SSH
with the card's dropbear once the network bridge is up
(`ssh root@10.9.0.2 -t TERM=xterm-256color /opt/phi/bin/htop`).
