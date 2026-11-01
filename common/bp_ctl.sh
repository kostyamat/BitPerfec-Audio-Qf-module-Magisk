#!/system/bin/sh
# The one entry point BitPerfect Control uses (as root: su -c sh <module>/common/bp_ctl.sh <cmd> ...).
# The app never touches the module's files itself; every action goes through the same helpers the
# installer and service.sh use, so there is one place for each rule.
#
#   status            print key=value lines: what the unit is and what the module is doing
#   usb <0|1>         set usb_dac in /sdcard/BitPerfectAudio/bitperfect.conf, switch the policy include,
#                     restart audioserver when it changed (prints usb_result=changed|same|unsupported)
#   usb_mode <auto|FORMAT/RATE>   set usb_dac_mode (e.g. S16_LE/44100, as the DAC declares it) and the USB
#                     policy; restarts audioserver when USB is on (usb_mode_result=changed|saved|same|bad_value)
#   usb_volume <full|follow>   set usb_dac_volume: the DAC at full scale, or its own volume control following
#                     the head unit's knob (common/bp_usbvol.sh watches it; no restart; a DAC without a control
#                     stays at full scale) (usb_volume_result=saved|bad_value); status: usb_volume=, usb_dac_volctl=MAX|none
#   mic show | mic set <SIM|VOIP|BT> <gain_db|aec|nr|nr_depth> [value] | mic reset <channel>
#   mic preset list | mic preset <save|load|del> <name>
#                     the user's call-mic settings (UIS7862, common/bp_mic.sh); a change rebuilds the AGDSP XML
#                     and restarts audioserver, never during a call
#                     (mic_result=changed|same|saved_in_call|saved|bad_value|no_preset; preset=<name> per line)
#   navi list         navi=<package> <adjust> <mix> <factory|bitperfect|user>, one per navigator
#   navi set <pkg> <true|false> <appset|0-100>   / navi del <pkg>
#                     edit the user's navigators.conf and rebuild the live list (prints
#                     navi_result=saved|bad_value|no_base); the platform reads it at boot - reboot

MODDIR=/data/adb/modules/BitPerfect.module
. "$MODDIR/common/bp_usb.sh"
. "$MODDIR/common/bp_naviapp.sh"
. "$MODDIR/common/bp_mic.sh"
. "$MODDIR/common/bp_usbvol.sh"
USBPOL="$MODDIR/system/vendor/etc/usb_audio_policy_configuration.xml"
NAVI_BASE="$MODDIR/common/NaviApp.base.ini"
NAVI_LIVE="$MODDIR/system/config/NaviApp.ini"
APC="$MODDIR/system/vendor/etc/audio_policy_configuration.xml"

# Rewrite <key>=<value> in the settings file (created with its explanation if missing). In place, so
# the file keeps the owner's other lines and comments. Values are checked by the caller.
bp_conf_set_key() {
    bp_conf_ensure
    T=/data/local/tmp/bp_conf.$$
    if grep -q "^[[:space:]]*$1[[:space:]]*=" "$BP_CONF"; then
        sed "s#^[[:space:]]*$1[[:space:]]*=.*#$1=$2#" "$BP_CONF" > "$T" && cat "$T" > "$BP_CONF"
    else
        cat "$BP_CONF" > "$T" && echo "$1=$2" >> "$T" && cat "$T" > "$BP_CONF"
    fi
    rm -f "$T"
}

# Restart audioserver and return only when the new one serves the policy again (<= 15 s), so the
# caller's next status already shows the new routing. With the USB DAC output on, a plugged DAC the new
# policy does not list is announced again (bp_usb_announce) - else it stays silent until replugged.
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
    [ "$(bp_usb_state "$APC")" = 1 ] && bp_usb_announce | while read -r l; do echo "usb_announced=$l"; done
}

