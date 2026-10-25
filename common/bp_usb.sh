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
