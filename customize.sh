##########################################################################################
# BitPerfect Universal Installer
#
# 🔴 The version is READ from module.prop, never written here. A hardcoded string in this
# banner said "v5.3" while module.prop said v5.4 and the zip in the release folder was named
# "v5.4.1" - three labels, three different answers, and the unit could confirm none of them.
# Whatever prints the version must derive it from the one place that ships with the module.
##########################################################################################
: "${MODPATH:=${0%/*}}"

MODVER=$(grep -m1 '^version=' "$MODPATH/module.prop" 2>/dev/null | cut -d= -f2)
MODCODE=$(grep -m1 '^versionCode=' "$MODPATH/module.prop" 2>/dev/null | cut -d= -f2)
[ -z "$MODVER" ] && MODVER="UNKNOWN"
[ -z "$MODCODE" ] && MODCODE="?"

ui_print "***************************************************"
ui_print "       BitPerfect Universal Audio Engine           "
ui_print "       $MODVER (versionCode $MODCODE)"
ui_print "          for QF001 / K706 Platform                "
ui_print "***************************************************"

ui_print "- Unpacking profiles..."
unzip -o "$ZIPFILE" 'profiles/*' 'common/*' -d "$MODPATH" >&2

# ---------------------------------------------------------------------------
# A snapshot of the FACTORY state, taken before anything is replaced.
#
# This is the only moment it can be taken: once the module is active the
# original files are hidden behind the overlay, and a unit that has had the
# module for a while can no longer tell us what it looked like before. Two
# apparently identical head units behave differently here, and without a
# "before" picture from real hardware every explanation stays a guess.
#
# Read-only. Nothing is transmitted; the folder stays on the owner's storage
# and they decide whether to send it.
# ---------------------------------------------------------------------------
# 🔴 Written to /data/local/tmp first, copied to /sdcard as a finished directory.
# A root script writing straight to /sdcard produces FILES OF ZERO LENGTH on some
# builds - the data lands in the lower filesystem while the FUSE layer the user
# sees keeps an empty inode. The first survey ever returned came back that way:
# every file 0 bytes, on the very hardware we needed.
STAMP=$(date '+%Y%m%d_%H%M%S')
SNAP="/data/local/tmp/qf_snap_$STAMP/before_install_$STAMP"
SNAP_DEST="/sdcard/QF_audio_survey"
mkdir -p "$SNAP/vendor_etc" 2>/dev/null

getprop > "$SNAP/getprop.txt" 2>/dev/null

# /vendor/etc is not the factory once any module is active - Magisk's overlay
# hides the original, so on a re-install we would archive our own files and call
# them "factory". The vendor partition can be mounted a second time, read-only,
# to read what is really underneath.
SRC=/vendor/etc
ORIGIN="live /vendor/etc (may already be overlaid by a module)"
mkdir -p /data/local/tmp/vraw_snap 2>/dev/null
for dev in /dev/block/dm-1 /dev/block/mapper/vendor /dev/block/by-name/vendor; do
    [ -e "$dev" ] || continue
    if mount -o ro "$dev" /data/local/tmp/vraw_snap 2>/dev/null; then
        if [ -f /data/local/tmp/vraw_snap/etc/audio_pcm.xml ]; then
            SRC=/data/local/tmp/vraw_snap/etc
            ORIGIN="factory vendor partition, mounted read-only from $dev"
            break
        fi
        umount /data/local/tmp/vraw_snap 2>/dev/null
    fi
done

for f in audio_pcm.xml audio_route.xml audio_config.xml audio_effects.xml \
         qf_audio_route_has_i2s.xml qf_audio_route_no_i2s.xml \
         qf_double_bt_audio_route_i2s.xml qf_double_bt_audio_route_noi2s.xml \
         audio_policy_engine_product_strategies.xml \
         audio_policy_engine_stream_volumes.xml audio_policy_volumes.xml \
         primary_audio_policy_configuration.xml
