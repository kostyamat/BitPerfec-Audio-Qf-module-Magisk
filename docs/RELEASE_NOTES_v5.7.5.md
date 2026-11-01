🔴 **QF / K706 (or its MG clone) only.** UIS7862: full module. UIS8581: reduced profile 🧪 (no tester report yet). Any other firmware is refused and nothing is changed.

📖 **Guide with pictures:** [English](https://github.com/kostyamat/BitPerfec-Audio-Qf-module-Magisk/blob/main/docs/GUIDE.en.md) · [Українською](https://github.com/kostyamat/BitPerfec-Audio-Qf-module-Magisk/blob/main/docs/GUIDE.uk.md)

**BitPerfect Control — the settings app inside the module**
- Status: the chip, what is really playing and where (head unit or USB DAC, bits, rate), whether the module confirmed itself this boot. Settings in tabs: USB DAC, Microphone, Navigators, Look.
- 25 languages: English, Ukrainian, Arabic, Bulgarian, Chinese (Simplified, Traditional), Czech, Dutch, French, German, Greek, Hebrew, Hungarian, Italian, Japanese, Korean, Polish, Portuguese (PT, BR), Romanian, Russian, Slovak, Spanish (ES, AR), Turkish.

**USB DAC**
- Switching Head unit ↔ USB DAC works at once — no replugging, no reboot.
- Android sends the DAC full scale; the level is set by the DAC's own volume control. Optionally it follows the head unit's volume knob. A DAC without its own control plays at full level — Android never cuts its signal.
- The DAC's own name, id and declared formats; DAC mode: its best, or a fixed format from its own list (e.g. 44.1 kHz without resampling).
- Silent while the ignition is off: no more loud beeping from the sleep countdown.

**Call microphone (UIS7862)** — per channel (SIM, VoIP, Bluetooth): level −12..+12 dB, echo cancelling, noise reduction and its depth, named presets. Recording apps keep the raw microphone.

**Shared microphone** — several apps can record at once (a dashcam next to wDSP Pro); Android no longer silences all but the one on top. Calls still take the microphone.

**Navigators** — add your own navigator and set how its prompts behave.

Installer output and logs are in English. Your settings live in `/sdcard/BitPerfectAudio/` and survive updates.

**Feedback:** https://t.me/kostyamat_dev/3 — send `/sdcard/QF_audio_survey/` and `/data/adb/BitPerfect.log` (see README).

---

🔴 **Лише QF / K706 (або клон MG).** UIS7862 — повний модуль, UIS8581 — зменшений профіль 🧪 (звітів тестерів ще нема).

Нове: програма налаштувань **BitPerfect Control** у модулі (стан, що й куди грає, вкладки; 25 мов). **USB-ЦАП** перемикається одразу, без перепідключення; Android віддає ЦАПу повну шкалу, гучність — власним регулятором ЦАПа, за бажанням за ручкою магнітоли; ЦАП мовчить при вимкненому запалюванні (більше ніякого пікання відліку сну). **Мікрофон дзвінків** окремо для SIM, VoIP і Bluetooth: рівень, ехозаглушення, шумодав і його глибина, пресети. **Спільний мікрофон** — кілька програм пишуть одночасно (реєстратор поруч із wDSP Pro). Власні **навігатори**. Посібник із картинками — [українською](https://github.com/kostyamat/BitPerfec-Audio-Qf-module-Magisk/blob/main/docs/GUIDE.uk.md). Відгуки — https://t.me/kostyamat_dev/3.
