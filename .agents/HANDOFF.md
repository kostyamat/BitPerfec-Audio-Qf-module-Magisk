# Зріз — 04.10.2026 ~22:50, сесія `3827b401` (Claude), мікрофон: дзвінок є, «сирий» запис — ні

**Доручення власника (картбланш):** один мікрофон — його NR (AGDSP 4.18) і AEC з петлі динаміка
для SIM- і BT-дзвінків, розпізнавання — клієнти, RAW для wDSP/ШІ. Платформу питати в Дж
(`0c0b138e`), кімната `gemini-window-3827-підключись-до-магніто`. Вночі дзвонити лише на 1200.

**Репо:** `v5.4-repaired`, не запушено з `73d72cc`. Ключове: `b96b2a4` AEC + вхід як у 4.18;
`64b4c9f` такти I2S на дзвінку; `456198d` `sys.bitperfect.enabled`; `e0cde90` мікрофон і опора +7.5 дБ.

**Стенд `192.168.1.140:9876`** (після знеструмлень адреса стрибає — сканувати порт 9876).
BitPerfect = репо, `enabled=1`; модуль дзвінків v3.7 + DialerKM `a386876`; wDSP від Дж
(`D:\gemini\wdsp_test`, `gemini_ui_dev`, `bfe03c8`); FS-Doctor v1.6 (`Data_FS_fix.module`, свій git,
прибирає). SIM у мережі (DIGI ES, LTE). MCU V02.13. adb вільний.

## 🧪 Перед тестовим дзвінком
Знімання: `.agents/tools/call_probe.sh` (SIM, 1200 через Telecom), `.agents/tools/bt_probe.sh` (BT).
DialerKM: `am broadcast -a com.km.roco_ai.action.VOICE_DIAL -p com.km.roco_ai --es extra_number N`.
Здоров'я: немає `dsp timeout`, є `name:Audio\Handset\NB1|WB1`.

## ✅ Сьогодні (04.10)
- SIM-дзвінок з wDSP від Дж (22:31): мікрофон звільнено, DSP живий, «звук є» (власник).
- Шторм після знеструмлення — eMMC, не наш код. FS-Doctor: 3 коміти (тиша диска, пороги від /data,
  сон без зависання) + `meminfo`-баг, через який демон помирав на звіті з v1.5.
- 8581: `extendArray`/`nrArray` = обробка **запису**; WebRTC AEC без опори; профіль 44.1/16 (TODO 5а).

## ⏳ У роботі — «сирий» мікрофон для wDSP і ШІ
- 📻 wDSP бере `AUDIO_SOURCE_MIC` → −98 дБ: набір `Music\Handsfree\Record` має `VBC_ADC0_DG=0x03`
  (на 31.5 дБ нижче за `UnprocessRecord`) + `NsEnable`. Завдання — Дж `ad912b89` (#1346/#1348,
  кімната «Сову на глобус WDSP», TODO 0а wDSP `af51d7b`); приймає Claude wDSP.
- 📻 RokoAi просить `UNPROCESSED` (9), але HAL отримує `source:1 flags:0`; поруч у лозі
  `CAPTURE_AUDIO_OUTPUT … denied`. У сирцях Unisoc підміни нема → бінарники QF. Розкопка — Дж
  `0c0b138e` (#1347). Коли знайде — фікс у BitPerfect, і wDSP, і ШІ отримають `UnprocessRecord`.

## 📋 Далі
BT-дзвінок (`BTHS`); аплінк/луна — живій людині, оцінити +7.5 дБ; рев'ю `gemini_ui_dev` (інший
акаунт); DialerKM без SIM і BT — «немає маршруту» (#1342); Telecom `sprd_voip_start` — розібрати.
