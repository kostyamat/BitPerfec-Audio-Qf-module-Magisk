#!/system/bin/sh
# Sourced by bp_ctl.sh and service.sh - the one place for the user's microphone settings (UIS7862).
# Map and field provenance: .agents/MIC_CONTROL.md.
#
# The module ships its tuned AGDSP XML in common/system/vendor/etc/audio_params/sprd/ (the base) and Magisk
# mounts the copy in system/vendor/... over /vendor (the live file). Applying = live = base + the user's
# lines from $BP_MIC_CONF, written in place (same inode, the mount keeps showing it), then the compiled
# blob in /data is deleted and audioserver restarted: the HAL rebuilds a missing blob from the XML.
#
# $BP_MIC_CONF lines: <channel> <control> <value>
#   channel  SIM (Handsfree NB..FB) | VOIP (Handsfree VOIP1) | BT (BTHS + BTHSNREC, all)
#   gain_db  -12..12   uplink digital gain (ul_dgain_volume1..15) relative to BitPerfect's, after AEC
#   aec      0|1       cvs TX_MODUAL/AEC: 1 = BitPerfect's value, 0 = off
#   nr       0|1       cvs TX_MODUAL/POS (post filter, noise) - 1 = BitPerfect's value, 0 = off
#   nr_depth -24..-3   cvs Tx_Mono_Post/Gain_limit, the deepest cut of the noise post filter in dB (Q15 gain;
#                      BitPerfect ships 0x2666 = -10.5 dB in every mode, factory -8..-18 dB by mode)
# Presets: $BP_MIC_DIR/mic.preset.<name>.conf, the same lines; loading one replaces $BP_MIC_CONF.
# Recording (wDSP / DVR) is not touched here: that path must stay flat.

BP_MIC_DIR=/sdcard/BitPerfectAudio
BP_MIC_CONF=$BP_MIC_DIR/mic.conf
BP_MIC_HEAD='# BitPerfect - your microphone settings (BitPerfect Control edits this file)
# channel (SIM|VOIP|BT)  control (gain_db -12..12 | aec 0|1 | nr 0|1 | nr_depth -24..-3)  value'
BP_MIC_BLOBS=/data/vendor/local/media/audio_params
BP_MIC_SIM="Handsfree/NB1 Handsfree/NB2 Handsfree/WB1 Handsfree/WB2 Handsfree/SWB1 Handsfree/FB1"
BP_MIC_VOIP="Handsfree/VOIP1"
BP_MIC_BT="BTHS/NB1 BTHS/NB2 BTHS/WB1 BTHS/WB2 BTHS/SWB1 BTHS/FB1 BTHS/VOIP1 BTHSNREC/NB1 BTHSNREC/NB2 BTHSNREC/WB1 BTHSNREC/WB2 BTHSNREC/SWB1 BTHSNREC/FB1 BTHSNREC/VOIP1"

bp_mic_modes() {
    case "$1" in SIM) echo "$BP_MIC_SIM" ;; VOIP) echo "$BP_MIC_VOIP" ;; BT) echo "$BP_MIC_BT" ;; *) return 1 ;; esac
}

# 0 when "$1 $2 $3" is a line we can apply.
bp_mic_valid() {
    bp_mic_modes "$1" >/dev/null || return 1
    case "$2" in
        gain_db) echo "$3" | grep -qE '^-?[0-9]{1,2}$' && [ "$3" -ge -12 ] && [ "$3" -le 12 ] ;;
        aec|nr) [ "$3" = 0 ] || [ "$3" = 1 ] ;;
        nr_depth) echo "$3" | grep -qE '^-[0-9]{1,2}$' && [ "$3" -ge -24 ] && [ "$3" -le -3 ] ;;
        *) return 1 ;;
    esac
}

# The user's valid lines, last one per channel+control wins: "channel control value".
bp_mic_lines() {
    [ -f "$BP_MIC_CONF" ] || return 0
    tr -d '\r' < "$BP_MIC_CONF" | while read -r c k v _; do
        case "$c" in ''|'#'*) continue ;; esac
        bp_mic_valid "$c" "$k" "$v" && echo "$c $k $v"
    done | awk '{ last[$1 " " $2] = $3 } END { for (k in last) print k, last[k] }'
}

