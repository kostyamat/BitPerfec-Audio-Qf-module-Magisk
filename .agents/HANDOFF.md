# Slice — 02.11.2026, session `3827b401` (Claude): v5.7.7 RELEASED

**Release v5.7.7 is live:** tag on `6d1d9f9`, asset `QF_BitPerfect.module.v5.7.7-Universal.zip` (2 002 681 B, md5 1be99f5f…) + guide PDFs, `update.json` → 5707.
v5.7.5 stays published as a prerelease titled DO NOT USE; v5.7.6 stays as it is. Default branch **`main`**; `v5.4-repaired` is only fast-forwarded to it (v5.6.x installs read
its `update.json`). Push from WSL as the default user, both branches.

**In v5.7.7:** DAC curve per model (`usb_dac_curve_<vid>_<pid>`, 5 sliders, monotone cubic, right side stretches, left stays), the DAC's control and steps read from the DAC,
`common/bp_propwait` + `inotifyd` instead of polling, a no-root screen (red, Open Magisk, asks again on return), installer warns about the Magisk app. From v5.7.6: ready files,
no patching of the unit's files (sole exception `music_volume` in `car.config`), awk failure guarded. Red note in all texts: Magisk app 30.6 (owner; 27 and 31.1 not reproduced by me).
Details: `.agents/USB_DAC.md`, `.agents/DEBT.md`. `f4b4d4d` has a wrong title; its description is in `17e7506`.

**Stand 194 `192.168.1.194:9876`** (QF05 004121, ums512, BU32107): v5.7.7 by update from public v5.6.1. GeneralPlus DAC (`1b3f:2008`, 30 steps) plugged, `usb_dac=1`, follow. 🔴 The owner's curves
are in its `bitperfect.conf`: DO NOT overwrite them (copy: `D:/My_K706_Magisk_Modules/stand194_backup_20261102`). BitPerfect has no Magisk grant now: a prompt on first open.
System language en-US. Shared with QF_DVR (session 147a9dc2): board room `qf-dvr-claude-window-7ef9`, rules `C:\APPS_Contacts\BitPerfect--DVR\MIC_CLIENT_CONTRACT.md` § «Stand 194».

## ⏳ Open
- Marcin's complaint on v5.7.5 (noise, YT Music crash, ~8 reboots): cause NOT established. Needs his log + tombstones and Magisk version.
- Stand: `system_server` SIGSEGV in JIT at boot, also with BitPerfect removed. 🧩 Suspect PMPatch3, ❓ or QF DVR (owner). `DEBT.md`; test = disable PMPatch3 for a few boots, needs the owner's yes.
- Owner's toggle idea (head unit path while the DAC is off): top of `TODO.md`.
- `usb_dac_volume` default is `full`: a person switching to USB DAC gets it at full scale until the knob toggle is on. Owner has not decided.

## 📋 Next (`.agents/TODO.md`)
Testers' feedback; shorten `AGENTS.md` (over 8 KB); UIS8581 with a tester; «Авто» direct DAC path; DTS / multichannel; AEC calibration; EQ for wDSP.

## Waiting
- Gemini #2009 correction still owed (PGA step ≈5–6 dB at the top, not 3; with BitPerfect source 9 passes).
- Owner: SIM call without echo (`58d9759`); SIM call silencing wDSP+DVR. ❓ Forum posts for v5.7.7: not asked.
