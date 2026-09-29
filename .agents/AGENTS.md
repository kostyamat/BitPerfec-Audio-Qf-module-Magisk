# BitPerfect Control — rules in force

## 0. 🔴 The doctrine — every other rule here serves it

The owner, 30.09.2026, in his words:

> *«суть бітперфекта — ми забираємо з любого плеєра звук в максимальній якості, не допускаємо його
> ослаблення, присідання чи зміни АЧХ до виходу на BU32107, з асемплом/ресемплом до 24/48 (це
> максимум, що дозволяють штатні налаштування тактового генератора та мікросхеми на цьому апараті),
> регулювання звуку та ефекти суто на рівні BU32107. Вона для цього і існує.»*

What follows from it, and what every change is measured against:

1. **Nothing attenuates, compresses or shapes the signal before the chip.** No digital gain, no EQ,
   no dynamics in the Android path. Volume and effects belong to **BU32107**, which exists for that.
2. **24-bit / 48 kHz is the target**, up- or resampled to it. That is the ceiling the stock clock
   generator and the chips on this unit allow — not a preference.
3. **Output sits at 0 dB, always.** The owner: *«я хочу щоб флінжер видав на вихід на ДСП весь звук
   до останнього кванта»*. This is why `persist.qf.arm.default.volume=15` is pinned — see
   `qf-platform`, `09-NAVIGATION-AND-BITPERFECT.md` §13. 🔴 Removing that pin drops the base to the
   fallback 9 and leaves the digital path at −16 dB for good after the first navigation prompt.
4. **Special modes may deviate, briefly.** Calls, navigation and ducking are allowed to switch rate
   or depth while they last — preferably resampling back to 24/48. A transient, intentional
   attenuation is not a breach of the doctrine; a permanent one is.
5. **BD units are held to the same target.** Gemini confirms 24/48 on the DAC/CPU that carries
   BD37xxx over analogue — same conditions, the route simply is not I2S.

📻 **Verified on the bench 30.09.2026**, and this is the shape to keep:

```
HAL format: 0x4 (AUDIO_FORMAT_PCM_8_24_BIT)   on primary AND fast
Sample rate: 48000 Hz                          on both
VBC_IIS_MST_WIDTH_SET: WD_16BIT >WD_24BIT      24-bit selected on the bus
G db on the music track at index 15: 0         unity, nothing lost
```

⇒ Before any change to the audio path, ask: does it attenuate, resample away from 24/48, or move an
effect out of the chip? If yes, it is wrong here even when it sounds better.

---

## What this project is

Two things under one name, **in one repository** — the app ships inside the module, so they are
released together. The repo is public by intent; the owner, 30.09.2026: *«бітперфект — моя візитка»*.

```
BitPerfec-Audio-Qf-module-Magisk/        branch v5.4-repaired
├─ .agents/            these notes — they cover BOTH halves
├─ control-app/        the Android app, com.radiorubka.bitperfect
├─ META-INF/  common/  profiles/  system/    ┐
├─ customize.sh  module.prop                 │  the Magisk module payload
├─ service.sh  system.prop                   ┘
└─ README.md
```

| | what |
|---|---|
| **the module** | `BitPerfect.module` — a Magisk module that radically changes the audio path of the QF/K706 platform |
| **the app** | `com.radiorubka.bitperfect` — a live editor for the platform's AGDSP parameters: filters on and off, microphone gain per mode, applied by restarting `audioserver`. Delivered **inside the module**, in `priv-app`, because it needs `android.uid.system` |

🔴 **The release zip is assembled by hand and must contain exactly seven entries:** `META-INF`,
`common`, `profiles`, `system`, `customize.sh`, `module.prop`, `service.sh`. ⚠️ `.agents/` and
`control-app/` are **sources, not payload** — zipping the whole folder would ship them to every owner
and bloat the module. There is no build script yet; writing one is worth doing before the next
release, precisely so this cannot be got wrong by hand.

Both are led by one session. The owner, 29–30.09.2026: *«так, це ти і модуль твій»*.

