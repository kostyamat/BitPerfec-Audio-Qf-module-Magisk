#!/system/bin/sh
# Sourced by service.sh. Contract: C:\APPS_Contacts\wDSP--BitPerfect\BOOT_AUDIO_STATE_CONTRACT.md, B / B-bis.
#
# After boot and after wake the MCU plays at whatever gain it woke with, while the level of the
# live source already sits in its property (sys.media.vol etc.). The framework only pushes that
# level when the volume type matches, and after boot the type is empty - so nothing is pushed
# until someone touches the encoder or a player starts (measured 01.10: type empty, media 10,
# MCU still at the start-up gain).
#
# Re-selecting the CURRENT channel makes the MCU service push the level that is already in the
# property. It invents no number and switches no source, so a repeat is inaudible and wDSP or
# RokoAi doing the same thing at the same moment converge on one result. There is no readable
# "done" state for MCU gain, so the rule is: once per event, under three conditions.

# $1 = event name for the log. Returns 0 acted, 1 skipped (reason in BP_MCU_WHY).
bp_repush_mcu_level() {
    BP_MCU_WHY=""
    [ "$(getprop sys.mute.state)" = "true" ] && { BP_MCU_WHY="global mute on"; return 1; }
    [ "$(getprop sys.qf.call_state)" = "true" ] && { BP_MCU_WHY="call in progress"; return 1; }
    # The MCU's own answer, cross-checked with the platform's mirror; disagreement = do nothing.
    BP_MCU_CH=$(service call mcu_service 14 2>/dev/null | sed -n 's/.*Parcel(00000000 \([0-9a-f]*\).*/\1/p')
    [ -n "$BP_MCU_CH" ] || { BP_MCU_WHY="mcu_service did not answer"; return 1; }
    BP_MCU_CH=$((0x$BP_MCU_CH))
    BP_PROP_CH=$(getprop sys.qf.sound.channel)
    [ "$BP_MCU_CH" = "$BP_PROP_CH" ] || { BP_MCU_WHY="channel mismatch: mcu $BP_MCU_CH, prop $BP_PROP_CH"; return 1; }
    service call mcu_service 15 i32 "$BP_MCU_CH" >/dev/null 2>&1 || { BP_MCU_WHY="RPC_SetChannel failed"; return 1; }
    log -t BitPerfect "MCU level re-pushed on channel $BP_MCU_CH ($1)"
    return 0
}
