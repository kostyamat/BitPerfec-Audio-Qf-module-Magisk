# BitPerfect — changelog

## v5.6 (October 2026)

🔴 **UIS7862 only. Not for UIS8581** — the installer refuses any other platform and changes nothing.

Compared with v5.4:

**Calls**
- SIM calls: handsfree echo cancellation, microphone with headroom (about +13 dB), the bass of the
  handset path back.
- Bluetooth calls: louder microphone.
- Telegram / WhatsApp calls work: the factory VoIP record mode looped the microphone input (stutter,
  crackle, silence on the far end); it is no longer switched on, and the apps use their own echo
  cancelling. VoIP calls are louder on the speaker at mid volume.

**Microphone**
- Raw, unprocessed input for DSP and voice apps (wDSP, assistants); voice recognition input without
  echo cancelling or noise suppression.
- Headroom in every mode: the car-settings microphone sliders trim the level down without clipping.

**Playback**
- One 24-bit / 48 kHz output; the second output on the same PCM (`pcmC0D3p busy`, silent TTS) is gone.

**Hardware**
- BD37xxx (analogue) units: the same 24/48 path into the SoC DAC and the same microphone setup as
  BU32107 units. 🧪 Not yet confirmed on a BD unit — reports wanted.
- The installer builds the audio configuration for the detected hardware from scratch; nothing of the
  other variant is left behind.

**Disable / remove**
- A guard script restores the factory default volume and audio parameters when the module is disabled
  or removed (before, a disabled module left the factory path at full scale — heavy distortion).

**Diagnostics**
- `tools/QF_audio_survey.v1.3.zip`: a read-only report module that recognises any navigator and records
  what happens while it speaks. See README → Feedback.
