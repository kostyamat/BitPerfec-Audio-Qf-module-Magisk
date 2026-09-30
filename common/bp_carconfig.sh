#!/system/bin/sh
# Sourced by customize.sh (install) and service.sh (every boot) - the one place for this rule.
#
# The platform's own "default volume" lives in car.config, not in a property:
#   ConfigInfoManagerService (boot) copies music_volume.current -> persist.qf.arm.default.volume
#   QFSleepWakeup (every boot and every wake) sets MUSIC, NOTIFICATION and ALARM to that value
# Factory music_volume is 9, which is -16 dB on music and -17.8 dB on the alarm stream - and the
# incoming-call ringtone plays on the alarm stream (Telecom, measured 30.09.2026). Pinning the
# property alone loses: the config service rewrites it from car.config after we set it.
#
# music_volume is visible=0 in car.config - no user slider reads or writes it - so pinning it to
# unity takes no choice away from the owner. The file is rewritten in place (cat, not sed -i):
# it is system:system 0600 with an SELinux label, and a replaced inode would lose both.

BP_CARCONFIG=/great/protect_dir/car.config
BP_CARCONFIG_BAK=/data/adb/BitPerfect.car.config.bak

# returns 0 = already 15, 2 = changed, 1 = file or line missing (not a QF unit we know)
bp_pin_music_volume() {
    [ -f "$BP_CARCONFIG" ] || return 1
    BP_LINE=$(grep -a -m1 '^name=music_volume,' "$BP_CARCONFIG") || return 1
    case "$BP_LINE" in *"current=15,"*) return 0 ;; esac
    [ -f "$BP_CARCONFIG_BAK" ] || cp -p "$BP_CARCONFIG" "$BP_CARCONFIG_BAK"
    BP_TMP=/data/local/tmp/bp_car.config.$$
    sed '/^name=music_volume,/ s/current=[0-9]*,/current=15,/' "$BP_CARCONFIG" > "$BP_TMP" || return 1
    cat "$BP_TMP" > "$BP_CARCONFIG"
    rm -f "$BP_TMP"
    return 2
}
