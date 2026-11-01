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

## 📋 Next (`.agents/TODO.md`)
Root-prompt UX in `ModuleControl` (DEBT: one-line error, `su` every 3 s, deadline that cannot fire); shorten `AGENTS.md` (over 8 KB);
testers' feedback; UIS8581 with a tester; «Авто» direct DAC path; DTS / multichannel; AEC calibration; EQ for wDSP.

## Waiting
- Gemini #2009 correction still owed (PGA step ≈5–6 dB at the top, not 3; with BitPerfect source 9 passes).
- Owner: SIM call without echo (`58d9759`); SIM call silencing wDSP+DVR. ❓ Forum posts for v5.7.6: not asked.