# Rebuild the call-mic XML from mic.conf and restart audioserver - but a call would not survive the restart:
# then the setting is only kept, and applied after the call (next change) or at boot (service.sh).
bp_mic_apply() {
    if [ "$(getprop sys.qf.call_state)" = true ]; then echo "mic_result=saved_in_call"; return 0; fi
    bp_mic_build "$MODDIR"
    case $? in
        0) bp_restart_audioserver; echo "mic_result=changed" ;;
        *) echo "mic_result=same" ;;
    esac
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
        # Every sound card as it names itself: card=<cardN> <usb|internal> <usbid|-> <name>
        # (a USB DAC's name and id are its own descriptors; the internal one is the kernel driver's)
        tr -d '\r' < /proc/asound/cards | awk '
            /^ *[0-9]+ \[/ { n = $1; next }
            n != "" { sub(/^ +/, ""); sub(/ at usb-.*/, ""); print n "\t" $0; n = "" }' | while IFS="$(printf '\t')" read -r n name; do
            if [ -f "/proc/asound/card$n/usbid" ]; then
                echo "card=card$n usb $(cat /proc/asound/card$n/usbid) $name"
            else
                echo "card=card$n internal - $name"
            fi
        done
        bp_usb_caps | while read -r c f ch r; do echo "usb_caps=$c $f $ch $r"; done
        echo "usb_mode=$(bp_usb_mode_wanted)"
        echo "usb_mode_state=$(bp_usb_mode_state "$USBPOL")"
        echo "usb_volume=$(bp_usbvol_wanted)"
        echo "usb_dac_volctl=$(bp_usbvol_card | awk '{ print ($2 == "" ? "none" : $2) }')"
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
        bp_conf_set_key usb_dac "$2"
        bp_usb_set "$APC" "$2"
        case $? in
            0) bp_restart_audioserver; echo "usb_result=changed" ;;
            2) echo "usb_result=same" ;;
            *) echo "usb_result=unsupported" ;;
        esac
        ;;
    usb_volume)
        case "$2" in full|follow) ;; *) echo "usb_volume_result=bad_value"; exit 1 ;; esac
        bp_conf_set_key usb_dac_volume "$2"
        echo "usb_volume_result=saved"
        ;;
    usb_mode)
        bp_usb_mode_valid "$2" || { echo "usb_mode_result=bad_value"; exit 1; }
        bp_conf_set_key usb_dac_mode "$2"
        bp_usb_mode_set "$USBPOL" "$2"
        case $? in
            0) if [ "$(bp_usb_state "$APC")" = 1 ]; then bp_restart_audioserver; echo "usb_mode_result=changed"
               else echo "usb_mode_result=saved"; fi ;;
            2) echo "usb_mode_result=same" ;;
            *) echo "usb_mode_result=unsupported" ;;
        esac
        ;;
    mic)
        # mic show: mic=<channel> <gain_db> <aec> <nr> <nr_depth>   mic set <channel> <control> [value]
        # (no value = BitPerfect's)
        case "$2" in
            show) bp_mic_show | while read -r l; do echo "mic=$l"; done ;;
            set)
                bp_mic_set "$3" "$4" "$5" || { echo "mic_result=bad_value"; exit 1; }
                bp_mic_apply ;;
            reset)
                bp_mic_reset "$3" || { echo "mic_result=bad_value"; exit 1; }
                bp_mic_apply ;;
            preset)
                case "$3" in
                    list) bp_mic_preset list | while read -r l; do echo "preset=$l"; done ;;
                    save|del)
                        bp_mic_preset "$3" "$4"
                        case $? in
                            0) echo "mic_result=saved" ;;
                            3) echo "mic_result=no_preset" ;;
                            *) echo "mic_result=bad_value"; exit 1 ;;
                        esac ;;
                    load)
                        bp_mic_preset load "$4"
                        case $? in
                            0) bp_mic_apply ;;
                            3) echo "mic_result=no_preset" ;;
                            *) echo "mic_result=bad_value"; exit 1 ;;
                        esac ;;
                    *) echo "mic_result=bad_value"; exit 1 ;;
                esac
                ;;
            *) echo "mic_result=bad_value"; exit 1 ;;
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
