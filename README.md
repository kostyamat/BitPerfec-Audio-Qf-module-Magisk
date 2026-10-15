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

🔴 **Not for UIS8581 units.** Its audio HAL and libraries are different and the module has never run on
one. The installer stops on any platform other than UIS7862 (`ums512`); it only saves the factory
snapshot, which you are welcome to send if you want to help with support.

## What it changes

- **Playback:** one 24-bit 48 kHz output, Android at unity gain (no digital attenuation before the
  sound processor), navigation ducking, louder VoIP calls on the speaker.
- **Calls:** SIM calls with handsfree echo cancellation and microphone headroom; Bluetooth calls with
  a louder microphone; Telegram / WhatsApp calls fixed (the factory VoIP record mode loops the input).
  The car-settings microphone sliders trim the level down from there.
- **Microphone for apps:** a raw, unprocessed input for DSP and voice apps (wDSP, assistants).
- Everything is overlaid by Magisk; no system partition is ever written.

## Install, disable, remove

Install the zip in Magisk and reboot. The installer saves a snapshot of your unit's factory audio state
to `/sdcard/QF_audio_survey/` before it changes anything — it stays on your unit unless you send it.

Disabling or removing the module in Magisk is safe: a small guard script
(`/data/adb/post-fs-data.d/bitperfect_guard.sh`) restores the factory default volume and audio
parameters on the next boot, so the factory path does not play at full scale. Removing the module also
removes the guard.

## Feedback — what to send

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
