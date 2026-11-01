#!/system/bin/sh
# The USB DAC's level (usb_dac=1). Started by service.sh as "sh bp_usbvol.sh watch"; sources bp_usb.sh.
#
# Android sends the DAC full scale, always: STREAM_MUSIC at its maximum on the USB device (AudioService keeps
# a separate index per device - it was 10/15 on stand 194, a digital cut before a 16-bit DAC). The level is
# set inside the DAC, by its own USB volume control - after the full 16-bit word has reached it, as BU32107
# does it for the head unit. Every DAC names and scales that control its own way, so all of it is read from
# the DAC: which control, how many steps (128, 64, 32... or none), and the dB range the driver reports.
#
# usb_dac_volume=full    the DAC at its maximum; the level belongs to the amplifier. Default (unity gain).
# usb_dac_volume=follow  the DAC follows the head unit's volume knob through a curve; sys.media.vol 0 or
#                        sys.mute.state = the DAC's switch off. A DAC without its own control does not follow:
#                        AudioFlinger never cuts the DAC's signal (owner 01.11: «об'їзжаємо для цап флінжер
#                        повність, а якщо цап має власну систему регулювання підсилення - вішаємося на неї,
#                        - немає - значить немає»).
# usb_dac_curve_<vid>_<pid>=a,b,c,d,e  per DAC model: where knob 1, 8, 16, 24, 32 land, in % of the control's
#                        range; straight lines between them. Unset: even in steps, the knob as it always was.
#                        Owner 02.11: «шкала Дб у кожного своя, у мене початок не чутливий, у гось таке буде в
#                        кінці. А в когось лінія.» The dB range the driver reports is NOT what comes out: 📻 PCM2704
#                        reports -128..0 dB in 128 steps, yet step 4 ("-124 dB", below the 16-bit floor) is an audible
#                        whisper and half the knob ("-64 dB") is normal listening (owner by ear). So no default may be
#                        derived from it: a curve computed from those dB put knob 3 above normal listening.
# Ignition off (sys.qf.is.acc.on=false): the DAC's switch off and control at 0 until the ignition is back.
# The head unit's own level is not touched: that is wDSP's (AUDIO_PATH_AND_MODULE_CONTRACT).

BP_USBVOL_PID=/data/local/tmp/bp_usbvol.pid
# IAudioService 10 = setStreamVolume(stream, index, flags, caller) on every QF Android 10 build we have
# (🔬 framework.jar of stand 194, 7862 update(2), 8581 QF005 + BMW).
BP_USBVOL_TX=10
BP_USBVOL_CURVE_DEFAULT="3 25 50 75 100"

bp_usbvol_wanted() {
    BPV_V=$(grep -m1 '^[[:space:]]*usb_dac_volume[[:space:]]*=' "$BP_CONF" 2>/dev/null | cut -d= -f2 | tr -d ' \r\t')
    [ "$BPV_V" = follow ] && echo follow || echo full
}

