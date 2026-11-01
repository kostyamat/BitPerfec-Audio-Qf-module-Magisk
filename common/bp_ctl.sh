#!/system/bin/sh
# The one entry point BitPerfect Control uses (as root: su -c sh <module>/common/bp_ctl.sh <cmd> ...).
# The app never touches the module's files itself; every action goes through the same helpers the
# installer and service.sh use, so there is one place for each rule.
#
#   status            print key=value lines: what the unit is and what the module is doing
#   usb <0|1>         set usb_dac in /sdcard/BitPerfectAudio/bitperfect.conf, switch the policy include,
#                     restart audioserver when it changed (prints usb_result=changed|same|unsupported)
#   navi list         navi=<package> <adjust> <mix> <factory|bitperfect|user>, one per navigator
#   navi set <pkg> <true|false> <appset|0-100>   / navi del <pkg>
#                     edit the user's navigators.conf and rebuild the live list (prints
#                     navi_result=saved|bad_value|no_base); the platform reads it at boot - reboot

MODDIR=/data/adb/modules/BitPerfect.module
. "$MODDIR/common/bp_usb.sh"
. "$MODDIR/common/bp_naviapp.sh"
NAVI_BASE="$MODDIR/common/NaviApp.base.ini"
NAVI_LIVE="$MODDIR/system/config/NaviApp.ini"
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

# Restart audioserver and return only when the new one serves the policy again (<= 15 s), so the
# caller's next status already shows the new routing.
bp_restart_audioserver() {
    OLD=$(pidof audioserver)
    setprop ctl.restart audioserver
    i=0
    while [ $i -lt 30 ]; do
        sleep 0.5; i=$((i + 1))
        NEW=$(pidof audioserver)
        [ -n "$NEW" ] && [ "$NEW" != "$OLD" ] && service check media.audio_policy | grep -q ': found' && break
    done
    sleep 1
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
        # What really plays now: playing=<usb|internal> <cardN/pcmMp> <format> <channels> <rate>, one per running PCM
        for s in /proc/asound/card*/pcm*p/sub0; do
            grep -q RUNNING "$s/status" 2>/dev/null || continue
            C=${s#/proc/asound/}; C=${C%%/*}
            K=internal; [ -f "/proc/asound/$C/usbid" ] && K=usb
            P=${s%/sub0}; P=${P##*/}
            echo "playing=$K $C/$P $(grep -E '^(format|channels|rate):' "$s/hw_params" 2>/dev/null | awk '{print $2}' | tr '\n' ' ')"
        done
        ;;
    usb)
        case "$2" in 0|1) ;; *) echo "usb_result=bad_value"; exit 1 ;; esac
        bp_conf_set_usb "$2"
        bp_usb_set "$APC" "$2"
        case $? in
            0) bp_restart_audioserver; echo "usb_result=changed" ;;
            2) echo "usb_result=same" ;;
            *) echo "usb_result=unsupported" ;;
        esac
        ;;
    navi)
        case "$2" in
            list)
                USERS=" $( [ -f "$BP_NAVI_USER" ] && tr -d '\r' < "$BP_NAVI_USER" | awk '$1 !~ /^#/ && NF >= 3 {print $1}' | tr '\n' ' ') "
                OURS=" $BP_NAVI_ON $BP_NAVI_ADD "
                tr -d '\r' < "$NAVI_LIVE" | awk '$1 !~ /^#/ && NF >= 3 {print $1, $2, $3}' | while read -r p a m; do
                    O=factory
                    case "$OURS" in *" $p "*) O=bitperfect ;; esac
                    case "$USERS" in *" $p "*) O=user ;; esac
                    echo "navi=$p $a $m $O"
                done
                ;;
            set|del)
                [ -f "$NAVI_BASE" ] || { echo "navi_result=no_base"; exit 1; }
                if [ "$2" = set ]; then
                    bp_navi_user_set "$3" "$4" "$5" || { echo "navi_result=bad_value"; exit 1; }
                else
                    bp_navi_user_set "$3" ""
                fi
                bp_naviapp_live "$NAVI_BASE" "$NAVI_LIVE"
                echo "navi_result=saved"
                ;;
            *) echo "navi_result=bad_value"; exit 1 ;;
        esac
        ;;
    *)
        echo "usage: bp_ctl.sh status | usb <0|1> | navi list|set|del"
        exit 1
        ;;
esac
