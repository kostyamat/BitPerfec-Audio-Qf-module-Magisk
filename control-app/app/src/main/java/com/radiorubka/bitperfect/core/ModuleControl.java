package com.radiorubka.bitperfect.core;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * Talks to the BitPerfect module through its one control entry point, {@code common/bp_ctl.sh}, as root.
 * The app never writes the module's files itself: the module owns every rule (paths, the policy include,
 * when audioserver must restart), the app only asks. Blocking calls - run them off the main thread.
 */
public final class ModuleControl {

    public static final String MODULE_DIR = "/data/adb/modules/BitPerfect.module";
    private static final String CTL = MODULE_DIR + "/common/bp_ctl.sh";
    private static final long TIMEOUT_S = 20;

    private ModuleControl() {
    }

    /** Result of one call: the key=value lines it printed, or why there are none. */
    public static final class Result {
        public final Map<String, String> values = new LinkedHashMap<>();
        public String error; // null = ok

        public String get(String key) {
            String v = values.get(key);
            return v == null ? "" : v;
        }

        public boolean ok() {
            return error == null;
        }
    }

    public static Result status() {
        return run("status");
    }

    /** {@code usb_result}: changed (audioserver restarted), same, unsupported, bad_value. */
    public static Result setUsbDac(boolean on) {
        return run("usb " + (on ? "1" : "0"));
    }

    private static Result run(String args) {
        Result r = new Result();
        Process p = null;
        try {
            p = new ProcessBuilder("su", "-c", "sh " + CTL + " " + args).redirectErrorStream(true).start();
            try (BufferedReader in = new BufferedReader(new InputStreamReader(p.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = in.readLine()) != null) {
                    int eq = line.indexOf('=');
                    if (eq > 0) {
                        String k = line.substring(0, eq).trim();
                        String v = line.substring(eq + 1).trim();
                        String prev = r.values.get(k);
                        r.values.put(k, prev == null ? v : prev + "\n" + v); // repeated keys (playing=) are joined
                    }
                }
            }
            if (!p.waitFor(TIMEOUT_S, TimeUnit.SECONDS)) {
                r.error = "timeout";
            } else if (p.exitValue() != 0 && r.values.isEmpty()) {
                r.error = "no_root_or_module"; // su refused, or the module is not installed
            }
        } catch (Exception e) {
            r.error = "no_root";
        } finally {
            if (p != null) p.destroy();
        }
        return r;
    }
}