# The first plugged USB card's number, "" if none.
bp_usbvol_cardnum() {
    for BPV_U in /proc/asound/card*/usbid; do
        [ -f "$BPV_U" ] || continue
        BPV_C=${BPV_U#/proc/asound/card}; echo "${BPV_C%%/*}"
        return 0
    done
}

# Card $1's own playback volume control by name: the usual names first, else the first there is.
bp_usbvol_ctl() {
    BPV_L=$(tinymix -D "$1" -t 2>/dev/null | tr -d '\r' | awk -F'\t' '$4 ~ /Playback Volume$/ { print $4 }')
    for BPV_P in 'PCM Playback Volume' 'Master Playback Volume' 'Speaker Playback Volume' 'Headphone Playback Volume'; do
        echo "$BPV_L" | grep -qxF "$BPV_P" && { echo "$BPV_P"; return 0; }
    done
    echo "$BPV_L" | sed -n 1p
}

# Steps of control $2 on card $1: the top of its 0..N range, "" if it is not one.
bp_usbvol_max() {
    tinymix -D "$1" "$2" 2>/dev/null | sed -n 's/.*range 0->\([0-9]*\).*/\1/p'
}

# The first plugged USB card: "N MAX" when it has its own volume control, "N" when it has none, "" if none.
bp_usbvol_card() {
    BPV_N=$(bp_usbvol_cardnum)
    [ -n "$BPV_N" ] || return 0
    BPV_K=$(bp_usbvol_ctl "$BPV_N")
    [ -n "$BPV_K" ] && BPV_M=$(bp_usbvol_max "$BPV_N" "$BPV_K") || BPV_M=""
    echo "$BPV_N $BPV_M"
}

# The range control $2 of card $1 reports: "min max" in 1/100 dB, "" if the driver gives none.
bp_usbvol_db() {
    awk -v n="name=\"$2\"" 'index($0, n) { on = 1; next } on && /Volume:/ { print; exit }' "/proc/asound/card$1/usbmixer" 2>/dev/null |
        sed -n 's/.*dBmin=\(-*[0-9]*\), dBmax=\(-*[0-9]*\).*/\1 \2/p'
}

# The conf key of the model on card $1: usb_dac_curve_08bb_2704.
bp_usbvol_curve_key() {
    echo "usb_dac_curve_$(tr ':' '_' < "/proc/asound/card$1/usbid" 2>/dev/null | tr -d '\r')"
}

# The user's curve for card $1, spaces between the five values; "" if none.
bp_usbvol_curve_user() {
    grep -m1 "^[[:space:]]*$(bp_usbvol_curve_key "$1")[[:space:]]*=" "$BP_CONF" 2>/dev/null | cut -d= -f2 | tr -d ' \r\t' | tr ',' ' '
}

# Control value for knob $1 (1..32), control top $2, curve $3 (five values).
bp_usbvol_level() {
    BPV_KN=$1; BPV_TOP=$2
    set -- $3
    if [ "$BPV_KN" -le 8 ]; then BPV_LO=1; BPV_HI=8; BPV_A=$1; BPV_B=$2
    elif [ "$BPV_KN" -le 16 ]; then BPV_LO=8; BPV_HI=16; BPV_A=$2; BPV_B=$3
    elif [ "$BPV_KN" -le 24 ]; then BPV_LO=16; BPV_HI=24; BPV_A=$3; BPV_B=$4
    else BPV_LO=24; BPV_HI=32; BPV_A=$4; BPV_B=$5
    fi
    BPV_PC=$(( BPV_A * 100 + (BPV_B - BPV_A) * 100 * (BPV_KN - BPV_LO) / (BPV_HI - BPV_LO) ))
    echo $(( (BPV_PC * BPV_TOP + 5000) / 10000 ))
}

# 0 when "$1" is a curve we can use: five whole percents, none below the one before it.
bp_usbvol_curve_valid() {
    echo "$1" | grep -qE '^[0-9]{1,3}(,[0-9]{1,3}){4}$' || return 1
    BPV_PREV=0
    for BPV_X in $(echo "$1" | tr ',' ' '); do
        [ "$BPV_X" -le 100 ] && [ "$BPV_X" -ge "$BPV_PREV" ] || return 1
        BPV_PREV=$BPV_X
    done
}

# Android's music index on the USB device. setStreamVolume acts on the device the stream plays to, so it is
# sent only while the policy lists a USB output (media then goes there); flags 0 = no volume panel.
bp_usbvol_index() {
    dumpsys media.audio_policy 2>/dev/null | awk '/Available output devices/ { on = 1; next }
        /Available input devices/ { on = 0 } on && /type: AUDIO_DEVICE_OUT_USB/ { f = 1 } END { exit !f }' || return 1
    service call audio $BP_USBVOL_TX i32 3 i32 "$1" i32 0 s16 com.radiorubka.bitperfect >/dev/null 2>&1
}

# The knob as the platform reads it: an unset sys.media.vol (after boot, before the first turn) is
# persist.sys.main_volume (qf-platform 08), never full scale. 0 when muted.
bp_usbvol_knob() {
    BPV_VOL=$(getprop sys.media.vol)
    case "$BPV_VOL" in ''|*[!0-9]*) BPV_VOL=$(getprop persist.sys.main_volume) ;; esac
    case "$BPV_VOL" in ''|*[!0-9]*) BPV_VOL=0 ;; esac
    [ "$BPV_VOL" -gt 32 ] && BPV_VOL=32
    [ "$(getprop sys.mute.state)" = true ] && BPV_VOL=0
    echo "$BPV_VOL"
}

