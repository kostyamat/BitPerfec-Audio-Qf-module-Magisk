# Slice — 01.11.2026, session `3827b401` (Claude): v5.7.5 on stand 194 — mic engine works, app card next

**v5.7.5-Universal (5705), commit `27951b0`** — test build, not a release (no tag, `update.json` still 5.6.1).
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

## Microphone (owner 01.11: «берись за мікрофон»), plan + field map `.agents/MIC_CONTROL.md`
Done, on stand, 📻 seen on screen: `common/bp_mic.sh` (`bp_ctl.sh mic show|set|reset|preset`, gain/AEC/NR/
`nr_depth` → `Tx_Mono_Post/Gain_limit` 🧩), app card with tabs, depth slider, presets. Owner set BT +3, SIM nr 0.
**Next:** AEC calibration per mode (fader front/centre by MCU, then ask the user to restore it in the EQ app) —
by day; bench numbers do not carry to a car. ❓ real call: SIM = Handsfree NB/WB? `POS` = NR post-filter?
In-call live tuning needs the HAL tuning server: reverse `start_audio_tunning_server` (32-bit primary HAL).

## ⏳ USB DAC (owner 01.11: «Бери ЦАП»), on stand 194, PCM2704
✅ `ddfafda` the module announces the DAC to AudioService after a switch/restart (IAudioService 60, SDK 29) — it
used to stay silent until replugged. ✅ `ee249d0`/`27951b0` `common/bp_usbvol.sh` watcher: Android full scale on
the USB device (index 15), level = the DAC's own control; `usb_dac_volume=follow` maps `sys.media.vol` 0..32
(unset → `persist.sys.main_volume`) to it, no control → no follow (owner: «немає - значить немає»). App toggle
`6a26b2b`. 📻 knob 16→64, 32→128; after boot 12/128 with main=3. ❓ PCM2704 unit in dB.
**Next:** sleep beeping — start `/data/local/tmp/dacsleep.sh` (scratchpad copy) BEFORE the owner turns ACC off.
Then «Авто» = direct USB output for the player (patch `libaudiopolicymanager` getOutputForDevice: linear PCM →
direct when the DAC declares its format/rate); ❓ owner: where prompts go while the player holds the DAC (I said
head-unit speakers).

## Waiting
- Gemini #2009 correction still owed (PGA step ≈5–6 dB at the top, not 3; with BitPerfect source 9 passes).
- Owner: SIM call without echo (`58d9759`); SIM call silencing wDSP+DVR; testers' reports.

## 📋 Next (`.agents/TODO.md`)
1. Testers' feedback. 2. UIS8581 mic via `/data` audio_para — with a tester. 3. BitPerfect Control: mic block
(above), navigators service (TODO §3). 4. EQ for wDSP (TODO §4).
