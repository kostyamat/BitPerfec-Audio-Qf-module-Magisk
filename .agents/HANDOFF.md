# Slice — 14.10.2026 ~17:10, session `3827b401` (Claude): call audio done, defaults known

**Owner's brief:** NR and AEC for SIM/BT calls, a clean mic for wDSP/AI. BitPerfect is mine; I run the room
`bitperfect-control-qfphone-rokoai`. Announce adb on the board only when another line is on the bench. No sound at
night without permission.

**Repo:** `v5.4-repaired`, pushed up to `3c65e41` (06.10); the rest is local. The owner pushes.
Key: `5aea177` one output on PCM 3; `906a42b` CVS Handset = Handsfree (SIM echo); `e95d013` call mic VBC ADC2/ADC3
18 → 7 (≈ +13 dB); `59f14b6` UnprocessRecord without DP; `bb856b0` normal record ADC0 DG → 0 (BT mic louder);
`5a845b8` cutoff_tx Handset 0x64 → 0x32 (SIM bass back).

**Bench `192.168.1.138:9876`** (address moves — scan 9876): BitPerfect **v5.5.11** (= v5.5.9 by audio files),
calling module v3.8.4, BT dialer v8d, patched QF Framework (`QF_Framework_Mod`), our SystemUI (`QF_SystemUI_Mod`).
Input level of source 9: `/data/local/tmp/tonetest.sh <s>`; `MicMeter` (`mm.dex`) only for sources 1/6 (9 is silenced).

## Mic defaults (📻 13.10; owner: «дефолти ми вже знаємо», the user tunes the rest)
- Hardware: codec ADCL/ADCR 0..7 = car-settings slider, ≈ 5–6 dB/step at the top; VBC DG is inverted (0 = max).
  Phone tone at full volume, slider 7: peak ≈ −12 dBFS — no clipping, ≈ 12 dB headroom.
- SIM call 7/7 (mic ADC2 = AEC reference ADC3): «луни немає, чути нормально». 4/4 — echo. Reference apart from the
  mic (4/10) — squeaks: **move them together only**.
- SIM now «схожий на звук БТ», «басів більше, луни немає». DRC_tx tried (v5.5.10) — «крошиться», reverted `8db467a`.
  ❓ In the car: engine hum through the 50 Hz cutoff (owner: NR/EQ «заточені на шум траси… мотор максимально глушиться»).

## ⏳ Open
0. **Telegram calls: mic stutters/crackles/silent** (voice messages fine). 📻 14.10 log (`tgcall.sh` on the bench):
   app opens source 7, but `APM getInputForDevice` already gets **source 1** (remap 7→1 happens before APM — not in
   `getInputForAttr`, not in `AudioRecord::set` log path; still unknown where). HAL opens the input as VOIP_RECORD (7,
   because `sprd_voip_start=true` after setMode 3) but `audio_add_input`/`in_read` compute NORMAL_RECORD (11) for
   source 1 → standby + reopen every ~240 ms (144× in 35 s), pop-mute each time. Output stays MM_NORMAL (no VoIP
   pcm). Next: find the 7→1 remap (APS/AudioFlinger/framework) or byte-patch `in_read`; owner decides.
1. **BitPerfect Control:** live per-mode mic editing from the defaults above; the AEC reference always moves with the mic.
2. EQ for wDSP — plan in #1703 (DynamicsProcessing on the player session, not session 0); waiting for their prototype.
- wDSP call-volume memory — fixed on their side (`698830f`, #1709), not yet confirmed by a live call.

## 📋 Next
SystemUI Notification Centre button — `QF_SystemUI_Mod` slice (blocked by Unisoc autolaunch on their app, #1720).
BT dialer wishes (its slice): BT-music icon, metadata in «BT speaker» mode, cover art; 8581.
