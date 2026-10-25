# Slice — 25.10.2026, session `3827b401` (Claude): v5.6.1 released, waiting for testers

**Owner's brief:** NR and AEC for SIM/BT calls, a clean mic for wDSP/AI. BitPerfect is mine; I run the room
`bitperfect-control-qfphone-rokoai`. Announce adb on the board only when another line is on the bench. No sound at
night without permission. Push / release only on the owner's order (`.agents/RELEASE.md`).

**wDSP renamed** (22.10): wDSP Pro, `com.communityofdevs.wdsp_pro` (old `com.radiorubka.wdsp` may coexist). BitPerfect
names no wDSP package; if a script/whitelist ever does, add the new one.

**Repo:** `v5.4-repaired` (GitHub default branch), pushed 23.10 (only slice/TODO doc commits local — push on order); GitHub release **v5.6.1** (`25b5f8b` = update.json → v5.6.1;
annotation `.agents/release/v5.6.1_github_release.md`). Magisk `updateJson` live (raw update.json + CHANGELOG.md 200).
Forum posts (4PDA ru, XDA en) and the annotation: `.agents/release/`. Support group https://t.me/kostyamat_dev/3.

**Bench `192.168.1.138:9876`** (address moves — scan 9876): BitPerfect **v5.6.1**, calling module v3.8.4, BT dialer
v12 (its session), patched QF Framework and SystemUI (their own sessions now).

## Mic defaults (📻 13.10; owner: «дефолти ми вже знаємо», the user tunes the rest)
- Codec ADCL/ADCR 0..7 = car-settings slider, ≈ 5–6 dB/step at the top; VBC DG is inverted (0 = max).
  Phone tone at full volume, slider 7: peak ≈ −12 dBFS — ≈ 12 dB headroom.
- SIM call 7/7 (mic ADC2 = AEC reference ADC3): no echo; 4/4 — echo; reference apart from the mic — squeaks:
  **move them together only**. DRC_tx tried — «крошиться», reverted.

## ⏳ Waiting / open
- 25.10 next release (not built; bench DEAD, owner waits for a new unit; firmware in `D:\Release`: `update(2)` = QF 7862,
  `8581_QF005`/`8581_BMW` = 8581, `TS10_*` = Topway). In it: installer English (`12a3460`); USB DAC `usb_dac=0/1`
  in `/sdcard/BitPerfectAudio/bitperfect.conf` (`5c79546`); **UIS8581 reduced profile** (`4f9fe9e`, `01675f6`:
  factory 16/44.1 + HAL + calls kept, nav policy + music curve only over known-md5 factory files, slider left to
  the user, no 7862 libs). All checked by an installer simulation in WSL on the firmware trees, not on a unit.
  On the new 7862 unit: install, reboot, flag 1, DAC with both values. 8581: only with a tester.
- 26.10 BitPerfect Control v0.1 in the module (`97bb76f` app, `6867601` priv-app + `common/bp_ctl.sh`): status,
  USB DAC, Modern + Hyper styles, support badge; emulator only (owner's AVD `emulator-5554`, Android 11, no root).
  Next: navigators service, mic/AEC/NR per mode (TODO §3).
- 25.10 survey tool v1.4 (`e0d4559`): mic check — source, HAL mode, on 8581 HAL dumps before/after NR
  (`media.dump.switch=0xe800` via the mmi.audio.ctrl FIFO, ~10 s, restored). For 8581 testers first.
- 23.10 v5.6.1 on the bench and released (policy check polls `58d9759`, QF/MG gate, updateJson). Owner to
  confirm a SIM call (echo gone?).
- Testers: BD37xxx survey (24/48 into the SC2730 DAC not yet seen on a BD unit); engine hum through the SIM
  50 Hz cutoff (in a car); navigator reports.
- Owner's «strange navigator» (MapFactor, was installing maps and loading the disk 15.10): watch logcat
  (focus, AudioTrack, getOutput) when he says it is ready.
- SIM: echo cancelling leaks the ends of the far end's phrases a little — owner: «Точну підстройку зробимо в програмі».

## 📋 Next — order from the owner (15.10), details in `.agents/TODO.md`
1. Testers: feedback and logs on v5.6/v5.6.1 (BD37xxx, navigators, engine hum) — the open items above.
2. UIS8581: reduced profile done (25.10); next only with a tester — mic in /data audio_para (TODO §2).
3. Then BitPerfect Control: per-mode mic, SIM AEC fine-tuning; the AEC reference always moves with the mic.
4. EQ for wDSP (plan #1703, ResonanceFX C++ core idea, owner 19.10) — details in `.agents/TODO.md` §4.