# Rules for one file: "Group/Mode[/Block]/tag op arg" (op = scale <dB> | zero).
bp_mic_rules() {
    bp_mic_lines | while read -r c k v; do
        for m in $(bp_mic_modes "$c"); do
            case "$1:$k" in
                audio_structure.xml:gain_db)
                    [ "$v" = 0 ] && continue
                    i=1; while [ $i -le 15 ]; do echo "$m/ul_dgain_volume$i scale $v"; i=$((i + 1)); done ;;
                cvs.xml:aec) [ "$v" = 0 ] && echo "$m/TX_MODUAL/AEC zero 0" ;;
                cvs.xml:nr)  [ "$v" = 0 ] && echo "$m/TX_MODUAL/POS zero 0" ;;
                cvs.xml:nr_depth) echo "$m/Tx_Mono_Post/Gain_limit q15db $v" ;;
            esac
        done
    done
}

# base XML $1 + rules file $2 -> stdout. Paths are taken below the <Audio> element.
# op: zero | scale <dB> (relative to the base value) | q15db <dB> (absolute Q15 gain).
bp_mic_awk() {
    awk -v rules="$2" '
        BEGIN { while ((getline l < rules) > 0) { split(l, a, " "); op[a[1]] = a[2]; arg[a[1]] = a[3] } }
        function path(t,   i, s, on) { s = ""; on = 0
            for (i = 1; i <= d; i++) { if (on) s = s st[i] "/"; if (st[i] == "Audio") on = 1 }
            return s t }
        /<\/[A-Za-z0-9_]+>/ && !/<[A-Za-z0-9_]+[ >].*\/>/ { print; if (d > 0) d--; next }
        /<[A-Za-z0-9_]+[ >]/ && !/\/>/ && !/<\?/ && !/<\// { match($0, /<[A-Za-z0-9_]+/); d++; st[d] = substr($0, RSTART + 1, RLENGTH - 1); print; next }
        /<[A-Za-z0-9_]+ .*val="[^"]*".*\/>/ {
            match($0, /<[A-Za-z0-9_]+/); t = substr($0, RSTART + 1, RLENGTH - 1); k = path(t)
            if (k in op) {
                match($0, /val="[^"]*"/); v = substr($0, RSTART + 5, RLENGTH - 6)
                if (op[k] == "zero") nv = "0x00"
                else if (op[k] == "q15db") nv = sprintf("0x%04x", int(32768 * exp(arg[k] / 20 * log(10)) + 0.5))
                else { n = 0; h = tolower(v); sub(/^0x/, "", h)
                       for (i = 1; i <= length(h); i++) n = n * 16 + index("0123456789abcdef", substr(h, i, 1)) - 1
                       n = int(n * exp(arg[k] / 20 * log(10)) + 0.5); if (n > 32767) n = 32767
                       nv = sprintf("0x%04x", n) }
                sub(/val="[^"]*"/, "val=\"" nv "\"")
            }
            print; next }
        { print }' "$1"
}

# Rebuild the live files of module dir $1 from base + the user's lines. Returns 0 changed, 2 unchanged,
# 1 not built. Nothing of the user's: the live file is the base itself, no awk (12 s at boot on 4.7 MB of XML).
# The same lines as last time: already built. A cut-short awk (out of memory at boot, full disk) must never
# reach the live file: the HAL would compile the torn XML into a blob.
bp_mic_build() {
    BPM_RC=2
    for f in audio_structure.xml cvs.xml; do
        BPM_B="$1/common/system/vendor/etc/audio_params/sprd/$f"
        BPM_L="$1/system/vendor/etc/audio_params/sprd/$f"
        BPM_D="$1/common/.mic_rules.$f"
        [ -f "$BPM_B" ] && [ -f "$BPM_L" ] || continue
        BPM_R=/data/local/tmp/bp_mic_rules.$$; BPM_T=/data/local/tmp/bp_mic_out.$$
        bp_mic_rules "$f" > "$BPM_R"
        BPM_S=$BPM_B
        if [ -s "$BPM_R" ]; then
            if cmp -s "$BPM_R" "$BPM_D"; then rm -f "$BPM_R"; continue; fi
            bp_mic_awk "$BPM_B" "$BPM_R" > "$BPM_T"
            if [ $? -ne 0 ] || [ "$(wc -l < "$BPM_T")" != "$(wc -l < "$BPM_B")" ]; then
                [ "$BPM_RC" = 0 ] || BPM_RC=1
                rm -f "$BPM_R" "$BPM_T"
                continue
            fi
            BPM_S=$BPM_T
        fi
        if ! cmp -s "$BPM_S" "$BPM_L"; then
            cat "$BPM_S" > "$BPM_L"
            rm -f "$BP_MIC_BLOBS/${f%.xml}"
            BPM_RC=0
        fi
        if [ -s "$BPM_R" ]; then cat "$BPM_R" > "$BPM_D"; else rm -f "$BPM_D"; fi
        rm -f "$BPM_R" "$BPM_T"
    done
    return $BPM_RC
}

