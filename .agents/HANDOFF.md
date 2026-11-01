# Slice — 01.11.2026, session `3827b401` (Claude): v5.7.2 on stand 194 — own navigators, live path, shared mic in force

**v5.7.2-Universal (5702), commit `cea3c59`** — test build, not a release (no tag, `update.json` still 5.6.1).
Installed on **stand 194 `192.168.1.194:9876`** (QF05 004121, ums512, BU32107). Stand is shared with QF_DVR
(session 147a9dc2) — talk to it ONLY in board room `qf-dvr-claude-window-7ef9` (owner set it 01.11, #2031; not Gemini's
`50b5 ↔ MCU patch` room); rules in `C:\APPS_Contacts\BitPerfect--DVR\MIC_CLIENT_CONTRACT.md` § «Stand 194» —
reboot only `svc power reboot`, `working`/`done` on the board, each line touches only its own module.

**Repo:** `v5.4-repaired`, ~45 commits local (origin = 23.10) — push on order. Release v5.6.1 live.

## ✅ This session (01.11), all committed, verified on stand 194
- Shared mic (`b1082ce`) **in force**: DVR measured wDSP Pro + DVR both UNPROCESSED, `silenced:false`. ⏳ SIM call
  silencing both — owner's test.
- USB switch waits for audioserver (2–3 s), status prints `playing=<usb|internal> cardN/pcmMp fmt ch rate`; app shows
  the real path and polls every 3 s through one root shell (`88fff49`, `f6e0b66`).
- Own navigators (`3605cb5`, `eac7d5b`): `/sdcard/BitPerfectAudio/navigators.conf`, base in `common/NaviApp.base.ini`,
  `bp_ctl.sh navi list|set|del`; app card «Navigators» (add an installed app, its volume control → prompts, music
  under prompts car/0–100 %). Applies after reboot. Stand: set/del work, live file 65 lines, no malformed line.
  ⏳ Owner to try the card itself (below the fold — no screenshot taken).
- 📻 USB DAC facts: owner's PCM2704 = «Burr-Brown from TI USB Audio DAC», S16_LE, 32/44.1/48 kHz — 16/48 is its
  ceiling; the earlier GeneralPlus dongle: S16, 44.1/48. Hot-plug of the PCM2704 worked without a reboot this time
  (UsbAlsaManager → APM USB_HEADSET); if the owner sees it fail again, capture `logcat` at that plug.

## ⏳ In progress — DAC mode (owner 01.11: DAC first, then mic)
Module side done, not on the stand yet (`33f09b8`): `usb_dac_mode=auto|FORMAT/RATE`, `bp_ctl.sh usb_mode`, status
`card=` / `usb_caps=` / `usb_mode=` / `usb_mode_state=`. Next: the app — the USB card shows the DAC's own name + id,
a mode picker from `usb_caps` (stereo only), the path note names the card (internal / USB); then v5.7.3 to stand 194.
Then the mic block (TODO §3): per-mode gain, NR/AEC switches, AEC auto-calibration per mode, NR curve presets.

## Waiting
- Gemini #2009 correction still owed (PGA step ≈5–6 dB at the top, not 3; with BitPerfect source 9 passes).
- Owner: SIM call without echo (v5.6.1 `58d9759`); testers: BD37xxx survey, engine hum, navigator reports.
- 🧩 Next idea, not started: a service that notices an unknown app speaking navigation and offers to add it (TODO §3).

## 📋 Next (owner 15.10; `.agents/TODO.md`)
1. Testers' feedback. 2. UIS8581 mic via `/data` audio_para — with a tester. 3. BitPerfect Control: per-mode mic,
AEC/NR/AGC (TODO §3). 4. EQ for wDSP (TODO §4).
