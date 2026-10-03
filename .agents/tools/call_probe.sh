# runs on the device as root; $1 = output dir
O=$1; mkdir -p $O
T0=$(date '+%m-%d %H:%M:%S.000')
echo "$T0" > $O/t0
tinymix > $O/tinymix_idle.txt 2>&1
am start -a android.intent.action.CALL -d tel:1200 -n com.android.server.telecom/.components.UserCallActivity >/dev/null 2>&1
sleep 12
dumpsys audio | grep -i -E 'mode|in call' | head -20 > $O/audio_mode.txt
dumpsys telecom | grep -i -E 'state|route|audioState' | head -30 > $O/telecom.txt
tinymix > $O/tinymix_call.txt 2>&1
getprop | grep -E 'call_state|vol.type|sound.channel' > $O/props.txt
sleep 6
input keyevent 6
sleep 3
dumpsys telecom | grep -i -c 'STATE_ACTIVE' > $O/after_hangup_active.txt
logcat -d -v time -t "$T0" > $O/logcat.txt 2>&1
echo done
