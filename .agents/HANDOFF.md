# Slice — 15.10.2026 ~21:25, session `3827b401` (Claude): BD37xxx compatibility, module rebuilt from empty

**Owner's brief:** NR and AEC for SIM/BT calls, a clean mic for wDSP/AI. BitPerfect is mine; I run the room
`bitperfect-control-qfphone-rokoai`. Announce adb on the board only when another line is on the bench. No sound at
night without permission.

**Repo:** `v5.4-repaired`, pushed up to `36dd787` (15.10). The owner pushes.
Key: `5aea177` one output on PCM 3; `906a42b` CVS Handset = Handsfree (SIM echo); `e95d013` call mic VBC ADC2/ADC3
18 → 7 (≈ +13 dB); `59f14b6` UnprocessRecord without DP; `bb856b0` normal record ADC0 DG → 0 (BT mic louder);
`5a845b8` cutoff_tx Handset 0x64 → 0x32 (SIM bass back).

**Bench `192.168.1.138:9876`** (address moves — scan 9876): BitPerfect **v5.5.17**,
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
0. **VoIP calls** fixed 14.10 (`0a2f7e5` no sprd_voip_start, `fece07a` no Unisoc AEC, `c8efacb` louder curve).
   📻 15.10 WhatsApp: owner «ватсапп прекрасно» — closed.
- ✅ Guard (`77115bd`, `70a9d37`, v5.5.16): `/data/adb/post-fs-data.d/bitperfect_guard.sh` — disabled/removed →
  car.config music_volume from backup, AGDSP blobs dropped, `sys.bitperfect.enabled=0`; enabled again → blobs
  dropped + pin 15. 📻 15.10 bench, all on the same boot: disable → 9, 16-bit, owner «не хрипить»; enable → 15, 24-bit.
- ✅ BD37xxx (`712d50c`, v5.5.17): vendor/etc built from empty — shared files in `common/`, profiles keep only
  `audio_pcm.xml` + routes; BD now has the BU policy (same mic). BD output is 24/48 into the SC2730 DAC by factory
  design (10-BITPERFECT-MODULE.md). ❓ Not yet on a BD unit — needs a tester's survey/log.
1. **BitPerfect Control:** live per-mode mic editing from the defaults above; the AEC reference always moves with the mic.
   📻 15.10 SIM: echo cancelling leaks the ends of the far end's phrases a little («практично не заважає»); owner:
   «Точну підстройку зробимо в програмі». SIM and BT otherwise «все добре».
2. EQ for wDSP — plan in #1703 (DynamicsProcessing on the player session, not session 0); waiting for their prototype.
- wDSP call-volume memory — fixed on their side (`698830f`, #1709), not yet confirmed by a live call.

## 📋 Next
SystemUI Notification Centre button — `QF_SystemUI_Mod` slice (blocked by Unisoc autolaunch on their app, #1720).
BT dialer wishes (its slice): BT-music icon, metadata in «BT speaker» mode, cover art; 8581.
