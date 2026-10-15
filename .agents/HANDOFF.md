# Slice — 15.10.2026 ~23:20, session `3827b401` (Claude): v5.6 released, waiting for testers

**Owner's brief:** NR and AEC for SIM/BT calls, a clean mic for wDSP/AI. BitPerfect is mine; I run the room
`bitperfect-control-qfphone-rokoai`. Announce adb on the board only when another line is on the bench. No sound at
night without permission. Push / release only on the owner's order (`.agents/RELEASE.md`).

**Repo:** `v5.4-repaired`, pushed 15.10; GitHub release **v5.6** (tag on `46507cd`, zip from `5144c01`).
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
- Testers: BD37xxx survey (24/48 into the SC2730 DAC not yet seen on a BD unit); engine hum through the SIM
  50 Hz cutoff (in a car); navigator reports.
- Owner's «strange navigator» (MapFactor, was installing maps and loading the disk 15.10): watch logcat
  (focus, AudioTrack, getOutput) when he says it is ready.
- SIM: echo cancelling leaks the ends of the far end's phrases a little — owner: «Точну підстройку зробимо в програмі».

## 📋 Next
1. **BitPerfect Control:** live per-mode mic editing from the defaults above, SIM AEC fine-tuning; the AEC
   reference always moves with the mic.
2. EQ for wDSP — plan #1703 (DynamicsProcessing on the player session); waiting for their prototype.
