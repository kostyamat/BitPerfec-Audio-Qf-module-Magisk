#!/usr/bin/env bash
# SessionStart(compact) hook for the BitPerfect session: after a compaction, print what to do
# first. The global after_compact.py already prints the slice and git state; this adds the
# project's own resume checklist. stdout of a SessionStart hook is added to the context.
cat <<'EOF'
=== BitPerfect: after compaction, before anything else ===
1. Re-arm the board watchman (Monitor, re-arm on every 30-min expiry):
   "C:/Program Files/Python312/python.exe" C:/repos/agent-bridge/watch_board.py --session 3827b401-ee38-4390-8b5a-8b5a12ad49b7 --agent Claude --window local_bd04d1ce-829d-462b-836e-6f38608f5b29
2. Call audio is DONE (13.10, see slice). Open, in this order:
   - QF_SystemUI_Mod: Notification Centre button is on the bench; press blocked by Unisoc autolaunch on THEIR app
     (#1720) - wait for session 704c824e, then contract item 5 end-to-end; then drop the diagnostic Log.i.
   - QF_Framework_Mod TODO #1: ACC_ON broadcast + FLAG_RECEIVER_INCLUDE_BACKGROUND (owner: "так, але в туду").
   - BitPerfect Control (per-mode mic; AEC reference always moves with the mic); EQ wDSP waits for their prototype.
   WSL: always `wsl -u root -e bash script.sh` (global CLAUDE.md).
3. After any cvs.xml/pga change on the bench: delete /data/vendor/local/media/audio_params/<blob> + reboot
   (the module installer does it). Clean installs only: module zip from the commit (git archive, 7 entries).
4. Bench 192.168.1.138:9876 (moves: scan 9876). Announce adb only if another line is on the bench.
   Never cut `dumpsys media.audio_flinger` with head/grep -m1 - dump to a file.
5. Other repos: QF_Framework_Mod (call-volume persist + wake reset, 13.10), QF_SystemUI_Mod, QF_Bluetooth_Mod,
   DialerKM, QF_Cellular_Calling - each has its own slice.
   BT dialer is persistent: after pm install -r -> reboot. Keystore password never goes into files.
6. Do not push (the owner pushes). Commit after each verified step; rewrite .agents/HANDOFF.md (<= 4 KB).
EOF
