/*
 * Prints one line whenever one of the named system properties changes, without polling: bionic's
 * __system_property_wait sleeps on a futex (0 % CPU) and wakes at the next property change anywhere
 * (.agents/platform/22-WATCHING-PROPERTIES.md; the wDSP line does the same through JNI).
 *
 *   bp_propwait <tick ms> <name> [name...]
 *
 * Line: "C v1 v2 ..." when a value changed (and once at start), "T v1 v2 ..." on a quiet tick. An empty value is "-".
 * Values with spaces are not expected from these properties. Ends when the reader closes the pipe (SIGPIPE).
 *
 * Build (WSL, -u root): tools/native/build.sh -> common/bp_propwait, arm64: every QF firmware we have.
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/system_properties.h>
#include <time.h>

#define MAX_PROPS 16

static char now[MAX_PROPS][PROP_VALUE_MAX];

static int read_all(int n, char **names) {
    int changed = 0;
    for (int i = 0; i < n; i++) {
        char v[PROP_VALUE_MAX] = "";
        __system_property_get(names[i], v);
        if (strcmp(v, now[i]) != 0) {
            strcpy(now[i], v);
            changed = 1;
        }
    }
    return changed;
}

static void put(char kind, int n) {
    putchar(kind);
    for (int i = 0; i < n; i++) printf(" %s", now[i][0] ? now[i] : "-");
    putchar('\n');
    fflush(stdout);
}

int main(int argc, char **argv) {
    if (argc < 3 || argc - 2 > MAX_PROPS) {
        fprintf(stderr, "usage: bp_propwait <tick ms> <name> [name...]\n");
        return 2;
    }
    long tick = atol(argv[1]);
    int n = argc - 2;
    char **names = argv + 2;
    struct timespec ts = {tick / 1000, (tick % 1000) * 1000000L};
    uint32_t serial = 0;

    /* The serial before the read: a change between the two wakes the wait at once. Waiting for "not 0" returns it. */
    __system_property_wait(NULL, 0, &serial, &ts);
    read_all(n, names);
    put('C', n);
    for (;;) {
        uint32_t next = serial;
        int woke = __system_property_wait(NULL, serial, &next, &ts);
        if (woke) serial = next;
        if (read_all(n, names)) put('C', n);
        else if (!woke) put('T', n);
    }
}
