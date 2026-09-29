# What BitPerfect can actually control on this platform

The register the control app is built from. Asked for by the owner, 30.09.2026: *«зроби список того
чим ми можемо (не всім варто) керувати на платформі в бітперфект»* — so every row carries a
recommendation, and the owner decides.

Provenance: 🔬 read in code · 📻 measured on the wire · 🧩 inferred · ❓ unverified.
Platform detail lives in the `qf-platform` skill, not here.

---

## The three mechanisms, and what each costs

| # | mechanism | how it applies | cost |
|---|---|---|---|
| **A** | edit the XML in `/data/vendor/local/media/`, delete the compiled blob | on the next `audioserver` start | one restart — 📻 safe, see below |
| **B** | FIFO `/data/vendor/local/media/mmi.audio.ctrl` | **immediately, no restart** | none |
| **C** | overlay a file in `/vendor/etc` through Magisk | reboot | 🔴 a reboot, and it is the `/vendor` overlay that hangs UIS8581 |

🔬 The HAL reads `/data` **before** `/vendor` (`parse_audio_config()` @ `0x35b08`,
`init_sprd_xml()` @ `0x30b64`), and falls back to `/vendor` if the `/data` copy is empty or broken —
so a bad file there is ignored, not fatal. 📻 A missing blob is recompiled from XML at
`audioserver` start; a present one is left alone (verified 27.09 and again 30.09).

✅ 📻 **Mechanism A is cheap.** Restarting `audioserver` was measured on 30.09 idle and under live
playback: the stream is reopened with a new `owner_pid`, `hw_ptr` keeps advancing, audio stays
audible, and `sys.media.vol` / `sys.current.vol.type` survive. ⚠️ The after-sleep case is untested.

🔴 **Everything below needs entry to `/data/vendor/local/media`, which is
`drwxrwx--- audioserver system`.** Root, `android.uid.system`, or a proxy — and SELinux may still
refuse. ❓ Untested, and it decides the app's whole shape.

---

## 1. Microphone — the group with the clearest value

Per mode, in the 730-byte record (60 modes; offset = `24 + mode × 730 + field`).

| what | where | mech | worth exposing? |
|---|---|---|---|
| **AEC on/off, live** | `sprd_aec_on=0\|1` | **B** | ✅ **yes** — instant, reversible, and the single most useful switch for anyone recording |
| AEC depth | `aec_switch +0x08`, `aec_enable +0x60`, `pdelay +0x62`, `fir_taps +0x68`, `aec_ref_delay +0x86`, `aec_ul_delay +0x88` | A | 🟡 advanced screen only — wrong values make echo worse, not better |
| **noise suppression** | `ul_nr_modu1..3_switch +0x9a..+0x9e`, `ul_min_psne +0xa0`, `ul_max_psne +0xa2`, `ul_ns_factor +0xa6`, `ul_ns_limit +0xaa` | A | ✅ **yes, as one switch plus a coarse strength** — "unprocessed microphone" is the whole point of v5.4 |
| **microphone digital gain** | `ul_dgain_volume1..15 +0xe2..+0xfe` | A | ✅ **yes** — the owner asked for this by name ("підсилення мікрофона в різних режимах") |
| microphone analog gain | `codec.xml` `adcl/adcr_capture_volume +0x04/+0x08` (0..7 = +0..+21 dB); `audio_pga.xml` `VBC ADC2 DG Set` | A | 🟡 expose the coarse 0..7 only, and only next to a level meter |
| microphone EQ | `ul_EQ_switch +0x0a`, bass `+0x0c..+0x12`, treble `+0x14..+0x1a`, FIR `ul_fir_eq_coef00..32 +0x1e..+0x5e` | A | 🔴 **no** — 33 FIR coefficients is not a control, it is a preset. Ship presets, not sliders |
| BT headset NR | `bt_headset_nrec=0\|1` | **B** | ✅ yes, it is one switch |
| sidetone | `Loopback_gain +0x26a` | A | 🟡 only if calls need it — ask the calling line |

## 2. Playback

| what | where | mech | worth exposing? |
|---|---|---|---|
| playback digital gain | `audio_pga.xml` `VBC_DAC0_DG/volume0` | A | 🔴 **no.** 🔴 The owner settled this: *«це вивірене значення… справжнє значення на яке реагує HAL 0-63, 32 рівно половина»*. Touching it is how rasp gets chased in the wrong place |
| `dl_dgain_volume1..15` | `+0x244..+0x260` | A | 🟡 read-only display; changing it overlaps the volume axis, which is wDSP's |
| DRC on music | `dsp_vbc.xml` `Music/<device>/Playback/st_control_0` | A | 🔴 **no — factory, leave alone.** Marked untouched in the platform notes for a reason |
| `FM_WITH_DSP` | FIFO | **B** | 🟡 diagnostic switch, hide behind the advanced screen |

## 3. Routing and policy — ours by the contract

| what | where | mech | worth exposing? |
|---|---|---|---|
| bit depth / rate on the wire | `primary_audio_policy_configuration.xml` | C | 🟡 **as a named profile, never as raw fields.** 📻 v5.4 rasped because 16-bit was added while the bus held `WD_24BIT` |
| which usage lands on which stream | `audio_policy_engine_product_strategies.xml` | C | 🔴 **no.** This is where the navigation and assistant behaviour is decided; it belongs in the module's release, reviewed, not in a live editor |
| volume-group curves | `audio_policy_engine_stream_volumes.xml` | C | 🔴 no — same reason, and it borders the volume axis |
| the four `qf_audio_route_*` files | `/vendor/etc` | C | 🔴 no — the HAL picks one from two flags by itself; a module must not fight it |
| navigator whitelist | `/system/config/NaviApp.ini` | C | 🟡 **read-only view, with a warning.** 🔬 The list is cached once per process, so editing it live changes nothing until a reboot |

## 4. Diagnostics — read, do not write

| what | where | worth exposing? |
|---|---|---|
| which payload is installed | `module.prop` | ✅ **yes, and it is currently broken** — two different payloads answer `versionCode 504`. Fix before anything else is believed |
| the live audio path | `/proc/asound/card0/pcm*/sub0/status`, `dumpsys media.audio_flinger` | ✅ yes — "is the path alive" is the question every other line asks us |
| per-source volume and current source | `sys.*.vol`, `sys.current.vol.type` | ✅ yes, **read-only**. Writing is wDSP's axis |
| custom policies present? | `NoiseSuppressor.isAvailable()` | ✅ yes — 📻 false on stock, true with the module, no root and no permission needed |
| live tuning server | `AudioTester_enable=1` → DIAG on port 9997 | 🟡 advanced only; this is the factory PC tuner's own channel |
| `agdsp_reboot` | FIFO | 🟡 advanced; useful when a parameter write does not take |

---

## What this adds up to

**Expose by default (8 controls):** AEC on/off · noise suppression on/off + coarse strength ·
microphone digital gain per mode · BT headset NR · installed-payload readout · audio-path health ·
per-source volume readout · custom-policies indicator.

**Behind an advanced screen:** AEC depth, analog mic gain, sidetone, `FM_WITH_DSP`, the tuning
server, `agdsp_reboot`.

**Do not expose:** playback digital gain, music DRC, product strategies, volume curves, route files,
microphone EQ coefficients.

🔑 The shape that follows: **presets, not sliders, wherever a wrong value is worse than the default**
— and every screen says which mechanism it used, because A costs a restart, B costs nothing, and C
costs a reboot. A person who cannot see that difference will blame the app for the platform.
