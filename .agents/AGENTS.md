# BitPerfect Control — rules in force

## What this project is

Two things under one name, and they must not be confused:

| | what | where |
|---|---|---|
| **the module** | `BitPerfect.module` — a Magisk module that radically changes the audio path of the QF/K706 platform | `D:\My_K706_Magisk_Modules\BitPerfect2\`, its own git repo, remote `git@github.com:kostyamat/BitPerfec-Audio-Qf-module-Magisk.git`, branch `v5.4-repaired` |
| **the app** | `com.radiorubka.bitperfect` — a live editor for the platform's AGDSP parameters: filters on and off, microphone gain per mode, applied by restarting `audioserver` | this repository |

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
