# Slice — 01.11.2026, session `3827b401` (Claude): v5.7.5 RELEASED, repo moved to `main`

**Release v5.7.5 is live:** tag `v5.7.5` on `97bf8cc`, asset `QF_BitPerfect.module.v5.7.5-Universal.zip`
(1 973 218 B, md5 4f8d49b5…) + guide PDFs en/uk (`tools/build_guide_pdf.py`, `tools/gh_release_asset.py`),
`update.json` → 5705 (`ae2b742`). Notes `docs/RELEASE_NOTES_v5.7.5.md`, guides `docs/GUIDE.en.md` / `GUIDE.uk.md`,
screenshots `docs/img/{en,uk}/`. Both branches pushed at `8bcd2aa`. TG posts (uk + en) written, owner posts them.
**Branches:** default is now **`main`** (owner 01.11: «з цієї версії переїзджаємо в майн»); `v5.4-repaired` is only
fast-forwarded to `main` on each release, because v5.6.x installs ask its `update.json` (`RELEASE.md`).
Work on `main`. Push from WSL as the default user, both branches.

**Stand 194 `192.168.1.194:9876`** (QF05 004121, ums512, BU32107, PCM2704 on USB): the release zip, 📻 checked
(bp=1, healthy, WD_24BIT, USB_HEADSET 15/15, DAC 12/128 at knob 3). System language is **en-US** (owner switched it
for the English screenshots). Shared with QF_DVR (session 147a9dc2): talk ONLY in board room
`qf-dvr-claude-window-7ef9`; rules `C:\APPS_Contacts\BitPerfect--DVR\MIC_CLIENT_CONTRACT.md` § «Stand 194»
(`svc power reboot`, `working`/`done`, own module only).

## What v5.7.5 holds (details in commits)
Shared mic; own navigators; call mic per channel (level, AEC, NR + depth, presets — `.agents/MIC_CONTROL.md`);
USB DAC: announced after a switch, full scale from Android, level on the DAC's own control (optionally the head
unit's knob), silent with the ignition off (`.agents/USB_DAC.md`); app in tabs, 25 languages (23 by Gemini),
APK 1.90 MB (WebP backgrounds, locale filter).

## 📋 Next version (`.agents/TODO.md`, rewritten for it)
1. Testers' feedback on v5.7.5 (other DACs, mic on real calls). 2. UIS8581 with a tester. 3. «Авто» = player
straight to the DAC + prompts elsewhere (navigation strategy move — careful, calls/radio stand on it), DTS /
multichannel DACs, AEC calibration per mode (by day, in a car). 4. EQ for wDSP.

## Waiting
- Gemini #2009 correction still owed (PGA step ≈5–6 dB at the top, not 3; with BitPerfect source 9 passes).
- Owner: SIM call without echo (`58d9759`); SIM call silencing wDSP+DVR.
- ❓ Forum posts (4PDA/XDA) for v5.7.5 — not asked yet. 8581: still no tester report (said so in the TG post).
