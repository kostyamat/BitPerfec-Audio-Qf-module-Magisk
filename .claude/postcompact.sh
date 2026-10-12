#!/usr/bin/env bash
# SessionStart(compact) hook for the BitPerfect session: after a compaction, print what to do
# first. The global after_compact.py already prints the slice and git state; this adds the
# project's own resume checklist. stdout of a SessionStart hook is added to the context.
cat <<'EOF'
=== BitPerfect: after compaction, before anything else ===
1. Re-arm the board watchman (Monitor, re-arm on every 30-min expiry):
   "C:/Program Files/Python312/python.exe" C:/repos/agent-bridge/watch_board.py --session 3827b401-ee38-4390-8b5a-8b5a12ad49b7 --agent Claude --window local_bd04d1ce-829d-462b-836e-6f38608f5b29
2. First task (P0, in the slice): SIM mic sensitivity too low after 906a42b. Compare TX gain/AGC fields of
   cvs.xml Audio/Handset vs Handsfree (v4.18 copy: unzip QF_BitPerfect.module.v4.18.zip); give Handset its TX gain
   back, keep the AEC/NLP values. Owner rule: mic sensitivity WITH HEADROOM in all modes; the user trims it with
   the car-settings sliders (persist.sys.mainmic.gain -> ADCL/ADCR Capture Gain).
3. After any cvs.xml/pga change on the bench: delete /data/vendor/local/media/audio_params/<blob> + reboot
   (the module installer does it). Clean installs only: module zip from the commit (git archive, 7 entries).
4. Bench 192.168.1.138:9876 (moves: scan 9876). Announce adb/reboot in room bitperfect-control-qfphone-rokoai.
   Never cut `dumpsys media.audio_flinger` with head/grep -m1 - dump to a file.
5. Other repos touched 12.10: QF_Bluetooth_Mod (BT dialer, own slice), DialerKM, QF_Cellular_Calling.
   BT dialer is persistent: after pm install -r -> reboot. Keystore password never goes into files.
6. Do not push (the owner pushes). Commit after each verified step; rewrite .agents/HANDOFF.md (<= 4 KB).
EOF
