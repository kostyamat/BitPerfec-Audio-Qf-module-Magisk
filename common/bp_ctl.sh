#!/system/bin/sh
# The one entry point BitPerfect Control uses (as root: su -c sh <module>/common/bp_ctl.sh <cmd> ...).
# The app never touches the module's files itself; every action goes through the same helpers the
# installer and service.sh use, so there is one place for each rule.
#
#   status            print key=value lines: what the unit is and what the module is doing
#   usb <0|1>         set usb_dac in /sdcard/BitPerfectAudio/bitperfect.conf, switch the policy include,
#                     restart audioserver when it changed (prints usb_result=changed|same|unsupported)

MODDIR=/data/adb/modules/BitPerfect.module
. "$MODDIR/common/bp_usb.sh"
APC="$MODDIR/system/vendor/etc/audio_policy_configuration.xml"

# Rewrite usb_dac=<v> in the settings file (created with its explanation if missing). In place, so the
# file keeps the owner's other lines and comments.
bp_conf_set_usb() {
    bp_conf_ensure
    T=/data/local/tmp/bp_conf.$$
    if grep -q '^[[:space:]]*usb_dac[[:space:]]*=' "$BP_CONF"; then
        sed "s/^[[:space:]]*usb_dac[[:space:]]*=.*/usb_dac=$1/" "$BP_CONF" > "$T" && cat "$T" > "$BP_CONF"
    else
        cat "$BP_CONF" > "$T" && echo "usb_dac=$1" >> "$T" && cat "$T" > "$BP_CONF"
    fi
    rm -f "$T"
}

case "$1" in
    status)
        echo "platform=$(getprop ro.board.platform)"
        echo "module_version=$(grep -m1 '^version=' "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)"
        echo "module_disabled=$([ -f "$MODDIR/disable" ] && echo 1 || echo 0)"
        echo "enabled=$(getprop sys.bitperfect.enabled)"
        echo "nav_policy=$([ -f "$MODDIR/bp_nav_policy" ] && echo 1 || echo 0)"
        echo "mcu=$(getprop persist.sys.qf.mcu.version)"
        echo "i2s=$(getprop persist.sys.qf.arm.use.i2s)"
        echo "default_volume=$(getprop persist.qf.arm.default.volume)"
        echo "usb_wanted=$(bp_usb_wanted)"
        echo "usb_state=$(bp_usb_state "$APC")"
        W=$(tinymix VBC_IIS_MST_WIDTH_SET 2>/dev/null | tail -1)
        echo "i2s_width=$W"
        for s in /proc/asound/card*/pcm*p/sub0; do
            grep -q RUNNING "$s/status" 2>/dev/null || continue
            echo "playing=$s $(grep -E '^(format|rate|channels):' "$s/hw_params" 2>/dev/null | awk '{print $2}' | tr '\n' ' ')"
        done
        ;;
    usb)
        case "$2" in 0|1) ;; *) echo "usb_result=bad_value"; exit 1 ;; esac
        bp_conf_set_usb "$2"
        bp_usb_set "$APC" "$2"
        case $? in
            0) setprop ctl.restart audioserver; echo "usb_result=changed" ;;
            2) echo "usb_result=same" ;;
            *) echo "usb_result=unsupported" ;;
        esac
        ;;
    *)
        echo "usage: bp_ctl.sh status | usb <0|1>"
        exit 1
        ;;
esac