bp_usbvol_watch() {
    echo $$ > "$BP_USBVOL_PID"
    BPV_LAST=""; BPV_STAMP=""; BPV_NUM=""; BPV_TOP_HW=""; BPV_CTL=""
    while [ "$(cat "$BP_USBVOL_PID" 2>/dev/null)" = $$ ]; do
        if [ "$(bp_usb_wanted)" != 1 ]; then BPV_LAST=""; sleep 3; continue; fi
        # the card is looked up again only when /proc/asound changes (plug, unplug)
        BPV_S=$(ls /proc/asound 2>/dev/null | tr '\n' ' ')
        if [ "$BPV_S" != "$BPV_STAMP" ]; then
            BPV_STAMP=$BPV_S; BPV_LAST=""; BPV_TOP_HW=""; BPV_CTL=""
            BPV_NUM=$(bp_usbvol_cardnum)
            if [ -n "$BPV_NUM" ]; then
                BPV_CTL=$(bp_usbvol_ctl "$BPV_NUM")
                [ -n "$BPV_CTL" ] && BPV_TOP_HW=$(bp_usbvol_max "$BPV_NUM" "$BPV_CTL")
            fi
            BPV_MAXI=$(service call audio 17 i32 3 2>/dev/null | sed -n 's/.*Parcel(00000000 \([0-9a-f]*\).*/\1/p')
            BPV_MAXI=$((0x${BPV_MAXI:-f}))
        fi
        if [ -z "$BPV_NUM" ]; then BPV_LAST=""; sleep 2; continue; fi
        BPV_VOL=$(bp_usbvol_knob)
        BPV_HW=$BPV_TOP_HW; BPV_SW=""
        [ -n "$BPV_TOP_HW" ] && BPV_SW=1
        if [ -n "$BPV_TOP_HW" ] && [ "$(bp_usbvol_wanted)" = follow ]; then
            if [ "$BPV_VOL" = 0 ]; then
                BPV_HW=0; BPV_SW=0
            else
                BPV_CUR=$(bp_usbvol_curve_user "$BPV_NUM")
                BPV_HW=$(bp_usbvol_level "$BPV_VOL" "$BPV_TOP_HW" "${BPV_CUR:-$BP_USBVOL_CURVE_DEFAULT}")
            fi
        fi
        # Ignition off: the DAC goes silent until it is back on. While the unit counts down to sleep, system_server
        # plays a tick every second (stream ALARM, 📻 stand 194 01.11: QFSleepWakeup «Delay seconds before go to
        # sleep», ten ticks) - through the DAC that is a loud beep a second (owner: «починає голосно пікати,
        # кожну секунду, ніби таймер»). The player is stopped by the platform a few seconds later anyway.
        if [ -n "$BPV_TOP_HW" ] && [ "$(getprop sys.qf.is.acc.on)" = false ]; then BPV_HW=0; BPV_SW=0; fi
        # a new audioserver starts from its own state: apply again
        BPV_WANT="$BPV_MAXI ${BPV_HW:--} ${BPV_SW:--} $(pidof audioserver)"
        if [ "$BPV_WANT" != "$BPV_LAST" ]; then
            [ -n "$BPV_HW" ] && tinymix -D "$BPV_NUM" "$BPV_CTL" "$BPV_HW" >/dev/null 2>&1
            [ -n "$BPV_SW" ] && tinymix -D "$BPV_NUM" "${BPV_CTL%Volume}Switch" "$BPV_SW" >/dev/null 2>&1
            if bp_usbvol_index "$BPV_MAXI"; then BPV_LAST=$BPV_WANT; else BPV_LAST=""; sleep 3; fi
        fi
        sleep 0.5
    done
}

case "$1" in
    watch)
        . "${0%/*}/bp_usb.sh"
        bp_usbvol_watch ;;
esac
