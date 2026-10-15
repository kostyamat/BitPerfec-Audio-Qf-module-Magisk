# Slice — 15.10.2026 ~21:10, session `3827b401` (Claude): disable/remove guard verified

**Owner's brief:** NR and AEC for SIM/BT calls, a clean mic for wDSP/AI. BitPerfect is mine; I run the room
`bitperfect-control-qfphone-rokoai`. Announce adb on the board only when another line is on the bench. No sound at
night without permission.

**Repo:** `v5.4-repaired`, pushed up to `3c65e41` (06.10); the rest is local. The owner pushes.
Key: `5aea177` one output on PCM 3; `906a42b` CVS Handset = Handsfree (SIM echo); `e95d013` call mic VBC ADC2/ADC3
18 → 7 (≈ +13 dB); `59f14b6` UnprocessRecord without DP; `bb856b0` normal record ADC0 DG → 0 (BT mic louder);
`5a845b8` cutoff_tx Handset 0x64 → 0x32 (SIM bass back).

**Bench `192.168.1.138:9876`** (address moves — scan 9876): BitPerfect **v5.5.16**,
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
0. **VoIP calls (Telegram)** — 📻 14.10. Cause: Unisoc `AudioPolicyManagerSPRD::startOutput` sends
   `sprd_voip_start=true` when STREAM_VOICE_CALL starts; in that mode the 7862 HAL loops standby/reopen on the
   input (VOIP_RECORD vs NORMAL_RECORD) whatever the source. Fixed `0a2f7e5` (lib64 libaudiopolicymanager, one `b`).
   Source 7 passthrough tried and reverted (`09ac926`). Unisoc AEC needs that mode → removed from audio_effects
   (`fece07a`), apps use their own AEC; WhatsApp «все чудово». Telegram: AEC works; «підсвистування» was
   at the louder level; voice_call SPEAKER curve raised (`c8efacb`, index 9: −18 → −6 dB). 📻 18:18 call at slider 7:
   owner «зв'язок ок»; volume «ок для мене». ⏳ WhatsApp 18:21: «між фразами шуми, ехо немає» (was «все чудово» on
   v5.5.12). Mic floor −36 dBFS; ringback reaches the mic at −5 dBFS. Next: owner calls WhatsApp with car-settings
   mic slider 5 (floor follows → lower VoIP record DG for good); if not — test Unisoc AEC back (`fece07a`) for NS.
- ✅ Guard (`77115bd`, `70a9d37`, v5.5.16): `/data/adb/post-fs-data.d/bitperfect_guard.sh` — disabled/removed →
  car.config music_volume from backup, AGDSP blobs dropped, `sys.bitperfect.enabled=0`; enabled again → blobs
  dropped + pin 15. 📻 15.10 bench, all on the same boot: disable → 9, 16-bit, owner «не хрипить»; enable → 15, 24-bit.
1. **BitPerfect Control:** live per-mode mic editing from the defaults above; the AEC reference always moves with the mic.
2. EQ for wDSP — plan in #1703 (DynamicsProcessing on the player session, not session 0); waiting for their prototype.
- wDSP call-volume memory — fixed on their side (`698830f`, #1709), not yet confirmed by a live call.

## 📋 Next
SystemUI Notification Centre button — `QF_SystemUI_Mod` slice (blocked by Unisoc autolaunch on their app, #1720).
BT dialer wishes (its slice): BT-music icon, metadata in «BT speaker» mode, cover art; 8581.
