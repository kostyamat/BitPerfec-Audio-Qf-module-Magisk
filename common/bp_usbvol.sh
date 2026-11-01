#!/system/bin/sh
# The USB DAC's level (usb_dac=1). Started by service.sh as "sh bp_usbvol.sh watch"; sources bp_usb.sh.
#
# Android sends the DAC full scale, always: STREAM_MUSIC at its maximum on the USB device (AudioService keeps
# a separate index per device - it was 10/15 on stand 194, a digital cut before a 16-bit DAC). The level is
# set inside the DAC, by its own USB volume control ("PCM Playback Volume", 0..128 on a PCM2704) - after the
# full 16-bit word has reached it, as BU32107 does it for the head unit.
#
# usb_dac_volume=full    the DAC at its maximum; the level belongs to the amplifier. Default (unity gain).
# usb_dac_volume=follow  the DAC follows the head unit's volume knob: sys.media.vol 0..32 -> 0..max of the
#                        DAC's control, linear in its steps (PCM2704: 4 units = ~2 dB a knob step ❓ unit not
#                        measured), sys.mute.state or 0 = the DAC's switch off. A DAC without its own control
#                        does not follow: AudioFlinger never cuts the DAC's signal (owner 01.11: «об'їзжаємо для
#                        цап флінжер повність, а якщо цап має власну систему регулювання підсилення - вішаємося на
#                        неї, - немає - значить немає»).
# Ignition off (sys.qf.is.acc.on=false): the DAC's switch off and control at 0 until the ignition is back.
# The head unit's own level is not touched: that is wDSP's (AUDIO_PATH_AND_MODULE_CONTRACT).

BP_USBVOL_PID=/data/local/tmp/bp_usbvol.pid
# IAudioService 10 = setStreamVolume(stream, index, flags, caller) on every QF Android 10 build we have
# (🔬 framework.jar of stand 194, 7862 update(2), 8581 QF005 + BMW).
BP_USBVOL_TX=10

bp_usbvol_wanted() {
    BPV_V=$(grep -m1 '^[[:space:]]*usb_dac_volume[[:space:]]*=' "$BP_CONF" 2>/dev/null | cut -d= -f2 | tr -d ' \r\t')
    [ "$BPV_V" = follow ] && echo follow || echo full
}

# The first plugged USB card: "N MAX" when it has its own volume control, "N" when it has none, "" if none.
bp_usbvol_card() {
    for BPV_U in /proc/asound/card*/usbid; do
        [ -f "$BPV_U" ] || continue
        BPV_C=${BPV_U#/proc/asound/card}; BPV_C=${BPV_C%%/*}
        BPV_M=$(tinymix -D "$BPV_C" 'PCM Playback Volume' 2>/dev/null | sed -n 's/.*range 0->\([0-9]*\).*/\1/p')
        echo "$BPV_C $BPV_M"
        return 0
    done
}

# Android's music index on the USB device. setStreamVolume acts on the device the stream plays to, so it is
# sent only while the policy lists a USB output (media then goes there); flags 0 = no volume panel.
bp_usbvol_index() {
    dumpsys media.audio_policy 2>/dev/null | awk '/Available output devices/ { on = 1; next }
        /Available input devices/ { on = 0 } on && /type: AUDIO_DEVICE_OUT_USB/ { f = 1 } END { exit !f }' || return 1
    service call audio $BP_USBVOL_TX i32 3 i32 "$1" i32 0 s16 com.radiorubka.bitperfect >/dev/null 2>&1
}

bp_usbvol_watch() {
    echo $$ > "$BP_USBVOL_PID"
    BPV_LAST=""; BPV_STAMP=""; BPV_CARD=""
    while [ "$(cat "$BP_USBVOL_PID" 2>/dev/null)" = $$ ]; do
        if [ "$(bp_usb_wanted)" != 1 ]; then BPV_LAST=""; sleep 3; continue; fi
        # the card is looked up again only when /proc/asound changes (plug, unplug)
        BPV_S=$(ls /proc/asound 2>/dev/null | tr '\n' ' ')
        if [ "$BPV_S" != "$BPV_STAMP" ]; then
            BPV_STAMP=$BPV_S; BPV_CARD=$(bp_usbvol_card); BPV_LAST=""
            BPV_MAXI=$(service call audio 17 i32 3 2>/dev/null | sed -n 's/.*Parcel(00000000 \([0-9a-f]*\).*/\1/p')
            BPV_MAXI=$((0x${BPV_MAXI:-f}))
        fi
        set -- $BPV_CARD
        if [ -z "$1" ]; then BPV_LAST=""; sleep 2; continue; fi
        # an unset sys.media.vol (after boot, before the first knob turn) is the platform's
        # persist.sys.main_volume, as the platform itself reads it (qf-platform 08) - never full scale
        BPV_VOL=$(getprop sys.media.vol)
        case "$BPV_VOL" in ''|*[!0-9]*) BPV_VOL=$(getprop persist.sys.main_volume) ;; esac
        case "$BPV_VOL" in ''|*[!0-9]*) BPV_VOL=0 ;; esac
        [ "$BPV_VOL" -gt 32 ] && BPV_VOL=32
        [ "$(getprop sys.mute.state)" = true ] && BPV_VOL=0
        BPV_IDX=$BPV_MAXI; BPV_HW=${2:-}; BPV_SW=""
        [ -n "$2" ] && BPV_SW=1
        if [ -n "$2" ] && [ "$(bp_usbvol_wanted)" = follow ]; then
            BPV_HW=$((BPV_VOL * $2 / 32)); [ "$BPV_VOL" = 0 ] && BPV_SW=0
        fi
        # Ignition off: the DAC goes silent until it is back on. While the unit counts down to sleep, system_server
        # plays a tick every second (stream ALARM, 📻 stand 194 01.11: QFSleepWakeup «Delay seconds before go to
        # sleep», ten ticks) - through the DAC that is a loud beep a second (owner: «починає голосно пікати,
        # кожну секунду, ніби таймер»). The player is stopped by the platform a few seconds later anyway.
        if [ -n "$2" ] && [ "$(getprop sys.qf.is.acc.on)" = false ]; then BPV_HW=0; BPV_SW=0; fi
        # a new audioserver starts from its own state: apply again
        BPV_WANT="$BPV_IDX ${BPV_HW:--} ${BPV_SW:--} $(pidof audioserver)"
        if [ "$BPV_WANT" != "$BPV_LAST" ]; then
            [ -n "$BPV_HW" ] && tinymix -D "$1" 'PCM Playback Volume' "$BPV_HW" "$BPV_HW" >/dev/null 2>&1
            [ -n "$BPV_SW" ] && tinymix -D "$1" 'PCM Playback Switch' "$BPV_SW" >/dev/null 2>&1
            if bp_usbvol_index "$BPV_IDX"; then BPV_LAST=$BPV_WANT; else BPV_LAST=""; sleep 3; fi
        fi
        sleep 0.5
    done
}

case "$1" in
    watch)
        . "${0%/*}/bp_usb.sh"
        bp_usbvol_watch ;;
esac
