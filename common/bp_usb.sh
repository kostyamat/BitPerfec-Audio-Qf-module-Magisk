#!/system/bin/sh
# Sourced by customize.sh (install) and service.sh (every boot) - the one place for the USB DAC rule.
#
# QF switched USB audio output off in the policy only: vendor/etc/audio_policy_configuration.xml has
#   <!-- qf patch, remove usb audio output, by liuhl -->
#   <!-- xi:include href="usb_audio_policy_configuration.xml"/ -->
# while the USB HAL (audio.usb.default.so), USB host and the kernel driver (CONFIG_SND_USB_AUDIO=y)
# are all there. The module carries a copy of that file and turns the include on or off from the
# user's setting; everything else in it stays the unit's own.
#
# usb_dac=0  Android does not use the DAC. Players with their own USB driver (USB Audio Player PRO,
#            Neutron, HiBy "USB exclusive") still play to it bit-perfect; everything else stays on the
#            sound processor. Factory behaviour, the default.
# usb_dac=1  While a DAC is plugged in, Android sends its sound there: one mixed output at the
#            DAC's best rate (resampled, not bit-perfect per source), stream volume at full scale -
#            the level is set on the DAC / amplifier. SIM calls stay on the head unit: in
#            AUDIO_MODE_IN_CALL the AOSP 10 engine allows only primary-module devices when the HAL
#            is < 3.0 and the call mic is on primary (Engine.cpp, STRATEGY_PHONE) - ours is 2.0.
#
# Our usb_audio_policy_configuration.xml (common/) is output-only on purpose: with a USB input
# declared, the engine would prefer a DAC's microphone over the cabin mic for calls and wDSP.

BP_CONF_DIR=/sdcard/BitPerfectAudio
BP_CONF=$BP_CONF_DIR/bitperfect.conf
BP_USB_ON='<xi:include href="usb_audio_policy_configuration.xml"/>'
BP_USB_OFF='<!-- xi:include href="usb_audio_policy_configuration.xml"/ -->'

# Create the settings file with its explanation if the user has none. Never overwrite one.
bp_conf_ensure() {
    [ -f "$BP_CONF" ] && return 0
    mkdir -p "$BP_CONF_DIR" 2>/dev/null || return 1
    cat > "$BP_CONF" <<'EOF'
# BitPerfect settings. Edit a value, save, reboot the unit.
# (Until the BitPerfect Control app exists, this file is the settings screen.)

# usb_dac - what an external USB DAC plays
#   0 = only players with their own USB driver (USB Audio Player PRO, Neutron, HiBy "USB exclusive"),
#       bit-perfect at any rate; all other sound stays on the head unit's sound processor. Default.
#   1 = all Android sound goes to the USB DAC while it is plugged in: resampled to the DAC's best
#       rate, Android volume at full scale - set the level on the DAC or the amplifier.
#       SIM calls stay on the head unit.
usb_dac=0

# usb_dac_mode - the format and rate Android plays to the DAC (with usb_dac=1)
#   auto = the DAC's best. Or FORMAT/RATE exactly as the DAC declares it, e.g. S16_LE/44100 (44.1 kHz
#   music without resampling). A DAC that cannot do it plays nothing from Android - use auto then.
usb_dac_mode=auto
EOF
    chmod 0666 "$BP_CONF" 2>/dev/null
    return 0
}

# Wanted state from the settings file: 1 or 0 (anything unreadable = 0).
bp_usb_wanted() {
    BPU_V=$(grep -m1 '^[[:space:]]*usb_dac[[:space:]]*=' "$BP_CONF" 2>/dev/null | cut -d= -f2 | tr -d ' \r\t')
    [ "$BPU_V" = "1" ] && echo 1 || echo 0
}

# Current state of a policy file: 1 = include on, 0 = off, x = neither form found.
bp_usb_state() {
    if grep -qF "$BP_USB_ON" "$1" 2>/dev/null && ! grep -qF "$BP_USB_OFF" "$1" 2>/dev/null; then
        echo 1
    elif grep -qF "$BP_USB_OFF" "$1" 2>/dev/null; then
        echo 0
    else
        echo x
    fi
}

# Set the include in $1 to $2 (0/1). Rewrites in place (cat >, same inode): on a live unit the file
# is bind-mounted over /vendor/etc, and a new inode would leave the mount on the old content.
# Returns 0 = changed, 2 = already so, 1 = file or include form not found.
bp_usb_set() {
    BPU_F=$1; BPU_W=$2
    [ -f "$BPU_F" ] || return 1
    BPU_S=$(bp_usb_state "$BPU_F")
    [ "$BPU_S" = "x" ] && return 1
    [ "$BPU_S" = "$BPU_W" ] && return 2
    BPU_T=/data/local/tmp/bp_apc.$$
    if [ "$BPU_W" = "1" ]; then
        sed "s#<!-- xi:include href=\"usb_audio_policy_configuration.xml\"/ -->#$BP_USB_ON#" "$BPU_F" > "$BPU_T" || return 1
    else
        sed "s#$BP_USB_ON#$BP_USB_OFF#" "$BPU_F" > "$BPU_T" || return 1
    fi
    cat "$BPU_T" > "$BPU_F"; rm -f "$BPU_T"
    return 0
}