🔴 **BitPerfect is load-bearing for the whole platform.** The owner: *«бітперфект це основний спосіб
вирівняти звучання… від нього залежить і дзвінки, і вдсп і радіо, і плеєр і ще маса майбутніх
проектів»*. A fault here does not look like a fault here — it surfaces as somebody else's bug.

## Build, install, verify

```bash
./gradlew :app:assembleDebug          # the app
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

- Debug builds only. R8 silently removes hidden-API calls, so a signed release does nothing while
  debug works.
- The module is not built by Gradle. Its installer is `customize.sh`; releases are zips in the
  module's own folder.
- 🔴 **After `adb install -r` services do not come back up by themselves.** The process shows in
  `pidof` while the service is dead and broadcasts go nowhere. Restart it explicitly.

## Bans

- 🔴 **Never mount a system partition rw and never write into `/system` or `/vendor` directly.** The
  module builds its own tree and Magisk overlays it. Owner's ruling, 30.09.2026.
- 🔴 **Evidence about the module comes from the wire, never from wDSP's analyser** — it sits on the
  same path and cannot witness it. Use `dumpsys media.audio_flinger`, `tinymix`,
  `/proc/asound/card0/pcm3p/sub0/status`, the HAL log.
- 🔇 **No sound at night without permission**, and when a ceiling is given it is set immediately
  before the test — it does not survive a reboot.
- Commit after every verified step; **push only on the owner's order**, and only from WSL.
- Do not grant permissions over adb.

## Traps that have already cost time here

- 🪤 **Byte deltas that equal the line count are CRLF, not content.** Normalise (`tr -d '\r'`)
  before diffing or comparing sizes of module files.
- 🪤 **After `adb reboot`, wait on `uptime`, not `sys.boot_completed`** — `adbd` outlives the request
  and the first poll reads the previous boot's `1`.
- 🪤 **`adb shell grep 'a\|b'` silently returns nothing** under MSYS. Use `MSYS_NO_PATHCONV=1` and
  verify an empty result with a second, simpler command before believing it.
- 🪤 **An unset `sys.*.vol` reads back as its `persist.sys.*_volume` default** on every call. That is
  the "volume reset itself" bug; there is no reset code.
- 🪤 **Volume is per source, not per Android stream**, and a write only reaches the MCU while its
  type matches `sys.current.vol.type`.

## Dependencies

| direction | who | contract |
|---|---|---|
| we own the audio policy; wDSP verifies and reports | **wDSP** (`com.radiorubka.wdsp`) | `C:\APPS_Contacts\wDSP--BitPerfect\AUDIO_PATH_AND_MODULE_CONTRACT.md` (mirror `wDSP\.agents\BITPERFECT_MODULE_CONTRACT.md`; edit the canon, then copy) |
| they order, we implement | **the calling line** — Gemini session `d739c765`, `DialerKM` + `qf_cellular_calling_master` | the same contract; the calling app is theirs, every audio policy under calls is ours |
| affected third party | **`kostyamat_fmradio`** | plays through the MCU channel past AudioFlinger, so a broken path can be inaudible to it |

🔴 wDSP owns the **volume level** (base plus the GALA offset). We own **routing**. Do not become a
second writer of level — one was cleared out of this path on 27.08 precisely to stop a race.
❓ Whether the app also owns muting has been put to the owner and is **not** answered.

## Where the knowledge is

Platform facts live in the `qf-platform` skill, never copied into this repo:
`10-BITPERFECT-MODULE.md` (the module itself, §7 routes, §12 AGDSP), `08-VOLUME-AND-SOURCES.md`,
`09-NAVIGATION-AND-BITPERFECT.md`, `05-AUDIO-PATH.md`, `02-MCU.md`. The live copy is
`wDSP\.agents\platform\` — anything added carries a provenance mark (🔬 read · 📻 measured ·
🧩 inferred · ❓ unverified).

The decompiled platform is in `D:\De-compiled\`. The UI style is the `automotive-hyper-ui` skill,
borrowed from the Gemini store (canon:
`C:\Users\kosty\.gemini\config\skills\automotive-hyper-ui\SKILL.md`).
