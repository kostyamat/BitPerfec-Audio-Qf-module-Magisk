#!/usr/bin/env bash
# SessionStart(compact) hook for the BitPerfect session: after a compaction, print what to do
# first. The global after_compact.py already prints the slice and git state; this adds the
# project's own resume checklist. stdout of a SessionStart hook is added to the context.
cat <<'EOF'
=== BitPerfect: after compaction, before anything else ===
1. Re-arm the board watchman (Monitor, re-arm on every 30-min expiry):
   "C:/Program Files/Python312/python.exe" C:/repos/agent-bridge/watch_board.py --session 3827b401-ee38-4390-8b5a-8b5a12ad49b7 --agent Claude --window local_bd04d1ce-829d-462b-836e-6f38608f5b29
2. v5.6 RELEASED 15.10 (GitHub tag v5.6, 4PDA/XDA posts) - waiting for testers. Calls (SIM/BT/Telegram/
   WhatsApp), mic, guard, BD layout are done. Next, when reports come: BD37xxx survey, engine hum (SIM),
   navigator reports (QF_audio_survey v1.3); owner's "strange navigator" (MapFactor) - watch logcat when ready.
   Then BitPerfect Control (per-mode mic, SIM AEC fine-tuning; AEC reference always moves with the mic).
   QF_Framework_Mod / QF_SystemUI_Mod / QF_Bluetooth_Mod now have their OWN sessions - not this one's work.
   Releases: .agents/RELEASE.md.  WSL: `-u root` for tools, but PUSH as the default user (keys in its ~/.ssh).
3. After any cvs.xml/pga change on the bench: delete /data/vendor/local/media/audio_params/<blob> + reboot
   (the module installer does it). Clean installs only: module zip from the commit (git archive, 7 entries).
4. Bench 192.168.1.138:9876 (moves: scan 9876). Announce adb only if another line is on the bench.
   Never cut `dumpsys media.audio_flinger` with head/grep -m1 - dump to a file.
5. Other repos: QF_Framework_Mod (call-volume persist + wake reset, 13.10), QF_SystemUI_Mod, QF_Bluetooth_Mod,
   DialerKM, QF_Cellular_Calling - each has its own slice.
   BT dialer is persistent: after pm install -r -> reboot. Keystore password never goes into files.
6. Push / release only on the owner's order. Commit after each verified step; rewrite .agents/HANDOFF.md (<= 4 KB).
EOF