# Current settings per channel, BitPerfect's defaults where the user set nothing:
# "channel gain_db aec nr nr_depth" (nr_depth 0 = BitPerfect's -10.5 dB).
bp_mic_show() {
    BPM_L=$(bp_mic_lines)
    for c in SIM VOIP BT; do
        g=$(echo "$BPM_L" | awk -v c=$c '$1 == c && $2 == "gain_db" { print $3 }')
        a=$(echo "$BPM_L" | awk -v c=$c '$1 == c && $2 == "aec" { print $3 }')
        n=$(echo "$BPM_L" | awk -v c=$c '$1 == c && $2 == "nr" { print $3 }')
        z=$(echo "$BPM_L" | awk -v c=$c '$1 == c && $2 == "nr_depth" { print $3 }')
        echo "$c ${g:-0} ${a:-1} ${n:-1} ${z:-0}"
    done
}

# Set (or with $3 empty, remove) one line in the user's file. Returns 0 saved, 1 bad value.
bp_mic_set() {
    [ -n "$3" ] && ! bp_mic_valid "$1" "$2" "$3" && return 1
    mkdir -p "$(dirname "$BP_MIC_CONF")"
    [ -f "$BP_MIC_CONF" ] || echo "$BP_MIC_HEAD" > "$BP_MIC_CONF"
    BPM_T=/data/local/tmp/bp_mic_conf.$$
    tr -d '\r' < "$BP_MIC_CONF" | awk -v c="$1" -v k="$2" '!($1 == c && $2 == k)' > "$BPM_T"
    [ -n "$3" ] && echo "$1 $2 $3" >> "$BPM_T"
    cat "$BPM_T" > "$BP_MIC_CONF"; rm -f "$BPM_T"
    return 0
}

# Back to BitPerfect's tuning for channel $1: every line of it leaves the user's file.
bp_mic_reset() {
    bp_mic_modes "$1" >/dev/null || return 1
    [ -f "$BP_MIC_CONF" ] || return 0
    BPM_T=/data/local/tmp/bp_mic_conf.$$
    tr -d '\r' < "$BP_MIC_CONF" | awk -v c="$1" '$1 != c' > "$BPM_T"
    cat "$BPM_T" > "$BP_MIC_CONF"; rm -f "$BPM_T"
}

# A preset name is a file name part: letters of any script, digits, '-', '_'; nothing a shell or a path reads.
bp_mic_preset_ok() {
    [ -n "$1" ] && [ ${#1} -le 48 ] || return 1
    case "$1" in *[/.\ \	\'\"\`\$\;\&\|\<\>\*\?\(\)\{\}\[\]\~\#\=\,\:\!\%\^\@\+]*) return 1 ;; esac
}

# preset list | save <name> | load <name> | del <name>. Returns 0 done, 1 bad name, 3 no such preset.
bp_mic_preset() {
    case "$1" in
        list)
            for f in "$BP_MIC_DIR"/mic.preset.*.conf; do
                [ -f "$f" ] || continue
                f=${f##*/mic.preset.}; echo "${f%.conf}"
            done ;;
        save)
            bp_mic_preset_ok "$2" || return 1
            mkdir -p "$BP_MIC_DIR"
            { echo "$BP_MIC_HEAD"; bp_mic_lines | sort; } > "$BP_MIC_DIR/mic.preset.$2.conf" ;;
        load)
            bp_mic_preset_ok "$2" || return 1
            [ -f "$BP_MIC_DIR/mic.preset.$2.conf" ] || return 3
            cat "$BP_MIC_DIR/mic.preset.$2.conf" > "$BP_MIC_CONF" ;;
        del)
            bp_mic_preset_ok "$2" || return 1
            [ -f "$BP_MIC_DIR/mic.preset.$2.conf" ] || return 3
            rm -f "$BP_MIC_DIR/mic.preset.$2.conf" ;;
        *) return 1 ;;
    esac
}
