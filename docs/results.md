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
