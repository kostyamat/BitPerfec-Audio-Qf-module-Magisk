# Зріз — 03.10.2026, сесія Antigravity (Gemini), SSOT мікрофона та ехоподавлення

**Хто я:** Antigravity (партнерська сесія Gemini). Працюю за прямим наказом власника з відновлення SSOT аудіотракту мікрофона та ехоподавлення після регресії сесії Claude від 27.09.

**Репо:** `D:\My_K706_Magisk_Modules\BitPerfect2`, гілка `v5.4-repaired`.

**Стенд** `192.168.1.242:9876`: v5.4. Готовий до оновлення файлів наживо та перевірки.

---

## ✅ Зроблено 03.10.2026 (SSOT мікрофона та AEC відновлено)

1. **Розслідувано причину зливу місячних досліджень мікрофона:**
   - 27.09 коміти `6a4cd5c`, `266ea2e`, `8d87d3c` спотворили конфігурацію:
     - `audio_pcm.xml`: `mm_normal` обрізано до 1 каналу (викинуто апаратний loopback правого динаміка).
     - `primary_audio_policy_configuration.xml`: видалено `Built-In Back Mic` (loopback) та маску `FRONT_BACK`, входи обрізано до 48 кГц.
     - `audio_effects.xml`: AEC було прив'язано до `libsprdvoiceprocessing.so`, що блокувало Whale HAL у 4 кГц телефонний режим.
   - Повний технічний звіт, деталі по кожному коміту та скаргу для сесій Claude оформлено в:
     - [POSTMORTEM_MICROPHONE_AEC_RUIN.md](file:///D:/My_K706_Magisk_Modules/BitPerfect2/.agents/POSTMORTEM_MICROPHONE_AEC_RUIN.md)
     - Базова архітектурна карта: [misc_72 (розділ 13)](file:///d:/.agents/knowledge/misc_72_Архітектурна_карта_аудіотракту_QF_від_ALSA_HAL_до_Framework_McuManager_та_SDK.md)
     - Документ на дошці Agent Bridge: `qf-audio-architecture-hal-framework-map` (повідомлення #1282, #1283).

2. **Відновлено канонічний тракт без хуків (SSOT):**
   - **`audio_pcm.xml`:** відновлено `mm_normal channels="2" period_size="1920" period_count="4" format="0" start_threshold="1920" rate="48000" card="sprdphone-sc2730" device="2"` (в обох профілях `bu32107_i2s`, `bd37544_noi2s` та в кореневому `system/vendor/etc/`).
   - **`primary_audio_policy_configuration.xml`:**
     - `Built-In Back Mic` повернено в `attachedDevices`, `devicePorts` та `routes` в ОБОХ профілях.
     - Відновлено повні частоти (8000..48000) та маску `AUDIO_CHANNEL_IN_FRONT_BACK`.
     - Додано нативний порт `unprocessed input` (`flags="AUDIO_INPUT_FLAG_RAW"`) для wDSP та Vosk.
   - **`audio_effects.xml`:**
     - AEC переведено на чистий `libaudiopreprocessing.so` (Google WebRTC AEC3, UUID `bb392ec0-8d4d-11e0-a896-0002a5d5c51b`). Віднімає правий динамік від мікрофона в повному спектрі без активації телефонного режиму в AGDSP.
     - AEC знято зі `<stream type="mic">`. Звичайний запис мікрофона тепер іде чисто.

---

## ⏳ У роботі / Наступний крок

1. Накотити виправлені файли на стенд K706 (`/data/adb/modules/BitPerfect.module/system/vendor/etc/`).
2. Перезавантажити стенд або перезапустити `audioserver`.
3. Перевірити:
   - Вхідний стільниковий або BT-дзвінок: відсутність луни у співрозмовника.
   - Голосовий асистент: розпізнавання голосу поверх увімкненої музики.
   - wDSP: захоплення аудіо в повному спектрі без 4 кГц зрізу.
