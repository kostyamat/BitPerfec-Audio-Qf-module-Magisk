# BitPerfect — changelog

🔴 **QF / K706 (or its MG clone) only. UIS7862: full module. UIS8581: reduced profile. Any other firmware: refused.**
Support: https://t.me/kostyamat_dev/3

## v5.7.5
Guide with pictures: docs/GUIDE.en.md · docs/GUIDE.uk.md
- BitPerfect Control, the settings app inside the module: what is playing and where, settings in tabs; 25 languages.
- USB DAC: Head unit / USB DAC switch works at once (no replug, no reboot); full scale from Android, level on the
  DAC's own control, optionally following the head unit's knob; DAC mode from its own format list; silent while the
  ignition is off (no more beeping from the sleep countdown).
- Call microphone (UIS7862) per channel — SIM, VoIP, Bluetooth: level, echo cancelling, noise reduction and its
  depth, named presets.
- Shared microphone: several apps record at once (a dashcam next to wDSP Pro); calls still take the microphone.
- Your own navigators, with how their prompts behave.
- UIS8581: reduced profile (navigation ducking, music curve, USB DAC); factory 16/44.1 output, HAL and calls kept —
  no tester report yet.
- Installer output and logs in English.

## v5.6.1
- Installer accepts QF firmware and its MG clone only and refuses everything else (a Topway install needed a reflash).
- Boot check of the audio policies waits for audioserver instead of one look at +2 s: the
  "BitPerfect enabled" flag no longer drops to 0 on some boots (calls lost echo cancelling).
- Updates from Magisk: the module now tells Magisk where its releases are.

## v5.6
- One 24-bit / 48 kHz output at 0 dB into the sound processor (BU32107 over I2S, BD37xxx through the SoC DAC).
- SIM calls with handsfree echo cancelling and a louder microphone; BT louder; Telegram / WhatsApp fixed.
- Raw microphone for DSP apps (wDSP); navigation prompts duck the music.
- Disable / remove restores the factory volume and audio parameters on the same boot.