do
    [ -f "$SRC/$f" ] && cp "$SRC/$f" "$SNAP/vendor_etc/" 2>/dev/null
done
cp /system/config/NaviApp.ini "$SNAP/vendor_etc/" 2>/dev/null

# The AGDSP parameter files are several megabytes each and identical across the
# fleet, so checksums answer "is this one standard?" without making the archive
# too big to send over a messenger.
{
    echo "# md5 of the AGDSP parameter files, from: $ORIGIN"
    md5sum "$SRC"/audio_params/sprd/*.xml 2>/dev/null
    echo
    echo "# and of what is live right now"
    md5sum /vendor/etc/audio_params/sprd/*.xml 2>/dev/null
} > "$SNAP/audio_params_md5.txt" 2>/dev/null

umount /data/local/tmp/vraw_snap 2>/dev/null
rmdir /data/local/tmp/vraw_snap 2>/dev/null

{
    echo "# taken before BitPerfect $MODVER (versionCode $MODCODE) was applied, $(date)"
    echo "# mcu: $(getprop persist.sys.qf.mcu.version)"
    echo "# configuration files came from: $ORIGIN"
    echo
    echo "## modules already installed BEFORE this one"
    echo "## (if BitPerfect is listed, this unit was not factory-clean)"
    ls /data/adb/modules/ 2>/dev/null
    for m in /data/adb/modules/*/module.prop; do
        [ -f "$m" ] && grep -H -E "^(id|version)=" "$m" 2>/dev/null
    done
    echo
    echo "## mixer"
    tinymix 2>/dev/null
    echo
    echo "## pcm streams"
    for s in /proc/asound/card0/pcm*p/sub0 /proc/asound/card0/pcm*c/sub0; do
        echo "=== $s ==="; cat "$s/status" 2>/dev/null; cat "$s/hw_params" 2>/dev/null
    done
    echo
    echo "## sound cards / codecs"
    cat /proc/asound/cards 2>/dev/null
    cat /sys/kernel/debug/asoc/codecs 2>/dev/null
    echo
    echo "## AK hub on the bus (XX = no chip answered)"
    for d in /sys/kernel/debug/regmap/*-001c; do
        [ -d "$d" ] && head -6 "$d/registers" 2>/dev/null
    done
} > "$SNAP/state.txt" 2>/dev/null

dumpsys media.audio_policy > "$SNAP/audio_policy.txt" 2>/dev/null

# Now hand it over as a whole, and check the copy actually carried bytes rather
# than trusting that it did.
mkdir -p "$SNAP_DEST" 2>/dev/null
cp -r "$SNAP" "$SNAP_DEST/" 2>/dev/null
chmod -R 0777 "$SNAP_DEST" 2>/dev/null
SRC_K=$(du -s "$SNAP" 2>/dev/null | awk '{print $1}')
DST_K=$(du -s "$SNAP_DEST/before_install_$STAMP" 2>/dev/null | awk '{print $1}')
rm -rf "/data/local/tmp/qf_snap_$STAMP" 2>/dev/null

ui_print " "
ui_print "  ---------------------------------------------------"
ui_print "  SAVED A SNAPSHOT OF YOUR UNIT'S FACTORY STATE:"
ui_print "    /sdcard/QF_audio_survey/   (${DST_K:-0} KB of ${SRC_K:-0} KB)"
ui_print " "
ui_print "  Configuration files and setting values only."
ui_print "  Nothing is sent anywhere - it stays on your unit."
ui_print "  Send it to the author to help support your chip set,"
ui_print "  or simply delete the folder."
ui_print "  ---------------------------------------------------"
ui_print " "

# UIS7862 (ums512): the full module. UIS8581 (sp9863a): a reduced profile (profiles/sp9863a/) - its HAL,
# libraries and vendor files are different, no 8581 bench exists, so only edits whose factory base was
# seen are applied. Anything else: refused, after the factory snapshot above is saved.
PLATFORM=$(getprop ro.board.platform)
case "$PLATFORM" in
    ums512)  BP_SOC=7862 ;;
    sp9863a) BP_SOC=8581 ;;
    *)
        ui_print " "
        ui_print "  !!! Platform $PLATFORM is neither UIS7862 (ums512) nor UIS8581 (sp9863a)."
        ui_print "  !!! Nothing was changed. State snapshot in /sdcard/QF_audio_survey/ -"
        ui_print "  !!! send it to the author if you want to help with support."
        abort "  BitPerfect: unsupported platform $PLATFORM"
        ;;
esac

# ums512 alone is not enough: Topway and other vendors ship UIS7862 too, with their own HAL, policy
# and libraries. Our patched libaudiopolicymanager.so and the vendor overlay are QF's; on a Topway
# they left the unit in a boot loop that only a reflash cured (owner, 23.10.2026). Accept QF
# firmware and its MG clone only: the MCU string's first field (QF05..., MG18/19/20 on the
# shengpai client build) or the hardware revision (QF001 on the bench; MG19 on shengpai).
QF_MCU=$(getprop persist.sys.qf.mcu.version)
QF_REV=$(getprop ro.boot.hardware.revision)
case "$QF_MCU" in QF*|MG*) QF_OK=yes ;; *) QF_OK=no ;; esac
case "$QF_REV" in QF*|MG*) QF_OK=yes ;; esac
if [ "$QF_OK" != "yes" ]; then
    ui_print " "
    ui_print "  !!! Not a QF unit (or its MG clone): MCU '$QF_MCU', revision '$QF_REV'."
    ui_print "  !!! BitPerfect is for QF / K706 firmware (or its MG clone) only."
    ui_print "  !!! Any other firmware is refused, no exceptions."
    ui_print "  !!! Nothing was changed. On other firmware this module bricks the unit."
    abort "  BitPerfect: not a QF/MG unit (MCU '$QF_MCU', revision '$QF_REV')"
fi

MCU_VER=$(getprop persist.sys.qf.mcu.version)
HW_CODE=$(echo "$MCU_VER" | awk -F'.' '{print $NF}')

# The six characters of the suffix, decoded from factory code - McuVersionUtils.parseMcuVersion
# together with the name arrays in ProductInfoConstants (both in QF_CarSettings):
#
#   [0] MCU family     [1] SOUND PROCESSOR  0=BU32107 1=BD37534 2=AK7738 3=AK7604
#   [2] tuner          [3] OUTPUT PATH      0=analogue  1=IIS
#   [4] control panel  [5] power bitmask
#
# v5.2 and earlier tested ${HW_CODE:4:2} == "21", i.e. characters 4 and 5 - the CONTROL PANEL and
# the POWER BITMASK. Neither concerns audio, and both read "21" on every firmware we have:
# 002121, 004121, 001121 and 011021 alike. So the test was ALWAYS TRUE, the BD branch was dead
# code, and every BD37534 unit - an analogue processor with no I2S at all - was handed the 24-bit
# I2S profile. That is the digital rasp BD owners keep reporting.
SOUND_CHIP=${HW_CODE:1:1}
MPU_MODE=${HW_CODE:3:1}
RADIO_CHIP=${HW_CODE:2:1}

# The platform computes the same answer itself: the audio HAL parses the MCU string in
# set_mpu_i2s_property and publishes the result. Prefer its answer, fall back to the suffix.
I2S_PROP=$(getprop persist.sys.qf.arm.use.i2s)

ui_print "- MCU detected: $MCU_VER"

# v5.1: say it out loud when the hardware cannot be identified. The fallback is the safe profile,
# but a silent fallback is how somebody ends up on the wrong audio path with no idea why - and on
# this platform the wrong path is audible as noise, not as silence.
if [ -z "$HW_CODE" ]; then
    ui_print "  !!! WARNING: persist.sys.qf.mcu.version is empty."
    ui_print "  !!! Installing the SAFE 16-bit profile. If you have a BU32107,"
    ui_print "  !!! tell the author and your hardware code will be added."
fi

mkdir -p "$MODPATH/system/vendor/etc"
mkdir -p "$MODPATH/system/config"

# Anything that is not a confirmed digital I2S path gets the safe analogue profile. Three
# independent signals have to agree before the 24-bit profile is applied, because being wrong in
# that direction is audible as noise, while being wrong the other way is merely not an improvement.
USE_I2S=no
if [ "$I2S_PROP" = "true" ] || [ "$MPU_MODE" = "1" ]; then
    USE_I2S=yes
fi
# BD37534 is analogue-in only: never give it the I2S profile, whatever the other flags say.
if [ "$SOUND_CHIP" = "1" ]; then
    USE_I2S=no
fi

case "$SOUND_CHIP" in
    0) CHIP_NAME="ROHM BU32107 (digital DSP)" ;;
    1) CHIP_NAME="ROHM BD37534 (analogue processor)" ;;
    2) CHIP_NAME="AKM AK7738 (external DSP)" ;;
    3) CHIP_NAME="AKM AK7604 (external DSP)" ;;
    *) CHIP_NAME="unknown ($SOUND_CHIP)" ;;
esac
ui_print "- Sound processor: $CHIP_NAME"

if [ "$BP_SOC" = "7862" ]; then
ui_print "- Path: $([ "$USE_I2S" = yes ] && echo 'digital I2S' || echo 'analogue (SC2730 DAC)')"

# system/vendor/etc is built from EMPTY here (owner, 30.09.2026): the zip ships no pre-seeded variant.
# profiles/<chip>/ carries only what depends on the hardware (audio_pcm.xml and the routes), common/
# carries everything shared (policy, effects, AGDSP parameters, volume curves) in one copy.
#
# Exactly one of the two route files belongs on a given unit, and the other has to be DELETED, not
# merely left unwritten. Two mechanisms used to leave it behind (the first is gone with the
# pre-seeded variant, the second still applies to units upgrading from an older version):
#
#   * `cp -rf` copies the chosen profile over the pre-seeded system/, but never removes a file the
#     profile has no counterpart for;
#   * Magisk installs an update INTO the existing module directory without clearing it, so a file
#     placed by an earlier version simply survives. 📻 Observed upgrading v5.2 -> v5.3 on a BU
#     unit: the module ended up carrying both routes.
#
# A leftover is not inert: the HAL chooses its route from
# persist.sys.qf.arm.use.i2s x persist.sys.qf.use.a2dp_route, so whatever sits there is a file it
# is entitled to load.
#
# 🔴 And deleting it from $MODPATH alone is NOT enough. On an upgrade Magisk unpacks into
# /data/adb/modules_update/<id> - which is what $MODPATH points at here - while the previously
# installed /data/adb/modules/<id> keeps whatever an older version put there. 📻 Verified twice on
# a BU unit upgrading v5.2 -> v5.3: the noi2s route deleted from $MODPATH was still present in the
# live module directory afterwards. Both paths have to be cleaned.
LIVE=/data/adb/modules/BitPerfect.module/system/vendor/etc

drop_route() {
    rm -f "$MODPATH/system/vendor/etc/$1"
    rm -f "$LIVE/$1"
}

if [ "$USE_I2S" = "yes" ]; then
    ui_print "- Profile: 24-bit 48kHz Hi-Fi Bit-to-Bit"
    cp -rf "$MODPATH/profiles/bu32107_i2s/system/"* "$MODPATH/system/"
    drop_route qf_double_bt_audio_route_noi2s.xml
    drop_route qf_audio_route_no_i2s.xml
else
    ui_print "- Profile: 16-bit Safe BitPerfect (no noise)"
    cp -rf "$MODPATH/profiles/bd37544_noi2s/system/"* "$MODPATH/system/"
    drop_route qf_double_bt_audio_route_i2s.xml
    drop_route qf_audio_route_has_i2s.xml
fi

ui_print "- Applying shared navigation and volume policies..."
cp -rf "$MODPATH/common/system/"* "$MODPATH/system/"
touch "$MODPATH/bp_nav_policy"

else
# ---------------------------------------------------------------------------
# UIS8581. Kept factory: the 16-bit / 44.1 kHz output (owner 04.10: profile 44.1/16, no HAL patch -
# 44.1 music plays without resampling), the HAL's own audio_hw.xml / audio_para / codec_pga.xml,
# audio_effects, calls. The 7862 libraries and vendor set (audio_pcm, audio_route, audio_config,
# audio_params/sprd, primary policy) are NOT for this SoC - v5.3 put them here and the unit hung on
# the logo. Applied: the navigation policy and the music curve, built from the 8581 factory files
# (tools/build_8581_profile.py), each only over a factory file with the md5 they were built from.
# ---------------------------------------------------------------------------
ui_print "- UIS8581: factory 16-bit / 44.1 kHz output kept (44.1 music is not resampled)"
rm -f "$MODPATH/system/lib/libaudioclient.so" "$MODPATH/system/lib64/libaudioclient.so"       "$MODPATH/system/lib64/libaudiopolicymanager.so"
rmdir "$MODPATH/system/lib" "$MODPATH/system/lib64" 2>/dev/null
NAV_FILES=0
while read -r SUM NAME; do
    [ -n "$NAME" ] || continue
    if [ "$(md5sum "/vendor/etc/$NAME" 2>/dev/null | cut -d' ' -f1)" = "$SUM" ]; then
        cp -f "$MODPATH/profiles/sp9863a/system/vendor/etc/$NAME" "$MODPATH/system/vendor/etc/$NAME"
        ui_print "- $NAME: navigation / music policy applied"
        [ "$NAME" = "audio_policy_engine_product_strategies.xml" ] && NAV_FILES=1
    else
        ui_print "- $NAME: this firmware's file is not the one we know - kept factory"
    fi
done < "$MODPATH/profiles/sp9863a/factory.md5"
[ "$NAV_FILES" = "1" ] && touch "$MODPATH/bp_nav_policy"
cp -f "$MODPATH/common/system/vendor/etc/usb_audio_policy_configuration.xml" "$MODPATH/system/vendor/etc/"
fi

# The navigator list (/system/config/NaviApp.ini) is edited from the unit's own copy (bp_naviapp.sh).
. "$MODPATH/common/bp_naviapp.sh"
if bp_naviapp_build /system/config/NaviApp.ini "$MODPATH/system/config/NaviApp.ini"; then
    ui_print "- Navigator list: iGo and missing navigators added to music ducking"
fi

# USB DAC: the unit's own top-level policy with QF's USB include switched by the user's setting
# (/sdcard/BitPerfectAudio/bitperfect.conf, usb_dac=0/1). service.sh re-applies it at every boot.
. "$MODPATH/common/bp_usb.sh"
bp_conf_ensure
cp -f /vendor/etc/audio_policy_configuration.xml "$MODPATH/system/vendor/etc/audio_policy_configuration.xml" 2>/dev/null
bp_usb_set "$MODPATH/system/vendor/etc/audio_policy_configuration.xml" "$(bp_usb_wanted)"
case $? in
    0|2) ui_print "- USB DAC output: usb_dac=$(bp_usb_wanted) (settings: $BP_CONF)" ;;
    *)   ui_print "- USB DAC: this unit's policy has no USB include we know - left factory"
         rm -f "$MODPATH/system/vendor/etc/audio_policy_configuration.xml"                "$MODPATH/system/vendor/etc/usb_audio_policy_configuration.xml" ;;
esac

# Calls run only on top of BitPerfect: every audio policy and route for calls lives here, the calling
# module ships none and refuses to work without sys.bitperfect.enabled=1 (set by service.sh).
# Contract: C:\APPS_Contacts\BitPerfect--Calling\MODULE_DETECTION_CONTRACT.md
rm -f "$MODPATH/capabilities" /data/adb/modules/BitPerfect.module/capabilities
if [ -d /data/adb/modules/qf_cellular_calling_master ] || [ -d /data/adb/modules_update/qf_cellular_calling_master ]; then
    if [ "$BP_SOC" = "7862" ]; then
        ui_print "- Calling module found: BitPerfect provides the call audio policy and routes"
    else
        ui_print "- Calling module found: on UIS8581 calls use the factory audio path"
    fi
fi

# Platform default volume -> unity, so the first boot after install already comes up at 0 dB.
. "$MODPATH/common/bp_carconfig.sh"
bp_pin_music_volume
case $? in
    0) ui_print "- car.config: music_volume already 15" ;;
    2) ui_print "- car.config: music_volume -> 15 (backup: $BP_CARCONFIG_BAK)" ;;
    3) ui_print "- car.config: music_volume is your 'default volume' slider - left alone (15 = 0 dB)" ;;
    *) ui_print "- car.config: music_volume not found, left alone" ;;
esac

# Guard against our own leftovers: Magisk runs nothing of a disabled module and there is no
# uninstall.sh, so a script outside the module puts car.config and the AGDSP blobs back to factory
# when BitPerfect is disabled or removed (and redoes ours when it is enabled again). See bp_guard.sh.
mkdir -p /data/adb/post-fs-data.d
cp -f "$MODPATH/common/bp_guard.sh" /data/adb/post-fs-data.d/bitperfect_guard.sh
chmod 0755 /data/adb/post-fs-data.d/bitperfect_guard.sh
rm -f /data/adb/BitPerfect.guard.restored
ui_print "- Disable/remove guard: /data/adb/post-fs-data.d/bitperfect_guard.sh"

# v5.1: the NXP branch used to do `setprop persist.sys.navi_volume 15` here. Removed.
#
# That property is the STREAM_SYSTEM index - it IS the navigation prompt's whole loudness. Writing
# 15 pins it to maximum, permanently and silently, over whatever the owner had chosen, and does it
# on the strength of a guess about the tuner chip. Loudness of prompts is a person's preference,
# not a property of the radio they happen to have.
#
# It also never actually ran: the RADIO_CHIP slice above was off by one until this version, so the
# branch was dead on every unit. Nobody was relying on it, and nothing regresses by dropping it.
#
# If NXP units genuinely need louder prompts - the tuner does run hot - that belongs where the
# owner can see and change it, not in an installer.
if [ "$RADIO_CHIP" = "4" ]; then
    ui_print "- Tuner: NXP TEF6686 (hot output)"
    ui_print "  If navigation prompts get lost, raise them in the volume settings."
fi

ui_print "- Clearing the stale AGDSP blob cache in /data..."
rm -f /data/vendor/local/media/audio_params/* 2>/dev/null

# ---------------------------------------------------------------------------
# UIS7862 library patches: libaudioclient.so (lets VOICE_RECOGNITION=6 and UNPROCESSED=9 through the
# vendor source=MIC override) and libaudiopolicymanager.so (never sends sprd_voip_start: the HAL's
# VoIP record mode is broken, it loops the input - Telegram calls).
#
# These binaries are UIS7862 builds; the platform gate at the top of this script stops any other SoC.
# ---------------------------------------------------------------------------
if [ "$BP_SOC" = "7862" ]; then
ui_print "- UIS7862: patched libaudioclient (sources 6 and 9) and libaudiopolicymanager (no HAL VoIP mode)"
set_perm_recursive "$MODPATH/system/lib" 0 0 0755 0644 u:object_r:system_lib_file:s0
set_perm_recursive "$MODPATH/system/lib64" 0 0 0755 0644 u:object_r:system_lib_file:s0
chcon u:object_r:system_file:s0 "$MODPATH/system/lib" "$MODPATH/system/lib64" 2>/dev/null
fi

ui_print "- Setting permissions..."
set_perm_recursive "$MODPATH/system/vendor/etc" 0 0 0755 0644
set_perm_recursive "$MODPATH/system/config" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755

ui_print "***************************************************"
ui_print "  Installation successful! Reboot the device.     "
ui_print "***************************************************"
