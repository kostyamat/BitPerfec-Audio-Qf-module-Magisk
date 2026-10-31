# Slice — 31.10.2026, session `3827b401` (Claude): DVR mic sharing in progress; next release in git, no unit

**Owner's brief:** NR and AEC for SIM/BT calls, a clean mic for wDSP/AI. Announce adb on the board only when another
line is on the bench. No sound at night without permission. Push / release only on order (`.agents/RELEASE.md`).
wDSP is now wDSP Pro `com.communityofdevs.wdsp_pro` (BitPerfect names no wDSP package).

**Repo:** `v5.4-repaired` (GitHub default); origin = 23.10, ~27 commits local — push on order. Release v5.6.1 live,
Magisk `updateJson` live. **Bench `192.168.1.138:9876` DEAD since 25.10** (new unit awaited; last: v5.6.1).
Firmware for offline work: `D:\Release\update(2)` = QF 7862, `8581_QF005`/`8581_BMW` = 8581, `TS10_*` = Topway.

## ⏳ IN PROGRESS — answer owed to QF_DVR (#1997; room `gemini-window-50b5-mcu-patch`, #2008)
DVR (session 147a9dc2, contract `C:\APPS_Contacts\BitPerfect--DVR\MIC_CLIENT_CONTRACT.md`) records UNPROCESSED 48k mono
next to wDSP Pro; Android 10 silences all but the top/latest uid (wDSP `silenced:true`). Owner: «UNPROCESSED ВДСП бере
завжди. Все решту має сідати до нього ресемплом як клієнт… BitPerfect дозволяє».
🔬 AOSP 10 `AudioPolicyService::updateUidStates_l`: allowCapture needs `isTopOrLatestActive`; `canCaptureOutput` lifts
only the call/sensitive clauses. Plan: patch `/system/lib64/libaudiopolicyservice.so` (7862 md5 9138eb08…, 8581
f08142f6…; stripped — find the function in Ghidra by its logic) to drop the top/latest term, KEEP in-call and
privacy-sensitive (VOICE_COMMUNICATION / CAMCORDER) silencing; both clients already share `patch:17`. Then: patch tool
like `tools/patch_libaudiopolicymanager.py`, answer DVR in the room + edit the contract, test on the new unit. Also
correct Gemini #2009 there: PGA step measured ≈5–6 dB at the top (not 3); with BitPerfect source 9 passes (no forced
MIC/stereo). First action after a restart: re-arm the board watchman (owner asked twice).

## Waiting
- Next release (not built): installer English, USB DAC `usb_dac` (`5c79546`), UIS8581 reduced profile (`4f9fe9e`,
  `01675f6`), BitPerfect Control v0.1 priv-app (`97bb76f`, `6867601`, emulator only), survey v1.4 mic check
  (`e0d4559`). All verified offline/emulator only. On the new 7862 unit: install, flag 1, DAC both values, the app.
- Owner to confirm a SIM call without echo (v5.6.1 fix `58d9759`). SIM AEC leaks phrase ends a little (fine-tune in app).
- Testers: BD37xxx survey, engine hum via SIM 50 Hz cutoff, navigator reports; owner's MapFactor when ready.
- Mic defaults (📻 13.10): slider 0..7 ≈5–6 dB/step at the top, 7 = ≈12 dB headroom; AEC reference ADC3 moves only
  together with the mic ADC2.

## 📋 Next (owner 15.10; `.agents/TODO.md`)
1. Testers' feedback and logs. 2. UIS8581: mic via `/data` audio_para — only with a tester (TODO §2).
3. BitPerfect Control: navigators service, per-mode mic, AEC/NR/AGC (TODO §3). 4. EQ for wDSP (TODO §4).
