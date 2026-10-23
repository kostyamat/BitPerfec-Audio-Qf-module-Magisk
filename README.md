<p align="center">
  <a href="https://www.paypal.com/paypalme/kostyamat">
    <img src="https://thumbs.dreamstime.com/b/cute-kawaii-coffee-mug-character-smiling-steam-isolated-white-adorable-cartoon-happy-face-decorative-lace-pattern-401912575.jpg" alt="Buy me a coffee" width="200"/>
    <br>
    <strong>If you found my work helpful, buy me a coffee! It keeps me motivated ☕</strong>
  </a>
</p>

# BitPerfect — audio engine for QF / Roco K706 head units

A Magisk module for Android head units on the **Unisoc UIS7862** platform (QF, Roco K706 and their
clones). It takes the sound from any player at full quality, with no attenuation and no change to the
frequency response, and hands it to the head unit's sound processor at **24 bit / 48 kHz, 0 dB**.
Volume and effects stay where they belong: in the sound processor.

⚖️ **Legal status / Right to Repair:** [LEGAL.md](LEGAL.md) (Ukrainian)

## Supported hardware

The installer reads the MCU code and picks the profile by itself.

| unit | output path | status |
|---|---|---|
| UIS7862 + **ROHM BU32107** | digital I2S, 24/48 | ✅ tested on the developer's unit |
| UIS7862 + **ROHM BD37xxx** | the SoC's own DAC (analogue), 24/48 by factory design | 🧪 needs reports |
| **UIS8581** | — | ❌ **not supported** — the installer refuses it and changes nothing |
| **Topway** and any other non-QF firmware on UIS7862 | — | ❌ **not supported** — the installer refuses it; installing it there needed a reflash |

🔴 **Not for UIS8581 units.** Its audio HAL and libraries are different and the module has never run on
one. The installer stops on any platform other than UIS7862 (`ums512`); it only saves the factory
snapshot, which you are welcome to send if you want to help with support.

🔴 **QF firmware (or its MG clone) only.** Other vendors ship UIS7862 too — Topway among them — with
their own audio HAL and libraries; the module's patched files leave such a unit unable to boot. The
installer checks the QF MCU string / hardware revision (`QF…` or `MG…`) and refuses anything else.

## What it changes

- **Playback:** one 24-bit 48 kHz output, Android at unity gain (no digital attenuation before the
  sound processor), navigation ducking, louder VoIP calls on the speaker.
- **Calls:** SIM calls with handsfree echo cancellation and microphone headroom; Bluetooth calls with
  a louder microphone; Telegram / WhatsApp calls fixed (the factory VoIP record mode loops the input).
  The car-settings microphone sliders trim the level down from there.
- **Microphone for apps:** a raw, unprocessed input for DSP and voice apps (wDSP, assistants).
- Everything is overlaid by Magisk; no system partition is ever written.

## What changed since the classic v4.18

v4.18 was a single BU32107 profile. Since then:

**Hardware detection**
- The sound processor and the output path are read from the MCU code at the right positions (v4.x read
  the control-panel digits, so every BD37xxx unit got the BU32107 I2S profile — the "digital rasp").
