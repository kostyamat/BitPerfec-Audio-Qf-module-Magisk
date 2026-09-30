# Working here — traps, and where each mirror lives

Knowledge, not rules. The rules are in `AGENTS.md`; this is what the machine and the platform do to
you while you follow them.

---

## Traps that have already cost time on this project

🪤 **A byte delta that equals the line count is CRLF, not content.** Normalise (`tr -d '\r'`) before
diffing or comparing sizes of module files. 📻 30.09: two builds looked 15 files apart; 12 of those
differed only in line endings, and the delta of each was exactly its line count. Without that check
the conclusion would have been "uncommitted work lost".

🪤 **After `adb reboot`, wait on `uptime`, not `sys.boot_completed`.** `adbd` outlives the reboot
request, so the first poll reads the *previous* boot's `1`. 📻 30.09: a waiter reported "up in ~10 s"
for a boot that took a minute.

🪤 **`adb shell grep 'a\|b'` silently returns nothing** under MSYS — the escape is eaten. Use
`MSYS_NO_PATHCONV=1`, and verify an empty result with a second, simpler command before believing it.
📻 This twice produced a false "absent": once for `com.waze` in `NaviApp.ini`, once for the
`/vendor/firmware` symlinks. Both were there.

🪤 **`adb pull` needs a Windows-style local path** when `MSYS_NO_PATHCONV=1` is set — a `/c/...`
destination fails with "No such file or directory".

🪤 **An unset `sys.*.vol` reads back as its `persist.sys.*_volume` default** on every call. That *is*
the "volume reset itself" bug; there is no reset code anywhere.

🪤 **Volume is per source, not per Android stream**, and a write only reaches the MCU while its type
matches `sys.current.vol.type`. A write to an inactive source stores the level and makes no sound.

🪤 **`persist.sys.*` are a derivative, not the store.** They are re-applied at boot from
`/great/protect_dir/car.config` via `config_service`. 📻 Proven: set `navi_remix_ratio` to 40 with
the file saying 60, reboot → 60. A direct write looks fine all session and then quietly reverts.

🪤 **`change_directory` moves the shell, not the session.** `pwd` shows the new path while
`get_session({session_id:"self"}).cwd` still shows the old one — and the post-compaction hook looks
at the session's `cwd`, so the guard silently does nothing. Check yourself with `get_session`, never
with `pwd`. 📻 30.09, cost a wrong "I have moved".

🪤 **Commit messages from PowerShell go through `-F <file>`, never `-m`.** A multi-line `-m` with
quotes inside breaks apart into pathspecs and the commit fails halfway.

🪤 **`git add` stops at the first non-existent path** and adds nothing after it, while the commit
still succeeds. Run `git show --stat` after every commit.

🪤 **A `.gitignore` line without a leading slash catches nested paths**, and one with a slash only
catches the root. `/build` missed `app/build` entirely here.

---

## Which mirror lives where

🔴 **The `qf-platform` skill is the canon** — the owner's ruling of 30.09.2026. Everything else is a
mirror, maintained by whoever owns the subject.

| file | subject | live mirror |
|---|---|---|
| `09-NAVIGATION-AND-BITPERFECT.md` | navigation, ducking, what BitPerfect does to them | **`.agents/platform/` here** |
| `10-BITPERFECT-MODULE.md` | the module itself — §7 routes, §12 AGDSP | **`.agents/platform/` here** |
| `08-VOLUME-AND-SOURCES.md` | the per-source volume model, the AK hub | `wDSP\.agents\platform\` |
| `05-AUDIO-PATH.md`, `02-MCU.md`, the rest | shared | `wDSP\.agents\platform\` |

Edit the mirror you own, then copy it to the skill — **never the other way round**.

🪤 **Never copy blind, in either direction.** Before overwriting, check the destination has no lines
the source lacks (`diff` after normalising CRLF). These files have drifted in *both* directions
before, and a copy made without that check destroys somebody's work.

Every addition carries a provenance mark: 🔬 read in code · 📻 measured on the wire · 🧩 inferred ·
❓ unverified. A guess written as a fact is worse than no note at all.

---

## Where the rest is

- decompiled platform — `D:\De-compiled\`
- UI style — the `automotive-hyper-ui` skill (canon:
  `C:\Users\kosty\.gemini\config\skills\automotive-hyper-ui\SKILL.md`)
- contracts between applications — `C:\APPS_Contacts\` is canonical; copies in trees are mirrors
- shared memory — one set of files behind four directory keys; sign entries, amend rather than
  duplicate (the rules are in the `MEMORY.md` header)
