# Microphone control in BitPerfect Control (UIS7862) — the plan and the field map

Owner, 01.11.2026: «берись за мікрофон» — per-channel mic gain, AEC / NR on/off, AEC auto-calibration per mode
(«окремо для кожного режиму дзвінка чи хто там ще єхо заглушення бере»), a user NR curve with presets («щоб
людина могла б собі підлаштувати криву заглушення NR, та зберегти пресети»). Queue: `TODO.md` §3.

Provenance: 🔬 read in the shipped XML / firmware · 📻 measured · 🧩 inferred · ❓ unverified.

## 1. Where each channel's sound is processed

The three AGDSP files share one mode map (🔬 `common/system/vendor/etc/audio_params/sprd/`, 60 modes):
`Handset` 0–6, `Handsfree` 7–13, `Headset4P` 14–20, `Headset3P` 21–27, `BTHS` 28–34, `BTHSNREC` 35–41,
`TypeC_Digital` 42–48, `Hac` 49–55, `Loopback` 56–59; inside each group `NB1 NB2 WB1 WB2 SWB1 FB1 VOIP1`.
(`audio_structure.xml` also lists a `UHB` in `Handsfree`/`Headset4P`/`BTHS` sharing the next group's index ❓.)

| channel (what the user sees) | modes | files |
|---|---|---|
| SIM call (car speakers + cabin mic) | `Handsfree` NB1…FB1 (7–12) 🧩 the HAL picks NB/WB by codec | `cvs.xml`, `audio_structure.xml`, `audio_pga.xml` |
| VoIP (Telegram, WhatsApp) | `Handsfree/VOIP1` (13) 🧩 | same |
| BT call | `BTHS` / `BTHSNREC` (28–41) 🧩 — which one depends on the phone's NREC | same |
| Recording (wDSP, DVR, assistant) | `audio_pga.xml` `Music/Handsfree/Record` and `UnprocessRecord` 🔬 — no CVS on this path | `audio_pga.xml` |

## 2. The controls and their fields (per mode)

| control | field | notes |
|---|---|---|
| mic digital gain | `audio_pga.xml` `<mode>/VBC_ADC2_DG/volume0` (ours 0x07, factory 0x18) 🔬; `audio_structure.xml` `ul_dgain_volume1..15` (ours 0x1800) 🔬 | 🔴 the AEC reference ADC3 moves only together with the mic ADC2 (📻 13.10) |
| AEC on/off | `cvs.xml` `TX_MODUAL/AEC` (0x07 on, 0 off) 🔬 field; meaning of the bits ❓ | also live: FIFO `sprd_aec_on=0|1` (one switch for all modes) |
| echo tail | `cvs.xml` `AEC_ADF_FL` (0x33) 🧩 adaptive-filter length | calibration target |
| residual echo suppression | `cvs.xml` `TX_MODUAL/NES` + `NES_PARA1..9` (NLP gains/thresholds) 🔬 | |
| NR on/off | `cvs.xml` `TX_MODUAL/POS` (post filter) 🧩; `audio_structure.xml` `ul_nr_modu1..3_switch` 🔬 | |
| NR curve | `cvs.xml` `Tx_Mono_Post`: `NFloor`, `thr_cvs`, `thr_cvs_sub`, `sm_S0..2`, `sm_N0..2`, `alpha_S/N`, `Gain_limit`, `NF_fade`, `G_*` 🔬 | BitPerfect already ships its own curve in every mode (1475 fields differ from factory) |
| AGC | `audio_structure.xml` `ul_alc_*` 🔬 | 🔴 off by default — owner: «AGC тут не допомога а зло» |
| AEC delays | `audio_structure.xml` `aec_ref_delay +0x86`, `aec_ul_delay +0x88`, `pdelay +0x62`, `fir_taps +0x68` 🔬 (Gemini's map) | calibration target |

## 3. How a change is applied (mechanism A)

The HAL reads `/data/vendor/local/media/audio_params/sprd/<name>.xml` before `/vendor` and falls back to `/vendor`
when the `/data` copy is broken (🔬 `init_sprd_xml` @ 0x30b64). A missing compiled blob in
`/data/vendor/local/media/audio_params/` is rebuilt from XML at audioserver start (📻 27.09).
So: module XML (ours) + the user's overrides → `/data/.../sprd/<name>.xml`, delete the blob, restart audioserver.
`bp_guard.sh` must remove the `/data` copies too when the module is disabled.

User state: `/sdcard/BitPerfectAudio/mic.conf` — `channel field value` lines; presets — `mic.<name>.conf` beside it.
The module (`common/bp_mic.sh`, called from `bp_ctl.sh mic …`) is the only writer; the app only asks.

### Live tuning server — does not start (📻 stand 194, 01.11.2026)
`echo -n AudioTester_enable=1 > /data/vendor/local/media/mmi.audio.ctrl`: the HAL takes it
(`ext_contrtol_process:AudioTester_enable=1`, `start_audio_tunning_server enter/exit`) and then logs
`E audio_hw_tester: can not create tunning server thread`; no listener on 9997. SELinux is Permissive on this unit,
so it is not a denial. ❓ Why — reverse `start_audio_tunning_server` in `audio.primary.ums512.so`. Needed because
a call cannot survive an audioserver restart: in-call tuning / calibration must go live, not through XML.
`sprd_aec_on=0|1` through the same FIFO is the one live switch known to work 🔬 (not yet measured).

## 4. Order of work
1. Module engine: read the current value of a field per channel, write overrides into the `/data` copies, rebuild
   blobs, restart; `bp_ctl.sh mic get|set|reset`. Test on stand 194 with `dumpsys`/dumps, no sound at night.
2. App: card «Microphone» — channel tabs; gain slider (ADC2+ADC3 together), AEC and NR switches; reset to BitPerfect.
3. NR curve presets (gentle / BitPerfect / strong + user-saved).
4. AEC auto-calibration per channel (TODO §3): fader front + balance centre by MCU, sweep, correlation →
   `aec_ref_delay` / ref level / `AEC_ADF_FL`; afterwards ask the user to restore the fader in the EQ app.
   Only in the car, by day, with the owner's permission. Verified only by a real call.