- Two profiles: BU32107 (I2S) and BD37xxx (the SoC's DAC). The audio configuration is built from scratch
  for the detected hardware; no file of the other variant is left behind, also after an upgrade.
- 🔴 UIS7862 only: the installer refuses UIS8581 and any other platform.

**Playback**
- One 24-bit / 48 kHz output: the second output on the same PCM made `pcmC0D3p busy`, re-routed the bus
  under music and silenced TTS — gone.
- 0 dB that survives: the platform default volume is pinned at unity where the platform keeps it
  (`car.config`), not only in a property it rewrites at boot. The incoming-call ringtone is no longer
  played 18 dB down.
- The CarSettings start-up volume slider is never touched (v5.0/v5.1 overwrote it).
- The 24-bit I2S width is enforced only where an I2S bus exists, at boot and after sleep.
- After boot and after sleep the MCU gets the level of the current source.

**Navigation**
- Navigators that announce themselves as "assistant" are treated as navigation, not music.
- Google TTS prompts duck the music like navigation prompts.

**Calls**
- SIM: handsfree echo cancellation on the handset path, microphone ≈ +13 dB with the echo reference moved
  with it, the handset bass back.
- Bluetooth: louder microphone; the call stays at 0 dB, without a forced communication mode.
- Telegram / WhatsApp: the Unisoc VoIP record mode looped the microphone input (stutter, crackle,
  silence) — it is no longer switched on, and the apps use their own echo cancelling; VoIP is louder on
  the speaker at mid volume.
- The calling module (`qf_cellular_calling_master`) works only on top of BitPerfect, which confirms
  itself each boot (`sys.bitperfect.enabled=1`) once the policies are loaded and the audio path is alive.

**Microphone**
- Raw, unprocessed input for DSP apps (wDSP), voice recognition without echo cancelling or noise
  suppression (assistants); the vendor override that forced every app to the plain microphone is patched
  for these two sources.
- Headroom in every mode: the car-settings microphone sliders trim the level down without clipping.

**Reliability**
- The boot watchdog checks that the audio path really runs (a stream stranded after the platform's own
  audioserver restart), not only that the policies are loaded.
- Disable / remove is safe: a guard script restores the factory volume and audio parameters on the same
  boot, and redoes ours when the module is enabled again.
- On install a snapshot of the factory audio state is saved to `/sdcard/QF_audio_survey/`.

## Install, disable, remove

Install the zip in Magisk and reboot. The installer saves a snapshot of your unit's factory audio state
to `/sdcard/QF_audio_survey/` before it changes anything — it stays on your unit unless you send it.

**Updates:** from the next release on, Magisk itself shows an **Update** button for BitPerfect when a
new release is published here (`updateJson` in `module.prop`, changelog in [CHANGELOG.md](CHANGELOG.md)).

Disabling or removing the module in Magisk is safe: a small guard script
(`/data/adb/post-fs-data.d/bitperfect_guard.sh`) restores the factory default volume and audio
parameters on the next boot, so the factory path does not play at full scale. Removing the module also
removes the guard.

## Feedback — what to send

💬 **Support group (Telegram):** https://t.me/kostyamat_dev/3 — reports go there.

"It does not work" cannot be fixed without data. Please send:

1. `/sdcard/QF_audio_survey/` — the factory snapshot the installer made;
2. `/data/adb/BitPerfect.log`;
3. **for navigation-prompt problems (too quiet, cut off, music not ducked), for BD37xxx units, and for
   any other sound problem:** a live report from the diagnostic tool below, taken with
   BitPerfect installed and with the navigator you actually use.

### Diagnostic tool: `tools/QF_audio_survey.v1.3.zip`

A read-only Magisk module: it changes nothing, plays nothing and sends nothing by itself. It writes a
report to `/sdcard/QF_audio_survey/`: audio configuration, mixer state, every audio stream, what format
and gain Android feeds the HAL, the installed navigators, and — the main part — what happens while a
navigator speaks: which app it is, how it plays (usage, audio focus) and every volume at that moment.
It recognises any navigator, also those that take no audio focus or speak as an "assistant".

1. Install it in Magisk (BitPerfect stays installed) and reboot.
2. Play music or radio, start your navigator and let it speak **once**.
3. In Magisk the tool's line shows `DONE` (or `DONE (partial)` after 7 minutes without a prompt).
4. Zip `/sdcard/QF_audio_survey/` and send it. Then remove the tool.

## Repository

The module payload is `META-INF`, `common`, `profiles`, `system`, `customize.sh`, `module.prop`,
`service.sh`. `control-app/` is the companion app (work in progress) and `.agents/` holds the
development notes — neither is part of the module.

## Support the developer

🏆 If you appreciate my work and want to buy me coffee/beer - your choice, or purchase licenses for some paid products that I offer, here is a link to some of my payment details.
👇

**Crypto**
- TRC-20 (Tron): `TCSvCEyX1Zxb9E97oTpxHsBCLiDZLPTvzk`
- TON (Telegram wallet): `UQCqracCOo_DEwVWQjPVYkKak-gSZx1TXQOxICi_9frpdr5j`

**PayPal** (Please send your PayPal payment via 'Friends and Family'. If you select 'Goods and Services', PayPal charges a large fee and forces me to create shipping information, which delays the process.)
https://www.paypal.com/paypalme/kostyamat

**Revolut**
https://revolut.me/kostyamat
