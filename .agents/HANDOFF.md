# Slice — 31.10.2026, session `3827b401` (Claude): v5.7 test build on stand 194; shared mic to verify

**v5.7-Universal (5700), commit `abaddfa`** — test build for testers (owner has the zip, not a release: no tag,
`update.json` still 5.6.1). Installed on **stand 194 `192.168.1.194:9876`** (QF05 004121, ums512, BU32107, NXP),
installer all English. Owner 31.10: no board announcements — only he and this line work.
📻 21:42 after boot: `sys.bitperfect.enabled=1`, patched `libaudiopolicyservice.so` mounted (md5 1a30dfaf…), app in
priv-app, WD_24BIT, primary 0x4 / 48 kHz, «Audio path is healthy»; wDSP Pro UNPROCESSED 48k `silenced:false`.
⏳ Not yet seen: DVR recording at the same time (`com.kostyamat.qfdvr` runs, its mic switch off) — turn it on, then
`dumpsys audio` → RecordActivityMonitor: both `silenced:false`; then a SIM call should silence both.

**Owner's brief:** NR and AEC for SIM/BT calls, a clean mic for wDSP/AI. Announce adb on the board only when another
line is on the bench. No sound at night without permission. Push / release only on order (`.agents/RELEASE.md`).
wDSP is now wDSP Pro `com.communityofdevs.wdsp_pro` (BitPerfect names no wDSP package).

**Repo:** `v5.4-repaired` (GitHub default); origin = 23.10, ~31 commits local — push on order. Release v5.6.1 live,
Magisk `updateJson` live. Old bench `192.168.1.138:9876` dead since 25.10; stand 194 (above) is the live one.
Firmware for offline work: `D:\Release\update(2)` = QF 7862, `8581_QF005`/`8581_BMW` = 8581, `TS10_*` = Topway.

## ✅ Shared microphone for QF_DVR (`b1082ce`) — offline only
Patched `libaudiopolicyservice.so` shipped as files (owner: «просто латану в модуль, все» — no install-time md5):
`system/lib64` (7862), `profiles/sp9863a/system/lib64` (8581, copied by customize.sh). Tool
`tools/patch_libaudiopolicyservice.py`. Contract `C:\APPS_Contacts\BitPerfect--DVR\MIC_CLIENT_CONTRACT.md` has the
answer; DVR told (board #2018, full answer + test steps; waiting for its stand result). 🔬 QF already treats source MIC as virtual.
Still owed in room `gemini-window-50b5-mcu-patch`: correct Gemini #2009 — PGA step ≈5–6 dB at the top (not 3); with
BitPerfect source 9 passes (no forced MIC/stereo).

## Waiting
- v5.7 contents: installer English, USB DAC `usb_dac` (`5c79546`), UIS8581 reduced profile (`4f9fe9e`, `01675f6`),
  BitPerfect Control v0.1 (`97bb76f`, `6867601`), survey v1.4 (`e0d4559`), shared mic (`b1082ce`). Still to try on
  stand 194: the app (root prompt, status), USB DAC both values, the shared mic with DVR. 8581: testers only.
  Public release (tag, update.json, posts) only on the owner's order.
- Owner to confirm a SIM call without echo (v5.6.1 fix `58d9759`). SIM AEC leaks phrase ends a little (fine-tune in app).
- Testers: BD37xxx survey, engine hum via SIM 50 Hz cutoff, navigator reports; owner's MapFactor when ready.
- Mic defaults (📻 13.10): slider 0..7 ≈5–6 dB/step at the top, 7 = ≈12 dB headroom; AEC reference ADC3 moves only
  together with the mic ADC2.

## 📋 Next (owner 15.10; `.agents/TODO.md`)
1. Testers' feedback and logs. 2. UIS8581: mic via `/data` audio_para — only with a tester (TODO §2).
3. BitPerfect Control: navigators service, per-mode mic, AEC/NR/AGC (TODO §3). 4. EQ for wDSP (TODO §4).
