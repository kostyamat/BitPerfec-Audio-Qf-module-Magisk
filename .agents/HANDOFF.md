# Slice — 01.11.2026, session `3827b401` (Claude): v5.7.5 on stand 194 — mic engine works, app card next

**v5.7.5-Universal (5705), commit `61c60f1`** — test build, not a release (no tag, `update.json` still 5.6.1).
🔴 Bench builds keep the version now; bump only for testers / release (`RELEASE.md`, owner 01.11).
**Stand 194 `192.168.1.194:9876`** (QF05 004121, ums512, BU32107), shared with QF_DVR (session 147a9dc2): talk to it
ONLY in board room `qf-dvr-claude-window-7ef9`; rules in `C:\APPS_Contacts\BitPerfect--DVR\MIC_CLIENT_CONTRACT.md`
§ «Stand 194» (`svc power reboot`, `working`/`done`, own module only). If shutdown hangs on `ntfs3g` (DVR's NTFS
stick): DVR unbinds the stick (`authorized=0`), or sysrq s→u→b.

**Repo:** `v5.4-repaired`, ~60 commits local (origin = 23.10) — push on order. Release v5.6.1 live.

## In v5.7.x since the release (all on stand 194, committed)
Shared mic (in force, DVR measured); USB switch waits for audioserver; app shows the real path and polls; own
navigators (`navigators.conf`, card «Navigators»); DAC mode (`usb_dac_mode`, app: DAC name + id, declared modes,
mode picker — 📻 auto 48k, `S16_LE/44100` → 44.1k). ⏳ Owner to try: navigators card, DAC mode picker.

## ⏳ In progress — microphone (owner 01.11: «берись за мікрофон»), plan + field map `.agents/MIC_CONTROL.md`
Engine done (`2f14bff`): `common/bp_mic.sh`, `/sdcard/BitPerfectAudio/mic.conf`,
`bp_ctl.sh mic show|set <SIM|VOIP|BT> <gain_db|aec|nr> [v]`; live XML = base (common/) + user lines, blob deleted,
audioserver restarted (refused in a call); service.sh re-applies after a reinstall.
📻 blob SIM `ul_dgain_volume1`: 0x1800 → +3 dB 0x21e7 → reset 0x1800.
App card «Microphone» done (`9483cff`): SIM/VoIP/BT, level −12..+12 dB (sent on release), AEC and NR switches,
reset. App sections are now tabs under the status cards (`b9e24d0`, owner: «не стрічкою вниз… з купою скролу»).
Both in the v5.7.5 zip on stand 194 (`61c60f1`). 📻 Seen on screen 01.11 18:06: tabs switch, the mic card shows
SIM/VoIP/BT, level, AEC, NR, reset; the owner already set `BT gain_db 3`, `SIM nr 0` from it and the module applied them.
**Next:** NR curve presets → AEC calibration per mode (fader front/centre by MCU, then ask the user to restore it
in the EQ app).
❓ On a real call: SIM = Handsfree NB/WB? `POS` = noise post-filter?
Live tuning server: HAL logs «can not create tunning server thread»; it is a local socket (`socket_local_server`) —
reverse `start_audio_tunning_server` (32-bit `/vendor/lib/hw/audio.primary.ums512.so`); needed for in-call tuning.

## Waiting
- Gemini #2009 correction still owed (PGA step ≈5–6 dB at the top, not 3; with BitPerfect source 9 passes).
- Owner: SIM call without echo (`58d9759`); SIM call silencing wDSP+DVR; testers' reports.

## 📋 Next (`.agents/TODO.md`)
1. Testers' feedback. 2. UIS8581 mic via `/data` audio_para — with a tester. 3. BitPerfect Control: mic block
(above), navigators service (TODO §3). 4. EQ for wDSP (TODO §4).
