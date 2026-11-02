# Slice — 02.11.2026, session `3827b401` (Claude): v5.7.6 RELEASED after the tester's complaint on v5.7.5

**Release v5.7.6 is live:** tag on `44ab2ec`, asset `QF_BitPerfect.module.v5.7.6-Universal.zip` (1 974 862 B, md5 e143802a…) + guide
PDFs, `update.json` → 5706. v5.7.5 stays published as a prerelease titled DO NOT USE, with a red link to v5.7.6.
Default branch **`main`**; `v5.4-repaired` is only fast-forwarded to it (v5.6.x installs read its `update.json`). Push from WSL as the
default user, both branches.

**What changed (owner 02.11: «у модуль потрапляє ГОТОВЕ ДО ВЖИВАННЯ», `AGENTS.md` Bans):** policy and navigator list are ready files,
nothing of the unit's is patched (sole exception: `music_volume` in `car.config`); 8581 md5 gate removed (no 8581 unit tested);
`bp_mic_build` guarded, no awk without `mic.conf`. Red note in texts: Magisk 30.6 max (owner; not checked by me).
Commit `f4b4d4d` has a wrong title; its real description is in `17e7506`.

**Stand 194 `192.168.1.194:9876`** (QF05 004121, ums512, BU32107, PCM2704 on USB): v5.7.6 by update from public v5.6.1, 📻 enabled=1, policy at
24.3 s, WD_24BIT. `usb_dac=1`, `usb_dac_volume=follow`, no `mic.conf`; BitPerfect has no Magisk grant now: the owner sees a prompt on first
open. Owner's earlier settings and logs: `D:/My_K706_Magisk_Modules/stand194_backup_20261101`. System language en-US. Shared with QF_DVR
(session 147a9dc2): board room `qf-dvr-claude-window-7ef9`, rules `C:\APPS_Contacts\BitPerfect--DVR\MIC_CLIENT_CONTRACT.md` § «Stand 194».

## ⏳ First tester complaint (Marcin, on v5.7.5): noise, YT Music crash, cured by ~8 reboots
Cause NOT established, not reproduced. Needs his `bp_report.tgz` (log, tombstones, settings). A second user: Magisk gave the app no root prompt;
ask the Magisk version first (31.1+ with a Magisk 27 kernel is the owner's suspect). All findings: `.agents/DEBT.md`, last section.

## ⏳ Local, NOT released (owner: «Випустимо пізніше, після відгуків на 576»), on stand 194, version still 5.7.6
- DAC volume curve per model (5 sliders, knob 1/8/16/24/32 in % of the DAC control, monotone cubic in float, right side stretches, left stays), applied at once,
  `common/bp_propwait` instead of polling, index restored at once. 📻 Owner 02.11: «все працює чудово, реакція швидка». The owner's own curve is on the stand: DO NOT overwrite it.
- Installer warns about the Magisk app. `RootCard`: red status, sections hidden, button opens Magisk on Superuser / Modules, root asked again on return; one `su`, real timeout.
  📻 Owner 02.11: «після надання доступу, програма зразу перечитала всі потрібні змінні». A running app keeps its open su shell after a revoke: expected.
- Watcher: `bp_propwait` + `inotifyd` (`/dev/snd`, settings folder), 5 s tick; 📻 DAC replug restored the level before sound. Manual edit of the settings file not tried.
- The driver's dB scale is false (`.agents/USB_DAC.md`); nothing is measured automatically (owner: «юзер бавиться»).
- Release needs: listening on the speakers (`usb_dac=0`), guide + notes for the curve and the root screen, a version bump, a clean install and an update from v5.7.6.

## 📋 Next (`.agents/TODO.md`)
Shorten `AGENTS.md` (over 8 KB);
testers' feedback; UIS8581 with a tester; «Авто» direct DAC path; DTS / multichannel; AEC calibration; EQ for wDSP.

## Waiting
- Gemini #2009 correction still owed (PGA step ≈5–6 dB at the top, not 3; with BitPerfect source 9 passes).
- Owner: SIM call without echo (`58d9759`); SIM call silencing wDSP+DVR. ❓ Forum posts for v5.7.6: not asked.
