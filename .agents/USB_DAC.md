# USB DAC — how Android drives it here, and what we change

Measured on stand 194 (UIS7862, PCM2704 `08bb:2704`), 01.11.2026, unless marked otherwise.

## 1. Connection: Android announces a DAC once
- 🔬📻 UsbAlsaManager → `AudioService.setWiredDeviceConnectionState(type, 1, "card=N;device=0;", "USB-Audio - <name>")`
  once, at plug-in. PCM2704 is typed `0x4000000` (USB_HEADSET). With `usb_dac=0` the policy has no USB module and
  refuses it; AudioService then forgets it, so after `usb_dac=1` + audioserver restart nobody announces it again.
- `authorized` 0→1 does not help: the kernel deconfigures without a bus disconnect, Android sees no event. A real
  disconnect through the hub would hit DVR's stick on the same hub — never.
- Fix (`common/bp_usb.sh` `bp_usb_announce`): repeat the call with root, `service call audio 60 …`.
- 🔬 IAudioService codes (baksmali, framework.jar of stand 194, 7862 update(2), 8581 QF005, 8581 BMW — identical):
  `setStreamVolume` 0xa, `getStreamVolume` 0xf, `getStreamMaxVolume` 0x11, `setWiredDeviceConnectionState` 0x3c.

## 2. Level: full scale from Android, the DAC's own control
- 📻 AudioService keeps a music index per device; `usb_headset` was 10/15 → a digital cut before a 16-bit DAC.
  QF volume keys go to the MCU, so the user cannot raise it. `audio_safe_volume_state=3` did not block raising it
  from root.
- 📻 USB mixer thread: `Processing format: PCM_FLOAT`, `HAL format: PCM_16_BIT` (PCM2704 is S16 only).
- 📻 PCM2704 has `PCM Playback Volume` (dsrange 0..128) and `PCM Playback Switch`. The driver's dB range is in
  `/proc/asound/cardN/usbmixer`: `dBmin=-12800, dBmax=0` (1/100 dB), 1 dB a step on paper. 🔴 Not what comes out: owner by ear, step 4
  («−124 dB») is a whisper, half the knob (step 64) normal listening. Never derive a level from it. Nothing is measured automatically (owner 02.11: «Ми дали інструмент, - юзер бавиться»).
- `common/bp_usbvol.sh`: index = max on the USB device; `usb_dac_volume=follow` → control from `sys.media.vol` through a
  curve per DAC model (`usb_dac_curve_<vid>_<pid>=a,b,c,d,e`: knob 1, 8, 16, 24, 32 in % of the range, strictly rising, monotone cubic in float; default even in steps; every level change is a ~1 s ramp)
  (unset → `persist.sys.main_volume`), mute → switch off. No control → no follow (owner: «немає - значить немає»).

## 3. «Auto» = the player straight to the DAC (not done — design notes)
- 🔬 `libaudiopolicymanagerdefault.so` (md5 95e96538…, 7862) `AudioPolicyManager::getOutputForDevices` @ 0x50378:
  AOSP gate «linear PCM, ≤192 kHz, ≤2 ch, no DIRECT flag → mixer». Unisoc additions at its start:
  stream 0 → flags `0x8001` (VOIP|DIRECT); stream 3 with flags 0 → `0x8` (DEEP_BUFFER) if `audio.deep_buffer.media`
  (unset here) — code 0x50400..0x50424. 🧩 Patch idea: that branch sets DIRECT (`orr w8, wzr, #0x1`, skip the
  property call). Then music tries a direct profile on its device; none → AOSP clears DIRECT and uses the mixer.
  FAST/low-latency tracks keep their flags and are not touched.
- 🔬 Policy needs a DIRECT mixPort on the USB module (dynamic profiles from the HAL, maxOpenCount 1).
- 🔴 One PCM per USB card: while the direct output holds it, a USB mixer output cannot open (busy) — the same rule
  as `pcmC0D3p` on primary.
- 🔴 🔬 `audio_policy_engine_product_strategies.xml`: `USAGE_ASSISTANCE_NAVIGATION_GUIDANCE`, `ASSISTANT`,
  `ASSISTANCE_SONIFICATION` are in **STRATEGY_MEDIA** (stream SYSTEM) — same device as music. «Prompts to the head
  unit» therefore needs them moved to another strategy whose PFW rule excludes USB
  (`parameter-framework/Settings/Policy/PolicyConfigurableDomains.xml`) — this touches the navigation ducking path,
  which calls and radio stand on. Owner's modes: TODO §3.
