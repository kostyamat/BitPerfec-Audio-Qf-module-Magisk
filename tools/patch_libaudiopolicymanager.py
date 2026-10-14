#!/usr/bin/env python3
"""Stop AudioPolicyManagerSPRD::startOutput from sending `sprd_voip_start=true` to the HAL (UIS7862).

The Unisoc wrapper sends it whenever a STREAM_VOICE_CALL output starts on the primary output in
communication mode. In that mode the UIS7862 HAL opens the capture as VOIP_RECORD but in_read
computes NORMAL_RECORD, so it standbys and reopens the input on every read (~240 ms): the far end
hears stutter, crackle or silence. Telegram plays the call on STREAM_VOICE_CALL and hits it;
WhatsApp does not and works (HAL normal record + its own AEC). This patch keeps every app on the
WhatsApp path.

Patch: at 0x138f0 `cbnz w23, 0x1386c` ("stream != VOICE_CALL -> skip") becomes `b 0x1386c`
(always skip). policy_force_fm_mute and everything else in startOutput stays as it was;
stopOutput/releaseOutput only send `false` when the flag set here is up, and it never is.

Usage: patch_libaudiopolicymanager.py <lib64/libaudiopolicymanager.so>   (in place)
Base: stock /system/lib64/libaudiopolicymanager.so, md5 2965f48cf63fe077b87b770c945bd5a1.
"""
import sys

OFF = 0x138f0               # file offset == vaddr (first two LOAD segments are identity-mapped)
OLD = bytes.fromhex("f7fbff35")  # cbnz w23, 0x1386c
NEW = bytes.fromhex("dfffff17")  # b    0x1386c

if len(sys.argv) != 2:
    sys.exit(__doc__)
path = sys.argv[1]
data = bytearray(open(path, "rb").read())
cur = bytes(data[OFF:OFF + 4])
if cur == NEW:
    print(f"{path}: already patched")
elif cur != OLD:
    sys.exit(f"{path}: unexpected bytes at {OFF:#x}: {cur.hex()} — not the stock library, refusing")
else:
    data[OFF:OFF + 4] = NEW
    open(path, "wb").write(data)
    print(f"{path}: patched at {OFF:#x}")
