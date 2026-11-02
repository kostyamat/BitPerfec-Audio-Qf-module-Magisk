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
#                        range, with decimals; a smooth rising line through them (monotone cubic, in float). Unset:
#                        even in steps, the knob as it always was. The person tunes it by ear; nothing is measured
#                        (owner 02.11: «Ми дали інструмент, - юзер бавиться»).
#                        Owner 02.11: «шкала Дб у кожного своя, у мене початок не чутливий, у гось таке буде в
#                        кінці. А в когось лінія.» The dB range the driver reports is NOT what comes out: 📻 PCM2704
#                        reports -128..0 dB in 128 steps, yet step 4 ("-124 dB", below the 16-bit floor) is an audible
#                        whisper and half the knob ("-64 dB") is normal listening (owner by ear). So no default may be
#                        derived from it: a curve computed from those dB put knob 3 above normal listening.
# Ignition off (sys.qf.is.acc.on=false): the DAC's switch off and control at 0 until the ignition is back.
# No polling of the knob: common/bp_propwait (native, __system_property_wait, 0 % CPU, source tools/native/) wakes
# this at the change, and the change is applied at once. inotifyd watches /dev/snd (a DAC plugged, 📻 stand 194: ~45 ms;
# /proc gives no such events) and the settings folder; init.svc.audioserver tells of a restart. A 5 s tick is the safety net.
# The head unit's own level is not touched: that is wDSP's (AUDIO_PATH_AND_MODULE_CONTRACT).

BP_USBVOL_PID=/data/local/tmp/bp_usbvol.pid
# IAudioService 10 = setStreamVolume(stream, index, flags, caller) on every QF Android 10 build we have
# (🔬 framework.jar of stand 194, 7862 update(2), 8581 QF005 + BMW).
BP_USBVOL_TX=10
BP_USBVOL_CURVE_DEFAULT="3.125 25 50 75 100"
# bp_ctl.sh changes this after writing the settings: the watcher reads them now, not at the next tick.
BP_USBVOL_POKE=sys.bitperfect.usbvol_poke

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

# Control value for knob $1 (1..32), control top $2, curve $3 (five values): a Fritsch-Carlson monotone cubic
# through knob 1, 8, 16, 24, 32 - it never overshoots between points, and even points give a straight line.
bp_usbvol_level() {
    echo "$1 $2 $3" | awk '{
        n = 5; split("1 8 16 24 32", x, " ")
        k = $1; top = $2
        for (i = 1; i <= n; i++) y[i] = $(i + 2)
        for (i = 1; i < n; i++) { h[i] = x[i + 1] - x[i]; d[i] = (y[i + 1] - y[i]) / h[i] }
        m[1] = d[1]; m[n] = d[n - 1]
        for (i = 2; i < n; i++) {
            if (d[i - 1] * d[i] <= 0) m[i] = 0
            else {
                a = 2 * h[i] + h[i - 1]; b = h[i] + 2 * h[i - 1]
                m[i] = (a + b) / (a / d[i - 1] + b / d[i])
            }
        }
        i = 1; while (i < n - 1 && k > x[i + 1]) i++
        t = (k - x[i]) / h[i]; t2 = t * t; t3 = t2 * t
        p = (2 * t3 - 3 * t2 + 1) * y[i] + (t3 - 2 * t2 + t) * h[i] * m[i] + (3 * t2 - 2 * t3) * y[i + 1] + (t3 - t2) * h[i] * m[i + 1]
        v = int(p * top / 100 + 0.5)
        if (v < 0) v = 0
        if (v > top) v = top
        print v
    }'
}

# 0 when "$1" is a curve we can use: five percents, each above the one before it (two points on one level would
# flatten the knob there), the last at most 100.
bp_usbvol_curve_valid() {
    echo "$1" | grep -qE '^[0-9]{1,3}(\.[0-9]{1,3})?(,[0-9]{1,3}(\.[0-9]{1,3})?){4}$' || return 1
    echo "$1" | tr ',' ' ' | awk '{ for (i = 2; i <= 5; i++) if ($i + 0 <= $(i - 1) + 0) exit 1; exit !($5 + 0 <= 100) }'
}

