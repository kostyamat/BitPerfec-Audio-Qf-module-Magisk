> [!CAUTION]
> **Magisk app: use version 30.6.** With the older app 27 the module may not install completely; with 31.1 and later, apps do not get root (they do not support a kernel patched with Magisk 27).
>
> **Програма Magisk: версія 30.6.** Зі старішою 27 модуль може поставитись не повністю; із 31.1 і новішими програми не отримують root (вони не підтримують ядро, патчене Magisk 27).

🔴 **QF / K706 (or its MG clone) only.** UIS7862: full module. UIS8581: reduced profile 🧪 (no tester report yet). Any other firmware is refused.

📖 **Guide with pictures:** [English](https://github.com/kostyamat/BitPerfec-Audio-Qf-module-Magisk/blob/main/docs/GUIDE.en.md) · [Українська](https://github.com/kostyamat/BitPerfec-Audio-Qf-module-Magisk/blob/main/docs/GUIDE.uk.md)

**USB DAC: a volume curve for your DAC**
- With "follows the head unit's knob" on, the USB DAC tab now has a curve: five sliders for where the knob lands on the DAC's own scale. Every DAC feels different, so tune it by ear with music on; it applies at once and is kept per DAC model. Without changes the knob behaves as before.
- The module finds the DAC's own volume control and its number of steps by itself (tested: 128 steps on a PCM2704, 30 on a GeneralPlus DAC with a microphone). The DAC's microphone is not used.
- The knob, mute and ignition now act at once: the module is woken by the change instead of checking on a timer. A DAC plugged in gets its level before the first sound.

**Root**
- Without root the app now says so in red, explains why and shows a button that opens Magisk on the right screen. Back from Magisk, it asks again by itself. It no longer retries every few seconds.
- The installer warns when the Magisk app is not version 30.6.

**Still waiting for reports:** v5.7.5 problems (sound fading, noise, crashes) were not reproduced here, so their cause is not confirmed. Please send `/data/adb/BitPerfect.log`, `/data/tombstones/`, `/sdcard/QF_audio_survey/` and your Magisk version to the [support group](https://t.me/kostyamat_dev/3).

---

**Українською.** USB-ЦАП: у вкладці тепер є крива гучності, п'ять повзунків, куди ручка магнітоли потрапляє на власній шкалі ЦАПа. Налаштовується на слух під музику, застосовується одразу, зберігається окремо для кожної моделі ЦАПа. Модуль сам знаходить регулятор ЦАПа і кількість кроків, а ручка, вимкнення звуку й запалювання спрацьовують одразу. Без root програма показує це червоним і відкриває Magisk на потрібному екрані, а після повернення питає ще раз. Інсталятор попереджає, якщо програма Magisk не 30.6. Причину скарг на v5.7.5 не підтверджено: якщо проблеми лишаються, надішліть `BitPerfect.log`, `/data/tombstones/`, `/sdcard/QF_audio_survey/` і версію Magisk у [групу підтримки](https://t.me/kostyamat_dev/3).