# ---- DAC mode: usb_dac_mode=auto | <ALSA format>/<rate>, e.g. S16_LE/44100 -------------------------
# auto: the "usb_device output" mixPort has no profile - the USB HAL takes the DAC's best rate.
# Fixed: one stereo profile, exactly what the DAC itself declares in /proc/asound/cardN/stream0 (the
# app offers only those). A DAC that cannot do the fixed mode gets no Android sound - status says so.

# ALSA format -> policy format (the USB HAL maps them back one to one).
bp_usb_fmt() {
    case "$1" in
        S16_LE) echo AUDIO_FORMAT_PCM_16_BIT ;;
        S24_3LE) echo AUDIO_FORMAT_PCM_24_BIT_PACKED ;;
        S24_LE) echo AUDIO_FORMAT_PCM_8_24_BIT ;;
        S32_LE) echo AUDIO_FORMAT_PCM_32_BIT ;;
        *) return 1 ;;
    esac
}

# 0 when $1 is "auto" or FORMAT/RATE we can write.
bp_usb_mode_valid() {
    [ "$1" = auto ] && return 0
    bp_usb_fmt "${1%/*}" >/dev/null || return 1
    echo "${1#*/}" | grep -qE '^[0-9]{4,6}$'
}

# Wanted mode from the settings file (anything unreadable = auto).
bp_usb_mode_wanted() {
    BPU_M=$(grep -m1 '^[[:space:]]*usb_dac_mode[[:space:]]*=' "$BP_CONF" 2>/dev/null | cut -d= -f2 | tr -d ' \r\t')
    bp_usb_mode_valid "$BPU_M" && [ -n "$BPU_M" ] && echo "$BPU_M" || echo auto
}

# Mode written in the USB policy file $1: auto or FORMAT/RATE.
bp_usb_mode_state() {
    BPU_L=$(grep -A1 'mixPort name="usb_device output"' "$1" 2>/dev/null | tr -d '\n')
    case "$BPU_L" in *'role="source"/>'*|'') echo auto; return ;; esac
    BPU_PF=$(echo "$BPU_L" | sed -n 's/.*format="\([A-Z0-9_]*\)".*/\1/p')
    BPU_PR=$(echo "$BPU_L" | sed -n 's/.*samplingRates="\([0-9]*\)".*/\1/p')
    for f in S16_LE S24_3LE S24_LE S32_LE; do
        [ "$(bp_usb_fmt $f)" = "$BPU_PF" ] && { echo "$f/$BPU_PR"; return; }
    done
    echo auto
}

# Write mode $2 into the USB policy file $1, in place. Returns 0 changed, 2 already so, 1 bad.
bp_usb_mode_set() {
    [ -f "$1" ] && bp_usb_mode_valid "$2" || return 1
    [ "$(bp_usb_mode_state "$1")" = "$2" ] && return 2
    BPU_T=/data/local/tmp/bp_usbpol.$$
    if [ "$2" = auto ]; then
        BPU_P=""
    else
        BPU_P="$(bp_usb_fmt "${2%/*}") ${2#*/}"
    fi
    awk -v p="$BPU_P" '
        /mixPort name="usb_device output"/ {
            skip = ($0 !~ /\/>/)
            if (p == "") print "        <mixPort name=\"usb_device output\" role=\"source\"/>"
            else {
                split(p, a, " ")
                print "        <mixPort name=\"usb_device output\" role=\"source\">"
                print "            <profile name=\"\" format=\"" a[1] "\" samplingRates=\"" a[2] "\" channelMasks=\"AUDIO_CHANNEL_OUT_STEREO\"/>"
                print "        </mixPort>"
            }
            next
        }
        skip { if ($0 ~ /<\/mixPort>/) skip = 0; next }
        { print }' "$1" > "$BPU_T" || return 1
    cat "$BPU_T" > "$1"; rm -f "$BPU_T"
    return 0
}

# What the plugged USB DACs declare: one "cardN FORMAT CHANNELS RATE,RATE" line per playback altset.
bp_usb_caps() {
    for s in /proc/asound/card*/stream0; do
        BPU_C=${s#/proc/asound/}; BPU_C=${BPU_C%%/*}
        tr -d '\r' < "$s" | awk -v c="$BPU_C" '
            /^Playback:/ { on = 1 } /^Capture:/ { on = 0 }
            on && /Format:/ { f = $2 } on && /Channels:/ { ch = $2 }
            on && /Rates:/ { sub(/.*Rates: */, ""); gsub(/ /, ""); print c, f, ch, $0 }'
    done
}
