#!/usr/bin/env bash
# SessionStart(compact) hook for the BitPerfect session: after a compaction, print what to do
# first. The global after_compact.py already prints the slice and git state; this adds the
# project's own resume checklist. stdout of a SessionStart hook is added to the context.
cat <<'EOF'
=== BitPerfect: after compaction, before anything else ===
1. Re-arm the board watchman (Monitor, re-arm on every 30-min expiry):
   "C:/Program Files/Python312/python.exe" C:/repos/agent-bridge/watch_board.py --session 3827b401-ee38-4390-8b5a-8b5a12ad49b7 --agent Claude --window local_bd04d1ce-829d-462b-836e-6f38608f5b29
2. You run the room "bitperfect-control-qfphone-rokoai" (owner 06.10): rules #1441 (announce adb /
   reboot, BitPerfect changes only through you, evidence marks), reports go to the board.
   Pending there:
   - #1536 Claude wDSP (OTHER account, reads the board later): call preset must switch at
     PHONE_CALL_START / sys.qf.call_state / btcall_type in the service, not when the screen opens.
   - #1535/#1537 debugger Gemini 0c0b138e: which AEC runs on BT calls and its echo tail; why
     setMode(3) never happens (SCO reset after 3 s). Demand code-from-source proof (owner).
   - RokoAi Gemini 2495fea2: keep Vosk without software gain; WAV probes in /sdcard/RokoAi.
3. Bench: 192.168.1.138:9876 (moves after power cuts: scan 192.168.1.0/24 for 9876).
   Never cut `dumpsys media.audio_flinger` with head/grep -m1 (SIGPIPE kills the HAL) - dump to a file.
4. DP in VoiceRecognition/UnprocessRecord stays ON (A/B 07.10: without it the owner is not heard).
5. Do not push (the owner pushes). Commit after each verified step; rewrite .agents/HANDOFF.md.
EOF
