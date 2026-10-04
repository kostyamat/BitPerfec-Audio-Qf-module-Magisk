#!/usr/bin/env bash
# SessionStart(compact) hook for the BitPerfect session: after a compaction, print what to do
# first. The global after_compact.py already prints the slice and git state; this adds the
# project's own resume checklist. stdout of a SessionStart hook is added to the context.
cat <<'EOF'
=== BitPerfect: after compaction, before anything else ===
1. Re-arm the board watchman (Monitor, persistent):
   "C:/Program Files/Python312/python.exe" C:/repos/agent-bridge/watch_board.py --session 3827b401-ee38-4390-8b5a-8b5a12ad49b7 --agent Claude --window local_bd04d1ce-829d-462b-836e-6f38608f5b29
2. Read the Gemini results that were pending at compaction time:
   - Дж ad912b89 (wDSP: AudioRecord -> AUDIO_SOURCE_UNPROCESSED, one place): room
     "gemini-window-3827-сову-на-глобус-wdsp", threads #1346 / #1348. Acceptance: HAL log
     name:Music\Handsfree\UnprocessRecord, no NsEnable; mic level far above -98 dB; call to 1200
     without dsp timeout. Final acceptance belongs to the Claude wDSP session.
   - Дж 0c0b138e (who remaps UNPROCESSED 9 -> MIC 1 before the HAL; CAPTURE_AUDIO_OUTPUT denied):
     room "gemini-window-3827-підключись-до-магніто", thread #1347. Also #1340 (8581 call params).
   Check every claim against the code / the wire before it lands in BitPerfect.
3. Bench address moves after power cuts: scan 192.168.1.0/24 for port 9876 (last: .140).
   One adb driver per bench - announce on the board before taking it.
4. Do not push. Commit after each verified step; rewrite .agents/HANDOFF.md, never append.
EOF
