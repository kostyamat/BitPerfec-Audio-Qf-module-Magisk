# How a BitPerfect release is made

Rules in force, from the v5.6 release (owner, 15.10.2026). Examples of every text: `.agents/release/`.

## Scope and labels
- 🔴 **QF firmware or its MG clone only, everyone else refused** (owner 23.10: «ти всіх виключай крім QF\MG») — `customize.sh`
  refuses anything whose `persist.sys.qf.mcu.version` / `ro.boot.hardware.revision` does not start `QF`/`MG`.
- 🔴 **UIS7862 only.** Every public text opens with «UIS7862 only — NOT for UIS8581» (owner: «з вказівками НЕ
  для 8581»); the installer enforces it (`customize.sh` platform gate, `ums512`).
- Version: `vX.Y-Universal` in `module.prop`; versionCode `XYZZ` (v5.5.17 = 5517, v5.6 = 5600). Bump only on a
  build that goes to the bench or out, in its own `release:` commit (module.prop only).

## Build and verify
1. Zip from the COMMIT, exactly 7 entries:
   `git -c core.autocrlf=false archive --format=zip -o QF_BitPerfect.module.vX.Y-Universal.zip HEAD META-INF common profiles system customize.sh module.prop service.sh`
2. Announce adb on the board if another line uses the bench; `magisk --install-module`, reboot.
3. Check after boot: `sys.bitperfect.enabled=1`, `car.config` music_volume 15, STREAM_MUSIC 15,
   `VBC_IIS_MST_WIDTH_SET` WD_24BIT (BU), log «Audio path is healthy». When the module layout changed, compare
   md5 of `/data/adb/modules_update/BitPerfect.module/system/vendor` with the previous live set.

## Publish (only on the owner's order: «пуш», «реліз»)
- The GitHub default branch is `v5.4-repaired` (set 16.10.2026; `main` holds only the old stub README) — the
  front page shows this branch's README, so it must be pushed for the README to be seen.
- Push from **WSL as the default user** (`wsl -e bash script.sh`) — the SSH keys are in that user's `~/.ssh`,
  root has none («Host key verification failed»). Check `git rev-list --left-right --count` = `0 0` after fetch.
- GitHub release from Windows: `python -I tools/gh_release.py <tag> <FULL sha> <body.md> <zip>` (token from
  `git credential fill`, never printed; a short sha is rejected). Tag on the pushed HEAD.
- **Magisk update** (`updateJson` in `module.prop` → `update.json` on the default branch): only AFTER the
  release asset is live, set `update.json` version / versionCode / zipUrl to it, add the release to
  `CHANGELOG.md`, commit, push. Pushed earlier, Magisk offers a zip that 404s. The zip name in `zipUrl` must
  match the uploaded asset exactly.

## Texts
- **README** (English) holds: what the module does, hardware table, «What changed since the classic v4.18»,
  install/disable/remove, Feedback (support group https://t.me/kostyamat_dev/3, what to send, the survey tool),
  «Support the developer» with the owner's payment details verbatim. README keeps «since v4.18» only; per-release notes go to
  `CHANGELOG.md` (Magisk shows it on the update button), short, one section per release.
- **Release annotation:** short, by the work done on the sound path and the microphone (owner: «згідно
  проробленої роботи що до трактів звуку і мікрофона»); English, then a short Ukrainian paragraph.
- **Forum posts:** 4PDA — Russian, BBCode (`[b] [list] [url] [font=Courier New]`); XDA — English, XenForo
  (`[B] [LIST] [URL='…'] [ICODE]`); each in one code block for copy-paste. A SHORT changelog vs 4.18 — owner:
  «Кожен крок змін описувати не потрібно».
- Feedback always asks for `/sdcard/QF_audio_survey/`, `/data/adb/BitPerfect.log` and, for navigation problems
  or BD units, a report from `tools/QF_audio_survey.v1.3.zip`.
