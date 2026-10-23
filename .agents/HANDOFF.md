# Slice — 15.10.2026 ~23:20, session `3827b401` (Claude): v5.6 released, waiting for testers

**Owner's brief:** NR and AEC for SIM/BT calls, a clean mic for wDSP/AI. BitPerfect is mine; I run the room
`bitperfect-control-qfphone-rokoai`. Announce adb on the board only when another line is on the bench. No sound at
night without permission. Push / release only on the owner's order (`.agents/RELEASE.md`).

## 🔴 From the wDSP line (22.10.2026): wDSP's package changed

The owner renamed wDSP to **wDSP Pro, package `com.communityofdevs.wdsp_pro`** (wDSP `bdb486f`); the old
`com.radiorubka.wdsp` may still be installed alongside. BitPerfect code does not name wDSP's package (checked:
only `.agents/AGENTS.md` dependencies and the contracts `C:\APPS_Contacts\wDSP--BitPerfect\*`). If any module
script, whitelist or policy overlay ever lists wDSP by package, add the new one.

**Repo:** `v5.4-repaired` (GitHub default branch since 16.10), pushed 15.10, 4 doc commits local — push on order; GitHub release **v5.6** (tag on `46507cd`, zip from `5144c01`).
Forum posts (4PDA ru, XDA en) and the annotation: `.agents/release/`. Support group https://t.me/kostyamat_dev/3.

**Bench `192.168.1.138:9876`** (address moves — scan 9876): BitPerfect **v5.6**, calling module v3.8.4, BT dialer
v9 (its session), patched QF Framework and SystemUI (their own sessions now).

## Mic defaults (📻 13.10; owner: «дефолти ми вже знаємо», the user tunes the rest)
- Codec ADCL/ADCR 0..7 = car-settings slider, ≈ 5–6 dB/step at the top; VBC DG is inverted (0 = max).
  Phone tone at full volume, slider 7: peak ≈ −12 dBFS — ≈ 12 dB headroom.
- SIM call 7/7 (mic ADC2 = AEC reference ADC3): no echo; 4/4 — echo; reference apart from the mic — squeaks:
  **move them together only**. DRC_tx tried — «крошиться», reverted.

## Done in v5.6 (details: README «What changed since v4.18», 10-BITPERFECT-MODULE.md)
VoIP (`0a2f7e5` no sprd_voip_start, `fece07a` no Unisoc AEC, `c8efacb` louder curve) — Telegram «люкс», WhatsApp
«прекрасно». Guard on disable/remove (`77115bd`). vendor/etc from empty, BD = BU policy (`712d50c`). Platform gate
UIS7862 only (`dbf20ae`). Survey tool v1.3 catches any navigator (`a31c3d2`; Waze takes no audio focus).

## ⏳ Waiting / open
- 23.10 **v5.6.1 on the bench** (zip from the `release:` commit), reboot OK: flag 1 at +25 s, policies, WD_24BIT,
  default.volume 15. In it: policy check polls (`58d9759`, was flag 0 on 4/10 boots → SIM echo), installer
  whitelist QF*/MG* (`74ce953`/`8e5f2f5`, after a Topway brick), Magisk `updateJson` (`3fd5cf3`). Not pushed.
  Publish on order: push, gh_release v5.6.1, THEN update.json → v5.6.1 + push (RELEASE.md). Owner to confirm a SIM call.
- ❓ `/great/protect_dir/car.config` lost its `music_volume` line on 18.10 between 19:55 and 19:59 (107 entries now,
  backup has it) — not our install; the 0 dB pin still holds via `persist.qf.arm.default.volume`. Who rewrote it?
- Testers: BD37xxx survey (24/48 into the SC2730 DAC not yet seen on a BD unit); engine hum through the SIM
  50 Hz cutoff (in a car); navigator reports.
- Owner's «strange navigator» (MapFactor, was installing maps and loading the disk 15.10): watch logcat
  (focus, AudioTrack, getOutput) when he says it is ready.
- SIM: echo cancelling leaks the ends of the far end's phrases a little — owner: «Точну підстройку зробимо в програмі».

## 📋 Next — order from the owner (15.10), details in `.agents/TODO.md`
1. Testers: feedback and logs on v5.6 (BD37xxx, navigators, engine hum) — the open items above.
2. UIS8581 adaptation: 44.1/16 profile, AGDSP params into /data instead of the /vendor overlay; needs a 8581 tester.
3. Then BitPerfect Control: per-mode mic, SIM AEC fine-tuning; the AEC reference always moves with the mic.
4. **EQ for wDSP (план #1703)** — нотація від власника (19.10): розглянути можливе впровадження C++ ядра з https://github.com/xeloria/ResonanceFX як гібридного програмно-апаратного еквалайзера.
   - *Ідея:* компенсувати обмежену дискретність і широку добротність BU32107 (вузьке вирізання резонансів/провалів салону через biquad notch у `double`, розширення стереобази M/S, mono bass < 90 Гц).
   - *Зауваження Antigravity:* брати виключно чисту C++ математику (`Biquad.h`, `Spatial.h`), без Magisk-обгортки та важких ефектів ResonanceFX, щоб гарантовано зберегти 24-bit 48kHz I2S тракт BitPerfect v5.6.

