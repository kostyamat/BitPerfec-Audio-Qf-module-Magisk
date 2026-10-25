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

# Who owns the default level. On UIS7862 music_volume is visible=0 - no slider - so it is ours.
# On UIS8581 it is visible=1, default 14: the "default volume" slider in car settings. A slider the
# owner can see is his choice and is never pinned (the same rule as persist.sys.main_volume above
# in service.sh). A missing line (CarSettings rewrote the file, 18.10 on the bench) is not a slider.
# Returns 0 = ours (pin it), 1 = the user's.
bp_level_is_ours() {
    BP_LINE=$(grep -a -m1 '^name=music_volume,' "$BP_CARCONFIG" 2>/dev/null)
    case "$BP_LINE" in
        *"visible=1"*) return 1 ;;
        "") [ "$(getprop ro.board.platform)" = "ums512" ] || return 1 ;;  # unknown elsewhere: hands off
    esac
    return 0
}

# returns 0 = already 15, 2 = changed, 1 = file or line missing, 3 = the user's slider (left alone)
bp_pin_music_volume() {
    [ -f "$BP_CARCONFIG" ] || return 1
    BP_LINE=$(grep -a -m1 '^name=music_volume,' "$BP_CARCONFIG") || return 1
    bp_level_is_ours || return 3
    case "$BP_LINE" in *"current=15,"*) return 0 ;; esac
    [ -f "$BP_CARCONFIG_BAK" ] || cp -p "$BP_CARCONFIG" "$BP_CARCONFIG_BAK"
    BP_TMP=/data/local/tmp/bp_car.config.$$
    sed '/^name=music_volume,/ s/current=[0-9]*,/current=15,/' "$BP_CARCONFIG" > "$BP_TMP" || return 1
    cat "$BP_TMP" > "$BP_CARCONFIG"
    rm -f "$BP_TMP"
    return 2
}
