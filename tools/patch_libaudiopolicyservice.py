#!/usr/bin/env python3
"""Shared microphone: AudioPolicyService::updateUidStates_l stops silencing all but one capture app.

AOSP 10 lets only the uid on top (or, with none on top, the latest started) capture; every other
active client gets APP_STATE_IDLE and AudioFlinger feeds it zeros (`silenced:true`) - QF DVR next to
wDSP Pro silenced one of them. The patch forces "is top or latest" true for every client:
`orr w9, w9, w10` (isTopOrLatestActive | isLatestSensitive) becomes `mov w9, #1`. The rest of the
rule stays: the assistant on top, a privacy-sensitive capture (VOICE_COMMUNICATION / CAMCORDER) and
an active call still silence the others; sensor privacy still silences everyone.
QF's build already treats AUDIO_SOURCE_MIC as a virtual source (mask 0x11e), never silenced.

Usage: patch_libaudiopolicyservice.py 7862|8581 <lib64/libaudiopolicyservice.so>   (in place)
Base: stock /system/lib64/libaudiopolicyservice.so
  7862 (QF update(2))      md5 9138eb08a6eaff6377532c8e04cd84e6 -> 1a30dfafbdaeaf3b4d95b51e7920dcfe
  8581 (QF005, BMW same)   md5 f08142f62fa9561214b160800b6201f2 -> f374a444ae32ba488081fecd648a799f
Contract: C:\\APPS_Contacts\\BitPerfect--DVR\\MIC_CLIENT_CONTRACT.md
"""
import sys

OFFS = {"7862": 0x18528, "8581": 0x1850c}  # file offset == vaddr (first two LOAD segments identity-mapped)
OLD = bytes.fromhex("29010a2a")  # orr w9, w9, w10
NEW = bytes.fromhex("29008052")  # mov w9, #1

if len(sys.argv) != 3 or sys.argv[1] not in OFFS:
    sys.exit(__doc__)
OFF, path = OFFS[sys.argv[1]], sys.argv[2]
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