# Android's music index at full scale on the USB device. com.qf.framework sets it to the knob's number on every turn
# (📻 stand 194 02.11: index 5, 6 between our 15s), a digital dip until this puts it back, so it goes at once.
# setStreamVolume acts on the device the stream plays to, so it is sent only while the policy lists a USB output
# (media then goes there); that is asked once per audioserver. Flags 0 = no volume panel.
bp_usbvol_usb_listed() {
    dumpsys media.audio_policy 2>/dev/null | awk '/Available output devices/ { on = 1; next }
        /Available input devices/ { on = 0 } on && /type: AUDIO_DEVICE_OUT_USB/ { f = 1 } END { exit !f }'
}

bp_usbvol_index() {
    service call audio $BP_USBVOL_TX i32 3 i32 "$1" i32 0 s16 com.radiorubka.bitperfect >/dev/null 2>&1
}

# Puts the index back only if it is not at full scale. IAudioService 15 = getStreamVolume (same builds as above).
bp_usbvol_index_fix() {
    BPV_IX=$(service call audio 15 i32 3 2>/dev/null | sed -n 's/.*Parcel(00000000 \([0-9a-f]*\).*/\1/p')
    [ -n "$BPV_IX" ] && [ $((0x$BPV_IX)) != "$1" ] && bp_usbvol_index "$1"
}

# The knob: sys.media.vol $1, sys.mute.state $2, persist.sys.main_volume $3. An unset sys.media.vol (after boot, before
# the first turn) is the main volume (qf-platform 08), never full scale. 0 when muted.
bp_usbvol_knob_of() {
    BPV_VOL=$1
    case "$BPV_VOL" in ''|-|*[!0-9]*) BPV_VOL=$3 ;; esac
    case "$BPV_VOL" in ''|-|*[!0-9]*) BPV_VOL=0 ;; esac
    [ "$BPV_VOL" -gt 32 ] && BPV_VOL=32
    [ "$2" = true ] && BPV_VOL=0
    echo "$BPV_VOL"
}

bp_usbvol_knob() {
    bp_usbvol_knob_of "$(getprop sys.media.vol)" "$(getprop sys.mute.state)" "$(getprop persist.sys.main_volume)"
}

# inotifyd, Magisk's busybox first. Watching one file on /sdcard fails here (📻 Invalid argument), the folder works.
bp_usbvol_inotify() {
    BPV_NT=""
    [ -x /data/adb/magisk/busybox ] && BPV_NT="/data/adb/magisk/busybox inotifyd"
    [ -z "$BPV_NT" ] && command -v inotifyd >/dev/null 2>&1 && BPV_NT=inotifyd
    [ -n "$BPV_NT" ] && [ -d /dev/snd ] || return 1
    BPV_NW="/dev/snd:nd"
    [ -d "$BP_CONF_DIR" ] && BPV_NW="$BPV_NW $BP_CONF_DIR:w"
    $BPV_NT - $BPV_NW 2>/dev/null &
    return 0
}

# One line per event: "C|T vol mute acc main poke audioserver" from the properties (T = a quiet tick), anything else
# from inotifyd ("n<TAB>/dev/snd<TAB>pcmC1D0p").
bp_usbvol_events() {
    BPV_PROPS="sys.media.vol sys.mute.state sys.qf.is.acc.on persist.sys.main_volume $BP_USBVOL_POKE init.svc.audioserver"
    BPV_BIN="${0%/*}/bp_propwait"
    BPV_TICK=500
    bp_usbvol_inotify && BPV_TICK=5000
    [ -x "$BPV_BIN" ] && "$BPV_BIN" "$BPV_TICK" $BPV_PROPS
    # no native helper (or it could not run): the same lines, every half second
    while :; do
        BPV_L="T"
        for BPV_PN in $BPV_PROPS; do BPV_PV=$(getprop "$BPV_PN"); BPV_L="$BPV_L ${BPV_PV:--}"; done
        echo "$BPV_L"
        sleep 0.5
    done
}

