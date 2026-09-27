#!/system/bin/sh
MODPATH=${0%/*}
LOGFILE="/data/adb/BitPerfect.log"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [up:$(cat /proc/uptime | awk '{print $1}')s] $1" >> "$LOGFILE"
}

log_msg "=== BitPerfect Universal v5.3 Service Starting ==="

MCU_VER=$(resetprop persist.sys.qf.mcu.version 2>/dev/null)
HW_CODE=$(echo "$MCU_VER" | awk -F'.' '{print $NF}')

# Suffix layout, from factory code (McuVersionUtils.parseMcuVersion + ProductInfoConstants):
#   [1] sound processor  0=BU32107 1=BD37534 2=AK7738 3=AK7604
#   [2] tuner            [3] output path  0=analogue 1=IIS
#   [4] control panel    [5] power bitmask
#
# Up to v5.2 this file used ${HW_CODE:4:2} == "21" to mean "BU32107". Characters 4-5 are the
# control panel and the power bitmask; they read "21" on every firmware we have, BU and BD alike.
# So the guard below fired on ANALOGUE units too, forcing a 24-bit I2S bus width every three
# seconds on hardware that has no I2S bus at all.
SOUND_CHIP=${HW_CODE:1:1}
MPU_MODE=${HW_CODE:3:1}
RADIO_CHIP=${HW_CODE:2:1}

# Prefer the platform's own answer - the audio HAL parses the same string and publishes it.
I2S_PROP=$(getprop persist.sys.qf.arm.use.i2s)
HAS_I2S=no
if [ "$I2S_PROP" = "true" ] || [ "$MPU_MODE" = "1" ]; then
    HAS_I2S=yes
fi
if [ "$SOUND_CHIP" = "1" ]; then      # BD37534: analogue inputs only
    HAS_I2S=no
fi

log_msg "Detected MCU: $MCU_VER (sound chip: $SOUND_CHIP, tuner: $RADIO_CHIP, I2S: $HAS_I2S)"

resetprop persist.qf.arm.default.volume 15

# --- persist.sys.main_volume is NOT ours to touch. Do not add it back. ---
#
# v5.0 wrote `persist.sys.main_volume 15` and `sys.media.vol 15`, on the assumption that they were
# Android's STREAM_MUSIC (0..15, 15 = unity). They are not. That is `persist.qf.arm.default.volume`,
# which this script does set, deliberately, a few lines above - and which is the whole point of the
# module: Android at unity, the DSP doing the work.
#
# `persist.sys.main_volume` is a different property on a different scale (0..32). It is the
# START-UP VOLUME SLIDER in CarSettings - an ordinary, visible user setting. People set it on
# purpose: low so a reboot does not startle the household, high because they like it loud.
#
# v5.1 tried to undo v5.0 by rewriting 15 back to 12. That was worse than the original bug: a
# module cannot tell "our old mistake" from "the owner chose this" by looking at the number, and 15
# is squarely inside the range the slider offers. So the heal quietly overrode a deliberate choice
# on every boot.
#
# It is gone, on purpose. v5.0 was pulled from distribution quickly and reached few units, and
# anyone it did reach can move the slider back in two taps - it is a setting they can see. Silently
# rewriting a user's setting to fix our own old bug is not a trade worth making.

(
    COUNT=0
    while [ "$(getprop sys.boot_completed)" != "1" ] && [ $COUNT -lt 120 ]; do
        sleep 0.5
        COUNT=$((COUNT + 1))
        if [ "$HAS_I2S" = "yes" ]; then
            tinymix "VBC_IIS_MST_WIDTH_SET" WD_24BIT 2>/dev/null
        fi
    done

    log_msg "System boot_completed reached (count=$COUNT)"

    sleep 2
    IS_NEW_POLICY=$(dumpsys media.audio_policy 2>/dev/null | grep -A 10 "Streams: AUDIO_STREAM_SYSTEM(1)" | grep "AUDIO_USAGE_ASSISTANCE_NAVIGATION_GUIDANCE")
    if [ -z "$IS_NEW_POLICY" ]; then
        log_msg "WARNING: audioserver started with old policies! Restarting audioserver now..."
        killall audioserver 2>/dev/null || pkill -9 audioserver
        sleep 2
        log_msg "audioserver restarted. New PID: $(pidof audioserver)"
    else
        log_msg "Policies are loaded."
    fi

    # --- and separately: is the path underneath them actually alive? ---
    #
    # Loaded policies say nothing about whether sound can flow. Measured on a live unit: after a
    # normal boot the players were silent while audioserver was up and the policies were correct.
    # The stream told the truth - state SETUP, trigger_time 0, and an owner PID that no longer
    # existed. A stream opened, configured and abandoned; everything after it lands in a device
    # that will never run.
    #
    # The platform itself causes this: McuManagerService.onVersionInfoChanged restarts audioserver
    # whenever the MCU version string is new or empty, and on a cold boot it is always empty. If
    # the HAL had a stream open at that moment, the stream is stranded.
    #
    # A watchdog that only checks policies cannot see any of it - that is exactly what this script
    # used to do, and it printed SUCCESS over a dead path.
    check_path_alive() {
        for s in /proc/asound/card0/pcm*p/sub0; do
            [ -f "$s/status" ] || continue
            ST=$(cat "$s/status" 2>/dev/null)
            case "$ST" in
                *"state: SETUP"*)
                    OWNER=$(echo "$ST" | grep owner_pid | awk '{print $3}')
                    TRIG=$(echo "$ST" | grep trigger_time | awk '{print $3}')
                    case "$TRIG" in
                        0.000000000)
                            if [ -n "$OWNER" ] && [ ! -d "/proc/$OWNER" ]; then
                                log_msg "STRANDED STREAM at $s: state SETUP, never triggered, owner $OWNER is gone. Restarting audioserver."
                                setprop ctl.restart audioserver
                                return 1
                            fi
                            ;;
                    esac
                    ;;
            esac
        done
        return 0
    }

    sleep 3
    if check_path_alive; then
        log_msg "Audio path is healthy."
    fi

    get_music_vol() {
        dumpsys audio 2>/dev/null | grep -A 5 "STREAM_MUSIC:" | grep "streamVolume:" | head -n 1 | cut -d: -f2
    }

    # Lightweight boot guard: check volume for ~15 seconds using native dumpsys audio (0 JVM starts)
    WATCH_UNTIL=$(($(date +%s) + 15))
    while [ $(date +%s) -lt $WATCH_UNTIL ]; do
        CURR_VOL=$(get_music_vol)
        if [ -n "$CURR_VOL" ] && [ "$CURR_VOL" != "15" ]; then
            NAVI_ACTIVE=$(getprop persist.sys.navi_state)
            if [ "$NAVI_ACTIVE" != "true" ]; then
                log_msg "Detected volume drop to $CURR_VOL! Restoring to 15..."
                cmd media.audio_flinger set-volume 3 1.0 2>/dev/null
                media volume --stream 3 --set 15 2>/dev/null
                resetprop persist.qf.arm.default.volume 15
            fi
        fi
        if [ "$HAS_I2S" = "yes" ]; then
            tinymix "VBC_IIS_MST_WIDTH_SET" WD_24BIT 2>/dev/null
        fi
        sleep 1.5
    done

    log_msg "Early boot watchdog completed. Final verification..."
    cmd media.audio_flinger set-volume 3 1.0 2>/dev/null
    media volume --stream 3 --set 15 2>/dev/null
    resetprop persist.qf.arm.default.volume 15

    # Suspend/Resume detector (wake-up watchdog)
    # Detects wake-up by monotonic time leap during deep sleep without background polling or VM calls
    LAST_TIME=$(date +%s)
    while true; do
        sleep 3
        NOW_TIME=$(date +%s)
        DIFF=$((NOW_TIME - LAST_TIME))
        LAST_TIME=$NOW_TIME

        if [ $DIFF -gt 12 ]; then
            IS_ACC_OFF=$(getprop sys.qf.is.acc.on)
            if [ "$IS_ACC_OFF" != "false" ]; then
                log_msg "Wake-up from sleep detected (time delta: ${DIFF}s). Restoring unity gain and 24-bit I2S..."
                if [ "$HAS_I2S" = "yes" ]; then
                    tinymix "VBC_IIS_MST_WIDTH_SET" WD_24BIT 2>/dev/null
                fi
                resetprop persist.qf.arm.default.volume 15
                cmd media.audio_flinger set-volume 3 1.0 2>/dev/null
                media volume --stream 3 --set 15 2>/dev/null
            fi
        fi
    done
) &
