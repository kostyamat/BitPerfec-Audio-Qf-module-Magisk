# Slice — 31.10.2026, session `3827b401` (Claude): shared mic done offline; next release in git, no unit

**Owner's brief:** NR and AEC for SIM/BT calls, a clean mic for wDSP/AI. Announce adb on the board only when another
line is on the bench. No sound at night without permission. Push / release only on order (`.agents/RELEASE.md`).
wDSP is now wDSP Pro `com.communityofdevs.wdsp_pro` (BitPerfect names no wDSP package).

**Repo:** `v5.4-repaired` (GitHub default); origin = 23.10, ~30 commits local — push on order. Release v5.6.1 live,
Magisk `updateJson` live. **Bench `192.168.1.138:9876` DEAD since 25.10** (new unit awaited; last: v5.6.1).
Firmware for offline work: `D:\Release\update(2)` = QF 7862, `8581_QF005`/`8581_BMW` = 8581, `TS10_*` = Topway.

## ✅ Shared microphone for QF_DVR (`b1082ce`) — offline only
Patched `libaudiopolicyservice.so` shipped as files (owner: «просто латану в модуль, все» — no install-time md5):
`system/lib64` (7862), `profiles/sp9863a/system/lib64` (8581, copied by customize.sh). Tool
`tools/patch_libaudiopolicyservice.py`. Contract `C:\APPS_Contacts\BitPerfect--DVR\MIC_CLIENT_CONTRACT.md` has the
answer; DVR told (board #2015). On the new unit: wDSP Pro + DVR both UNPROCESSED → both `silenced:false`
(`dumpsys media.audio_policy` to a file); a SIM call still silences them. 🔬 QF already treats source MIC as virtual.
Still owed in room `gemini-window-50b5-mcu-patch`: correct Gemini #2009 — PGA step ≈5–6 dB at the top (not 3); with
BitPerfect source 9 passes (no forced MIC/stereo).

## Waiting
- Next release (not built): installer English, USB DAC `usb_dac` (`5c79546`), UIS8581 reduced profile (`4f9fe9e`,
  `01675f6`), BitPerfect Control v0.1 priv-app (`97bb76f`, `6867601`, emulator only), survey v1.4 mic check
  (`e0d4559`), shared mic (`b1082ce`). All offline/emulator only. On the new 7862 unit: install, flag 1, DAC both
  values, the app, the shared mic.
- Owner to confirm a SIM call without echo (v5.6.1 fix `58d9759`). SIM AEC leaks phrase ends a little (fine-tune in app).
- Testers: BD37xxx survey, engine hum via SIM 50 Hz cutoff, navigator reports; owner's MapFactor when ready.
- Mic defaults (📻 13.10): slider 0..7 ≈5–6 dB/step at the top, 7 = ≈12 dB headroom; AEC reference ADC3 moves only
  together with the mic ADC2.

## 📋 Next (owner 15.10; `.agents/TODO.md`)
1. Testers' feedback and logs. 2. UIS8581: mic via `/data` audio_para — only with a tester (TODO §2).
3. BitPerfect Control: navigators service, per-mode mic, AEC/NR/AGC (TODO §3). 4. EQ for wDSP (TODO §4).
