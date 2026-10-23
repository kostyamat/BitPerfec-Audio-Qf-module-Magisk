# BitPerfect — changelog

🔴 **QF / K706 on UIS7862 only — NOT for UIS8581, NOT for any firmware other than QF / MG.**
Support: https://t.me/kostyamat_dev/3

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
