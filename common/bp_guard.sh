#!/system/bin/sh
# BitPerfect guard - installed by customize.sh as /data/adb/post-fs-data.d/bitperfect_guard.sh.
#
# Magisk runs nothing of a module when it is DISABLED, and this module has no uninstall.sh, yet the
# module leaves state outside its own directory that only makes sense while it is active:
#   1. car.config music_volume pinned to 15 (bp_carconfig.sh). On the factory 16-bit path that is
#      full scale and distorts every source (wDSP line, bench 15.10.2026, #1813).
#   2. AGDSP blobs in /data/vendor/local/media/audio_params/, built by the HAL from OUR XMLs; the HAL
#      keeps loading them after our XMLs are gone.
# post-fs-data.d scripts run on every boot whether or not the module is enabled, and before
# system_server (which copies car.config into persist.qf.arm.default.volume) and before the audio
# HAL starts - so the factory state is back on the same boot the module was switched off.
#
# Self-contained on purpose: when the module is removed, its directory is gone.

MOD=/data/adb/modules/BitPerfect.module
CARCONFIG=/great/protect_dir/car.config
BAK=/data/adb/BitPerfect.car.config.bak
DONE=/data/adb/BitPerfect.guard.restored
LOG=/data/adb/BitPerfect.log

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [guard] $1" >> "$LOG"; }

# Active module. Normally nothing to do; but if the guard restored the factory state earlier, the
# module was just switched back on: drop the factory-built blobs so the HAL rebuilds them from our
# XMLs, and pin music_volume again through the module's own rule - both before this boot uses them.
if [ -d "$MOD" ] && [ ! -f "$MOD/disable" ] && [ ! -f "$MOD/remove" ]; then
    if [ -f "$DONE" ]; then
        rm -f /data/vendor/local/media/audio_params/* 2>/dev/null
        . "$MOD/common/bp_carconfig.sh" && bp_pin_music_volume
        rm -f "$DONE"
        log "BitPerfect enabled again: AGDSP blobs removed, music_volume pinned."
    fi
    exit 0
fi

GONE=no
[ -d "$MOD" ] && [ ! -f "$MOD/remove" ] || GONE=yes

# Every boot while inactive: tell the calling line BitPerfect is NOT there (service.sh, which sets 1,
# does not run). Contract: C:\APPS_Contacts\BitPerfect--Calling\MODULE_DETECTION_CONTRACT.md
resetprop sys.bitperfect.enabled 0 2>/dev/null || setprop sys.bitperfect.enabled 0

if [ ! -f "$DONE" ]; then
    # 1. music_volume back to the value it had before BitPerfect first pinned it. Only that one
    #    field is restored: the rest of car.config may have changed since the backup was taken.
    if [ -f "$BAK" ] && [ -f "$CARCONFIG" ]; then
        ORIG=$(grep -a -m1 '^name=music_volume,' "$BAK" | sed -n 's/.*current=\([0-9]*\),.*/\1/p')
        if [ -n "$ORIG" ] && [ "$ORIG" != "15" ]; then
            TMP=/data/local/tmp/bp_guard_car.config.$$
            # In place (cat, not mv): the file is system:system 0600 with an SELinux label.
            sed "/^name=music_volume,/ s/current=[0-9]*,/current=$ORIG,/" "$CARCONFIG" > "$TMP" \
                && cat "$TMP" > "$CARCONFIG" && log "car.config music_volume restored to $ORIG."
            rm -f "$TMP"
        fi
    fi
    # 2. Let the HAL rebuild its blobs from whatever XMLs are live now (factory ones).
    rm -f /data/vendor/local/media/audio_params/* 2>/dev/null
    log "AGDSP blobs in /data removed (module $([ "$GONE" = yes ] && echo removed || echo disabled))."
    touch "$DONE"
fi

# Removed for good: clean up after ourselves, guard included.
if [ "$GONE" = "yes" ]; then
    rm -f "$BAK" "$DONE"
    log "BitPerfect removed - guard deletes itself."
    rm -f "$0"
fi
exit 0
