#!/usr/bin/env bash
# SessionStart(compact) hook for the BitPerfect session: after a compaction, print what to do
# first. The global after_compact.py already prints the slice and git state; this adds the
# project's own resume checklist. stdout of a SessionStart hook is added to the context.
cat <<'EOF'
=== BitPerfect: after compaction, before anything else ===
1. Re-arm the board watchman (Monitor, re-arm on every 30-min expiry):
   "C:/Program Files/Python312/python.exe" C:/repos/agent-bridge/watch_board.py --session 3827b401-ee38-4390-8b5a-8b5a12ad49b7 --agent Claude --window local_bd04d1ce-829d-462b-836e-6f38608f5b29
2. Mic P0 is CLOSED (13.10): defaults known (call 7/7, record DG 0, raw 9 without DP; 12 dB headroom at slider 7).
   Open: BitPerfect Control (per-mode mic editing; AEC reference ALWAYS moves with the mic); EQ wDSP waits for their
   prototype (#1703); SystemUI -> QF_NotificationCenter call from the status bar (QF_SystemUI_Mod, needs a contract).
3. After any cvs.xml/pga change on the bench: delete /data/vendor/local/media/audio_params/<blob> + reboot
   (the module installer does it). Clean installs only: module zip from the commit (git archive, 7 entries).
4. Bench 192.168.1.138:9876 (moves: scan 9876). Announce adb only if another line is on the bench.
   Never cut `dumpsys media.audio_flinger` with head/grep -m1 - dump to a file.
5. Other repos: QF_Framework_Mod (call-volume persist + wake reset, 13.10), QF_SystemUI_Mod, QF_Bluetooth_Mod,
   DialerKM, QF_Cellular_Calling - each has its own slice.
   BT dialer is persistent: after pm install -r -> reboot. Keystore password never goes into files.
6. Do not push (the owner pushes). Commit after each verified step; rewrite .agents/HANDOFF.md (<= 4 KB).
EOF
