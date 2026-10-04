O=$1; mkdir -p $O; T0=$(date '+%m-%d %H:%M:%S.000')
i=0; while [ "$(getprop sys.qf.call_state)" != "true" ] && [ $i -lt 600 ]; do sleep 1; i=$((i+1)); done
echo "call_state true after ${i}s" > $O/info.txt
sleep 6
tinymix > $O/tinymix_call.txt 2>&1
getprop | grep -E 'call_state|vol.type|sound.channel|bt' > $O/props.txt
dumpsys audio | grep -i -E 'mode|sco|bluetooth' | head -30 > $O/audio.txt
dumpsys media.audio_policy | grep -B2 -A3 'Source:' > $O/rec_clients.txt
i=0; while [ "$(getprop sys.qf.call_state)" = "true" ] && [ $i -lt 900 ]; do sleep 2; i=$((i+2)); done
echo "call ended after ${i}s" >> $O/info.txt
logcat -d -v time -t "$T0" > $O/logcat.txt 2>&1
echo done >> $O/info.txt
