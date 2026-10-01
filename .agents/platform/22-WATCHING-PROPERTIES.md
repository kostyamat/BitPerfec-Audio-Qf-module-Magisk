# Watching a system property without polling

Several platform states live only in properties — `sys.qf.call_state`, `sys.current.vol.type`,
`sys.qf.sound.channel`, `sys.qf.is.acc.on`. Reacting to them by polling costs a timer in every app
that cares. There are three ways to be told instead, and **one of them does not do what its name
suggests**.

📻 All three below were checked on the K706 bench, 01.10.2026, with a positive control, on the
harmless property `debug.bp.probe` (board #1131 → #1138 → #1141).

## The verdict

| method | wakes on a plain `setprop` / `SystemProperties.set`? | where it works |
|---|---|---|
| `__system_property_wait` (bionic) | **yes** — 📻 woke after 3032 ms on a `setprop` issued at 3 s, serial `16777216 → 16777218` | native code only: JNI or a standalone binary, API 26+ |
| QF broadcasts (`com.qf.action.PHONE_CALL_START` / `_END`, `com.qf.action.VOLUME_CHANGED`) | only when the platform code that sends them runs; a manual `setprop` sends nothing | any app |
| `SystemProperties.addChangeCallback` (hidden, reflection) | **no** — 📻 `callbacks=0` after an external `setprop`; `callbacks=1` only after `reportSyspropChanged()` | any app, but see below |

## Why `addChangeCallback` stays silent

🔬 `android/os/SystemProperties.java` (our `framework.jar`, md5-matched to the bench): the callbacks
run from `callChangeCallbacks()`, which native code calls only when the process receives the binder
transaction `SYSPROPS_TRANSACTION` (`IBinder.java`: 1599295570). That transaction is sent by
`SystemProperties.reportSyspropChanged()` — so **whoever changes a property must also announce it**,
and then every process in the system is woken. `property_service` itself notifies nobody.

⇒ It is useful only between parties that agree to call `reportSyspropChanged()` after a `set`.
For anything the platform or a shell script sets, it never fires — and the failure looks exactly
like "nothing changed".

### If you do use it (two parties that agreed to call `reportSyspropChanged()`)

Additions by the wDSP line (board #1145), checked against the same source:

- 🔬 **There is no `removeChangeCallback`.** `sChangeCallbacks` is a static, process-wide list and
  nothing removes from it — a registered callback lives as long as the process. Register once per
  process from a long-lived component, never from an activity, and capture no `Context` or `View`
  in the lambda: it is a leak nobody will find later.
- 🔬 **It runs on a binder thread, for every property at once.** `callChangeCallbacks()` copies the
  list under a lock and runs every callback synchronously on whichever thread received the
  transaction. Inside: read, compare, post the work to your own handler. No UI, no settings writes,
  no MCU calls.

## How to use the one that works

```c
#include <sys/system_properties.h>
const prop_info *pi = __system_property_find("sys.qf.call_state");   // NULL until it is set once
uint32_t serial = __system_property_serial(pi), next;
while (__system_property_wait(pi, serial, &next, NULL)) {             // futex, 0 % CPU
    serial = next;
    char v[PROP_VALUE_MAX];
    __system_property_read(pi, NULL, v);
    /* react to v */
}
```

- `__system_property_find` returns NULL for a property that has never been set. Wait on the global
  serial (`__system_property_wait(NULL, …)`) until it appears, or set it once at start.
  ⚠️ This matters for exactly the props we care about: 📻 after a cold boot `sys.current.vol.type`
  and `sys.media.vol` read back **empty** (#1056) — whether they are absent or present-and-empty was
  not distinguished (`getprop` prints the same). Code for both cases.
- One blocked thread per property; it costs nothing while asleep.
- The probe used for the measurement is a 7 KB aarch64 binary built with NDK r28,
  `aarch64-linux-android29-clang` — reproducible in a minute.

## In a shell script (Magisk `service.sh`)

❓ Not checked whether this toybox `getprop` has a wait option. Without one, a shell loop of `sleep N` that compares
state is the cheapest thing available without shipping a binary; it starts no JVM. Ship the native
waiter only if a delay of a few seconds actually matters.

— BitPerfect line, 01.10.2026 · additions: wDSP line, 01.10.2026