bp_usbvol_watch() {
    echo $$ > "$BP_USBVOL_PID"
    BPV_ME=$$
    bp_usbvol_events | {
    BPV_STAMP=""; BPV_NUM=""; BPV_TOP_HW=""; BPV_CTL=""; BPV_LK=""; BPV_LV=""; BPV_AS=""; BPV_T=0; BPV_POKE=""
    BPV_LASTHW=""; BPV_LASTVOL=""; BPV_LISTED=""; BPV_ON=""; BPV_FOLLOW=full; BPV_CUR=""; BPV_MAXI=15; BPV_SVC=""
    BPV_PV=-; BPV_PM=-; BPV_ACC=-; BPV_PMAIN=-; BPV_PP=-; BPV_PS=-; BPV_SLOW=1
    while read -r BPV_E BPV_F1 BPV_F2 BPV_F3 BPV_F4 BPV_F5 BPV_F6; do
        case "$BPV_E" in
            C|T) BPV_PV=$BPV_F1; BPV_PM=$BPV_F2; BPV_ACC=$BPV_F3; BPV_PMAIN=$BPV_F4; BPV_PP=$BPV_F5; BPV_PS=$BPV_F6 ;;
            *) BPV_SLOW=1
               # a new card node can come a moment before its /proc entry: look once more just after
               BPV_T=$((BPV_T + 1))
               ( sleep 0.5; setprop "$BP_USBVOL_POKE" "d$BPV_T" ) & ;;
        esac
        # The settings, the card, audioserver: on an event from inotifyd, a poke from bp_ctl.sh, an audioserver state
        # change, a tick, and at the start.
        [ "$BPV_PP" != "$BPV_POKE" ] || [ "$BPV_PS" != "$BPV_SVC" ] || [ "$BPV_E" = T ] && BPV_SLOW=1
        if [ "$BPV_SLOW" = 1 ]; then
            BPV_SLOW=0
            BPV_POKE=$BPV_PP; BPV_SVC=$BPV_PS
            [ "$(cat "$BP_USBVOL_PID" 2>/dev/null)" = "$BPV_ME" ] || exit 0
            BPV_ON=$(bp_usb_wanted)
            if [ "$BPV_ON" != 1 ]; then BPV_LASTHW=""; BPV_LASTVOL=""; continue; fi
            # the card is looked up again only when /proc/asound changes (plug, unplug)
            BPV_S=$(ls /proc/asound 2>/dev/null | tr '\n' ' ')
            if [ "$BPV_S" != "$BPV_STAMP" ]; then
                BPV_STAMP=$BPV_S; BPV_LASTHW=""; BPV_LASTVOL=""; BPV_LISTED=""; BPV_TOP_HW=""; BPV_CTL=""; BPV_TRY=0
                BPV_NUM=$(bp_usbvol_cardnum)
                if [ -n "$BPV_NUM" ]; then
                    BPV_CTL=$(bp_usbvol_ctl "$BPV_NUM")
                    [ -n "$BPV_CTL" ] && BPV_TOP_HW=$(bp_usbvol_max "$BPV_NUM" "$BPV_CTL")
                fi
                BPV_MAXI=$(service call audio 17 i32 3 2>/dev/null | sed -n 's/.*Parcel(00000000 \([0-9a-f]*\).*/\1/p')
                BPV_MAXI=$((0x${BPV_MAXI:-f}))
            fi
            BPV_FOLLOW=$(bp_usbvol_wanted)
            [ -n "$BPV_NUM" ] && BPV_CUR=$(bp_usbvol_curve_user "$BPV_NUM")
            # a new audioserver starts from its own state: the index again
            BPV_A=$(pidof audioserver)
            if [ "$BPV_A" != "$BPV_AS" ]; then BPV_AS=$BPV_A; BPV_LASTVOL=""; BPV_LISTED=""; BPV_TRY=0; fi
            if [ -z "$BPV_LISTED" ] && [ -n "$BPV_NUM" ]; then
                if bp_usbvol_usb_listed; then
                    BPV_LISTED=1; BPV_LASTVOL=""; BPV_TRY=0
                elif [ "${BPV_TRY:-0}" -lt 30 ]; then
                    # Android announces the DAC a few seconds after it appears: ask each second, for a while
                    BPV_TRY=$((${BPV_TRY:-0} + 1))
                    ( sleep 1; setprop "$BP_USBVOL_POKE" "l$BPV_TRY" ) &
                fi
            fi
            [ -n "$BPV_LISTED" ] && [ "$BPV_E" = T ] && bp_usbvol_index_fix "$BPV_MAXI"
        fi
        [ "$BPV_ON" = 1 ] && [ -n "$BPV_NUM" ] || continue
        BPV_VOL=$(bp_usbvol_knob_of "$BPV_PV" "$BPV_PM" "$BPV_PMAIN")
        BPV_HW=$BPV_TOP_HW; BPV_SW=1
        if [ -n "$BPV_TOP_HW" ] && [ "$BPV_FOLLOW" = follow ]; then
            if [ "$BPV_VOL" = 0 ]; then
                BPV_HW=0; BPV_SW=0
            else
                # awk only when the knob or the curve moved
                BPV_K2="$BPV_VOL $BPV_TOP_HW $BPV_CUR"
                if [ "$BPV_K2" != "$BPV_LK" ]; then
                    BPV_LK=$BPV_K2
                    BPV_LV=$(bp_usbvol_level "$BPV_VOL" "$BPV_TOP_HW" "${BPV_CUR:-$BP_USBVOL_CURVE_DEFAULT}")
                fi
                BPV_HW=$BPV_LV
            fi
        fi
        # Ignition off: the DAC goes silent until it is back on. While the unit counts down to sleep, system_server
        # plays a tick every second (stream ALARM, 📻 stand 194 01.11: QFSleepWakeup «Delay seconds before go to
        # sleep», ten ticks) - through the DAC that is a loud beep a second (owner: «починає голосно пікати,
        # кожну секунду, ніби таймер»). The player is stopped by the platform a few seconds later anyway.
        if [ -n "$BPV_TOP_HW" ] && [ "$BPV_ACC" = false ]; then BPV_HW=0; BPV_SW=0; fi
        # At once, no ramp (owner 02.11: «хотілося б максимально оперативно»). 📻 The DAC gets power only when
        # QFSleepWakeup sets USB host mode (+22 s on stand 194), first sound +44 s: this is in place before it.
        if [ -n "$BPV_TOP_HW" ] && [ "$BPV_HW $BPV_SW" != "$BPV_LASTHW" ]; then
            [ -z "$BPV_LASTHW" ] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [up:$(cut -d' ' -f1 /proc/uptime)s] USB DAC level set: knob $BPV_VOL, $BPV_CTL $BPV_HW of $BPV_TOP_HW." >> /data/adb/BitPerfect.log
            if [ "$BPV_SW" = 0 ]; then
                tinymix -D "$BPV_NUM" "${BPV_CTL%Volume}Switch" 0 >/dev/null 2>&1
                tinymix -D "$BPV_NUM" "$BPV_CTL" "$BPV_HW" >/dev/null 2>&1
            else
                tinymix -D "$BPV_NUM" "$BPV_CTL" "$BPV_HW" >/dev/null 2>&1
                tinymix -D "$BPV_NUM" "${BPV_CTL%Volume}Switch" 1 >/dev/null 2>&1
            fi
            BPV_LASTHW="$BPV_HW $BPV_SW"
        fi
        # The framework rewrites the index on every knob turn, in either mode, and may do so just after the property
        # changed: now, and twice more shortly after. The tick above catches anything later.
        if [ -n "$BPV_LISTED" ] && [ "$BPV_VOL" != "$BPV_LASTVOL" ]; then
            BPV_LASTVOL=$BPV_VOL
            bp_usbvol_index "$BPV_MAXI"
            ( sleep 0.15; bp_usbvol_index_fix "$BPV_MAXI"; sleep 0.3; bp_usbvol_index_fix "$BPV_MAXI" ) &
        fi
    done
    }
}

case "$1" in
    watch)
        . "${0%/*}/bp_usb.sh"
        bp_usbvol_watch ;;
esac
