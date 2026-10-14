#!/usr/bin/env python3
"""Let AUDIO_SOURCE_VOICE_COMMUNICATION (7) through QF's AudioRecord::set source override.

QF's AudioRecord::set forces every capture source to AUDIO_SOURCE_MIC (1). The cave added in aa7ac02
lets 6 (VOICE_RECOGNITION) and 9 (UNPROCESSED) through; this script rewrites the same caves to let
7 through as well. Without it a VoIP app (Telegram) opens source 1 while setMode(3) has set
sprd_voip_start, and the Unisoc HAL loops standby/reopen on the input every read (VOIP_RECORD vs
NORMAL_RECORD), which gives stutter, crackle and silence on the far end.

Usage: patch_libaudioclient.py <lib64/libaudioclient.so> <lib/libaudioclient.so>   (in place)
Each file must hold either the aa7ac02 cave (6, 9) or this script's cave (6, 7, 9).
"""
import sys

# arm64: cave at 0x3fdec, entered by `b 0x3fdec` at 0x4d584, returns to 0x4d588.
CAVE64 = 0x3fdec
OLD64 = bytes.fromhex(
    "694e41b9"  # ldr  w9, [x19, #0x14c]   (mAttributes.source)
    "3f190071"  # cmp  w9, #6
    "a0000054"  # b.eq 0x3fe08
    "3f250071"  # cmp  w9, #9
    "60000054"  # b.eq 0x3fe08
    "e9030032"  # orr  w9, wzr, #1
    "694e01b9"  # str  w9, [x19, #0x14c]
    "e0350014"  # b    0x4d588
    "00000000"
)
NEW64 = bytes.fromhex(
    "694e41b9"  # ldr  w9, [x19, #0x14c]
    "3f190071"  # cmp  w9, #6
    "e0000054"  # b.eq 0x3fe10
    "3f1d0071"  # cmp  w9, #7
    "a0000054"  # b.eq 0x3fe10
    "3f250071"  # cmp  w9, #9
    "60000054"  # b.eq 0x3fe10
    "e9030032"  # orr  w9, wzr, #1
    "694e01b9"  # str  w9, [x19, #0x14c]
)
NEW64 += bytes.fromhex("de350014")  # 0x3fe10: b 0x4d588
assert len(NEW64) == 40 and len(OLD64) == 36

# arm32 (Thumb-2): cave at 0x3090c, entered by `b 0x3090c` at 0x309d4, returns to 0x309d6.
CAVE32 = 0x3090c
OLD32 = bytes.fromhex(
    "d4f8d400"  # ldr.w r0, [r4, #0xd4]
    "0628"      # cmp   r0, #6
    "1cbf"      # itt   ne
    "0928"      # cmpne r0, #9
    "0120"      # movne r0, #1
    "c4f8d400"  # str.w r0, [r4, #0xd4]
    "5be0"      # b     0x309d6
    "c046"      # nop (mov r8, r8)
)
NEW32 = bytes.fromhex(
    "d4f8d400"  # ldr.w r0, [r4, #0xd4]
    "0628"      # cmp   r0, #6
    "1ebf"      # ittt  ne
    "0728"      # cmpne r0, #7
    "0928"      # cmpne r0, #9
    "0120"      # movne r0, #1
    "c4f8d400"  # str.w r0, [r4, #0xd4]
    "5ae0"      # b     0x309d6
)
assert len(NEW32) == len(OLD32) == 20


def patch(path, off, old, new):
    data = bytearray(open(path, "rb").read())
    cur = bytes(data[off:off + len(new)])
    if cur == new:
        print(f"{path}: already patched")
        return
    if bytes(data[off:off + len(old)]) != old or any(data[off + len(old):off + len(new)]):
        sys.exit(f"{path}: unexpected bytes at {off:#x}: {cur.hex()} — not the aa7ac02 cave, refusing")
    data[off:off + len(new)] = new
    open(path, "wb").write(data)
    print(f"{path}: patched at {off:#x}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    patch(sys.argv[1], CAVE64, OLD64, NEW64)
    patch(sys.argv[2], CAVE32, OLD32, NEW32)
