#!/system/bin/sh
# Sourced by customize.sh and bp_ctl.sh - the one place for the navigator list rule.
#
# /system/config/NaviApp.ini is the platform's list of navigators (QFAudioUtils.audio_init, read once
# per process - a change applies after a reboot). One line per app: "package adjust mix":
#   - listed at all: the app is a navigator - its prompts play as navigation and duck the music;
#   - adjust (true|false): the app's own volume control (setStreamVolume) sets the prompt volume;
#   - mix (appset|0..100): the music level under a prompt; appset = the car settings' mix.
# A line with fewer than three fields makes the parser drop the REST of the file, so every line we
# write is checked. The list differs per firmware, so the module never ships a fixed copy:
#   - base = the unit's own list, the six iGo builds "false" -> "true", missing navigators appended
#     (and Google TTS, prompts spoken through TTS);
#   - live = base + the user's own entries from $BP_NAVI_USER (they replace a base line of the same app).

BP_NAVI_ON="com.navngo.igo.javaclient com.basarsoft.igo.javaclient com.nng.igoprimoisr2013march24.javaclient com.nng.igo.primong.igoworld com.nng.igoprimo.javaclient com.nng.igoprimoisrael.javaclient"
BP_NAVI_ADD="pl.aqurat.automapa com.sygic.aura com.tomtom.gplay.navapp com.tomtom.gplay.navapp.nds com.generalmagic.magicearth net.osmand net.osmand.plus ru.dublgis.dgismobile com.mapfactor.navigator ru.yandex.yandexmaps com.mapswithme.maps.pro app.organicmaps com.google.android.tts"
BP_NAVI_USER=/sdcard/BitPerfectAudio/navigators.conf

# $1 = the unit's list, $2 = where to write the base. Returns 0 written, 1 no source.
bp_naviapp_base() {
    [ -f "$1" ] || return 1
    BPN_T=/data/local/tmp/bp_navi.$$
    tr -d '\r' < "$1" > "$BPN_T" || return 1
    for p in $BP_NAVI_ON; do
        sed -i "s/^\($p[[:space:]][[:space:]]*\)false\([[:space:]]\)/\1true\2/" "$BPN_T"
    done
    for p in $BP_NAVI_ADD; do
        grep -q "^$p[[:space:]]" "$BPN_T" || printf '%-44s true    appset\n' "$p" >> "$BPN_T"
    done
    cat "$BPN_T" > "$2"; rm -f "$BPN_T"
    return 0
}

# 0 when "$1 $2 $3" is a line the platform parses: a package name, true|false, appset|0..100.
bp_navi_valid() {
    echo "$1" | grep -qE '^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$' || return 1
    case "$2" in true|false) ;; *) return 1 ;; esac
    [ "$3" = appset ] && return 0
    echo "$3" | grep -qE '^[0-9]{1,3}$' && [ "$3" -le 100 ]
}

# Create the user's file with its explanation if missing.
bp_navi_user_ensure() {
    [ -f "$BP_NAVI_USER" ] && return 0
    mkdir -p "$(dirname "$BP_NAVI_USER")"
    cat > "$BP_NAVI_USER" <<'EOF'
# BitPerfect - your own navigators (BitPerfect Control edits this file; applies after a reboot)
# package                     adjust (true|false)   mix (appset|0-100)
#   adjust: the app's own volume control sets the prompt volume
#   mix:    the music level under a prompt; appset = the car settings' mix
EOF
}

# $1 = base list, $2 = where to write the live list. Invalid user lines are skipped.
bp_naviapp_live() {
    [ -f "$1" ] || return 1
    BPN_T=/data/local/tmp/bp_navi_live.$$
    tr -d '\r' < "$1" > "$BPN_T" || return 1
    if [ -f "$BP_NAVI_USER" ]; then
        tr -d '\r' < "$BP_NAVI_USER" | while read -r p a m _; do
            case "$p" in ''|'#'*) continue ;; esac
            bp_navi_valid "$p" "$a" "$m" && echo "$p $a $m"
        done > "$BPN_T.u"
        while read -r p a m; do
            awk -v p="$p" '$1 != p' "$BPN_T" > "$BPN_T.n"; cat "$BPN_T.n" > "$BPN_T"
            printf '%-44s %-7s %s\n' "$p" "$a" "$m" >> "$BPN_T"
        done < "$BPN_T.u"
        rm -f "$BPN_T.u" "$BPN_T.n"
    fi
    cat "$BPN_T" > "$2"; rm -f "$BPN_T"
    return 0
}

# Set (or with $2 empty, remove) the user's entry for package $1. Returns 0 saved, 1 bad value.
bp_navi_user_set() {
    [ -n "$2" ] && ! bp_navi_valid "$1" "$2" "$3" && return 1
    bp_navi_user_ensure
    BPN_T=/data/local/tmp/bp_navi_user.$$
    tr -d '\r' < "$BP_NAVI_USER" | awk -v p="$1" '$1 != p' > "$BPN_T"
    [ -n "$2" ] && printf '%-44s %-7s %s\n' "$1" "$2" "$3" >> "$BPN_T"
    cat "$BPN_T" > "$BP_NAVI_USER"; rm -f "$BPN_T"
    return 0
}
