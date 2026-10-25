#!/system/bin/sh
# Sourced by customize.sh - the one place for the navigator list rule.
#
# /system/config/NaviApp.ini is the platform's list of navigators whose prompts duck the music
# ("package  allow-adjust-navi-volume  volume-mix"). It differs per firmware (UIS8581 carries a line
# UIS7862 does not), so the module never ships a fixed copy: it edits the unit's own list.
#   - the six iGo builds are listed "false" by the factory -> "true" (their prompts duck like the rest);
#   - navigators the factory list lacks are appended, and Google TTS (prompts spoken through TTS).

BP_NAVI_ON="com.navngo.igo.javaclient com.basarsoft.igo.javaclient com.nng.igoprimoisr2013march24.javaclient com.nng.igo.primong.igoworld com.nng.igoprimo.javaclient com.nng.igoprimoisrael.javaclient"
BP_NAVI_ADD="pl.aqurat.automapa com.sygic.aura com.tomtom.gplay.navapp com.tomtom.gplay.navapp.nds com.generalmagic.magicearth net.osmand net.osmand.plus ru.dublgis.dgismobile com.mapfactor.navigator ru.yandex.yandexmaps com.mapswithme.maps.pro app.organicmaps com.google.android.tts"

# $1 = the unit's list, $2 = where to write ours. Returns 0 written, 1 no source.
bp_naviapp_build() {
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
