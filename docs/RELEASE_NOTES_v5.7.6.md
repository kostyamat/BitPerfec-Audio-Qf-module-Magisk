> [!CAUTION]
> **Magisk: use version 30.6 at most. 30.6 is the recommended one.** A kernel patched with Magisk works properly only up to 30.6; Magisk 31.1 and later do not support a kernel patched with Magisk 27.
>
> **Magisk: максимум версія 30.6, саме вона рекомендована.** Ядро, патчене Magisk, нормально працює лише до 30.6; Magisk 31.1 і новіші не підтримують ядро, патчене Magisk 27.

🔴 **QF / K706 (or its MG clone) only.** UIS7862: full module. UIS8581: reduced profile 🧪 (no tester report yet). Any other firmware is refused.

📖 **Guide with pictures:** [English](https://github.com/kostyamat/BitPerfec-Audio-Qf-module-Magisk/blob/main/docs/GUIDE.en.md) · [Українська](https://github.com/kostyamat/BitPerfec-Audio-Qf-module-Magisk/blob/main/docs/GUIDE.uk.md)

**Replaces v5.7.5. If you installed v5.7.5, update.**

A tester reported on v5.7.5: sound fading out, noise only, players crashing, and several reboots needed before it worked again. We could not reproduce this on a clean install, so its cause is not confirmed. These defects were found while looking for it, and are fixed:

- **The module brings everything itself.** The top-level audio policy and the navigator list are now ready files inside the module, on UIS8581 too. Nothing is copied from the unit and edited on the fly, so a small change in a new firmware no longer changes what the module does.
- **A failed microphone-settings build can no longer damage anything.** Before, it could write a broken parameter file over the working one, delete the compiled parameters and restart the sound server. A broken build now leaves everything as it was.
- **Boot:** the microphone step runs only when you have microphone settings. The module's checks finish about 12 seconds sooner on the unit we measured.

**Still seeing problems?** Please send `/data/adb/BitPerfect.log`, `/data/tombstones/`, `/sdcard/QF_audio_survey/` and your Magisk version to the [support group](https://t.me/kostyamat_dev/3).

---

**Українською.** Заміняє v5.7.5: якщо ставили її, оновіться. Тестер повідомив на v5.7.5 про зникання звуку, шум, падіння плеєрів і кілька потрібних перезапусків. На чистій установці ми цього не відтворили, тож причина не підтверджена. Виправлено знайдені під час пошуку вади: модуль сам несе всі свої файли, без правок файлів апарата на льоту; зірвана збірка налаштувань мікрофона більше нічого не псує; старт коротший приблизно на 12 секунд. Якщо проблеми лишаються, надішліть `BitPerfect.log`, `/data/tombstones/`, `/sdcard/QF_audio_survey/` і версію Magisk у [групу підтримки](https://t.me/kostyamat_dev/3).
