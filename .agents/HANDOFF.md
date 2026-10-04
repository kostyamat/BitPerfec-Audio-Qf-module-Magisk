# Зріз — 04.10.2026 ~23:58, сесія `3827b401` (Claude): дзвінок знову тихий — wDSP тримає мікрофон

**Доручення власника (картбланш):** один мікрофон — його NR (AGDSP 4.18) і AEC з петлі динаміка
для SIM- і BT-дзвінків, розпізнавання — клієнти, RAW для wDSP/ШІ. Платформу питати в Дж
(`0c0b138e`), кімната `gemini-window-3827-підключись-до-магніто`. Вночі дзвонити лише на 1200.

**Репо:** `v5.4-repaired`, не запушено з `73d72cc`. Ключове: `b96b2a4` AEC + вхід як у 4.18;
`64b4c9f` такти I2S на дзвінку; `456198d` `sys.bitperfect.enabled`; `e29dc9b` мікрофон і опора дзвінка DG 18.

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
- Шторм після знеструмлення — eMMC; FS-Doctor v1.6 (свій git). 8581 — профіль 44.1/16 (TODO 5а).

## ⏳ У роботі — «сирий» мікрофон для wDSP і ШІ
- wDSP просить `UNPROCESSED`, HAL однаково бере `source:1` (`Record`); рівень живий (#1351).
- 📻 23:35: регулятор VBC DG — це **послаблення**: 0 → −41.7, 8 → −50, 24 → −70 дБFS (≈1.2 дБ/крок).
  Набір `Record` (DG 3) майже на максимумі, `UnprocessRecord` (24) на ~20 дБ тихіший. На потоці
  wDSP висять WebRTC AEC + NS (наш `stream mic`), у DSP — `NsEnable`. Політика бачить `Source: MIC`.
- `e29dc9b` (DG 18) на стенді: спершу мої файли + ребут 23:45, потім Дж `0c0b138e` без доручення
  поставив свій зип v5.5.1 (`4edb0e9`, лише версія) і ребутнув посеред тесту. ❓ `4edb0e9` — за власником.
- 🔴 Дзвінок 23:48 — тиша: wDSP (збірка 23:21) пише «releasing microphone», а `AudioRecord` живе ще 3.6 с
  → `start_input_stream` поверх голосу → `dsp timeout`. P0 Дж `ad912b89` (#1368). Без фіксу не дзвонити.
- 🔬 Підміна 9→1: `lib64/libaudioclient.so` `AudioRecord::set` 0x4d59c `str w9(=1),[this,#332]` —
  `mAttributes.source = MIC` безумовно, для всіх (#1369). Латка зачепить усі застосунки — рішення власника.
  ⚠️ Якщо латати — DG `UnprocessRecord` (24) теж опустити, інакше −20 дБ.
- DialerKM `706192c` (Дж `d739c765`): без SIM і BT — «Немає маршруту», `call_state` не чіпає (#1345).
  На стенді ще не перевірено.

## 📋 Далі
BT-дзвінок (`BTHS`); аплінк/луна — живій людині, оцінити DG 18; рев'ю `gemini_ui_dev` (інший
акаунт); Telecom `sprd_voip_start` — розібрати.
