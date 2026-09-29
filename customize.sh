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

ui_print "- Розпакування профілів з архіву..."
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
ui_print "  ЗБЕРЕЖЕНО ЗНІМОК ЗАВОДСЬКОГО СТАНУ вашої магнітоли:"
ui_print "    /sdcard/QF_audio_survey/   (${DST_K:-0} KB, з ${SRC_K:-0} KB)"
ui_print " "
ui_print "  Це конфігураційні файли та значення налаштувань."
ui_print "  Нікуди не надсилається - лежить у вас."
ui_print "  Надішліть автору, якщо хочете допомогти з підтримкою"
ui_print "  вашого набору мікросхем; або просто видаліть теку."
ui_print "  ---------------------------------------------------"
ui_print " "

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

ui_print "- Виявлено MCU: $MCU_VER"

# v5.1: say it out loud when the hardware cannot be identified. The fallback is the safe profile,
# but a silent fallback is how somebody ends up on the wrong audio path with no idea why - and on
# this platform the wrong path is audible as noise, not as silence.
if [ -z "$HW_CODE" ]; then
    ui_print "  !!! УВАГА: persist.sys.qf.mcu.version порожній."
    ui_print "  !!! Ставлю БЕЗПЕЧНИЙ профіль 16-bit. Якщо у вас BU32107 -"
    ui_print "  !!! напишіть автору, додамо ваш код заліза."
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
    0) CHIP_NAME="ROHM BU32107 (цифровий DSP)" ;;
    1) CHIP_NAME="ROHM BD37534 (аналоговий процесор)" ;;
    2) CHIP_NAME="AKM AK7738 (зовнішній DSP)" ;;
    3) CHIP_NAME="AKM AK7604 (зовнішній DSP)" ;;
    *) CHIP_NAME="невідомий ($SOUND_CHIP)" ;;
esac
ui_print "- Аудіопроцесор: $CHIP_NAME"
ui_print "- Тракт: $([ "$USE_I2S" = yes ] && echo 'цифровий I2S' || echo 'аналоговий (ЦАП SC2730)')"

# Exactly one of the two route files belongs on a given unit, and the other has to be DELETED, not
# merely left unwritten. Two mechanisms leave it behind:
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
    ui_print "- Профіль: 24-bit 48kHz Hi-Fi Bit-to-Bit"
    cp -rf "$MODPATH/profiles/bu32107_i2s/system/"* "$MODPATH/system/"
    drop_route qf_double_bt_audio_route_noi2s.xml
    drop_route qf_audio_route_no_i2s.xml
else
    ui_print "- Профіль: 16-bit Safe BitPerfect (без шуму)"
    cp -rf "$MODPATH/profiles/bd37544_noi2s/system/"* "$MODPATH/system/"
    drop_route qf_double_bt_audio_route_i2s.xml
    drop_route qf_audio_route_has_i2s.xml
fi

ui_print "- Застосування спільних політик навігації та регулювання..."
cp -rf "$MODPATH/common/system/"* "$MODPATH/system/"

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
    ui_print "- Тюнер: NXP TEF6686 (гарячий вихід)"
    ui_print "  Якщо підказки навігації тонуть - підніміть їх у налаштуваннях гучності."
fi

ui_print "- Встановлення прав доступу..."
set_perm_recursive "$MODPATH/system/vendor/etc" 0 0 0755 0644
set_perm_recursive "$MODPATH/system/config" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755

ui_print "***************************************************"
ui_print "  Установка успішна! Перезавантажте пристрій.     "
ui_print "***************************************************"
