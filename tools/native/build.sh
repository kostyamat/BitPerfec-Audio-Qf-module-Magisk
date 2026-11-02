#!/bin/bash
# Build common/bp_propwait (run in WSL: wsl -u root -e bash tools/native/build.sh, from the repo root).
set -e
NDK=/root/android-ndk-r26d/toolchains/llvm/prebuilt/linux-x86_64/bin
"$NDK/aarch64-linux-android29-clang" -O2 -Wall -Wextra -s -o common/bp_propwait tools/native/bp_propwait.c
"$NDK/llvm-readelf" -d common/bp_propwait | grep -E 'NEEDED'
ls -l common/bp_propwait
