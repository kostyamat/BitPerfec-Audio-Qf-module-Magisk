package com.radiorubka.bitperfect.core;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
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

    // One root shell for the app's lifetime: Magisk asks (and toasts) once, not on every status poll.
    private static final String END = "__BP_END__";
    private static Process shell;
    private static BufferedReader shellOut;
    private static OutputStreamWriter shellIn;

    private static synchronized Result run(String args) {
        Result r = new Result();
        try {
            if (shell == null || !shell.isAlive()) open();
            shellIn.write("sh " + CTL + " " + args + " 2>&1; echo " + END + " $?\n");
            shellIn.flush();
            long deadline = System.currentTimeMillis() + TimeUnit.SECONDS.toMillis(TIMEOUT_S);
            String line;
            while ((line = shellOut.readLine()) != null) {
                if (line.startsWith(END)) {
                    if (!line.trim().endsWith(" 0") && r.values.isEmpty()) r.error = "no_module";
                    return r;
                }
                int eq = line.indexOf('=');
                if (eq > 0) {
                    String k = line.substring(0, eq).trim();
                    String v = line.substring(eq + 1).trim();
                    String prev = r.values.get(k);
                    r.values.put(k, prev == null ? v : prev + "\n" + v); // repeated keys (playing=) are joined
                }
                if (System.currentTimeMillis() > deadline) break;
            }
            close(); // the shell died (su refused) or hung
            r.error = r.values.isEmpty() ? "no_root" : "timeout";
        } catch (Exception e) {
            close();
            r.error = "no_root";
        }
        return r;
    }

    private static void open() throws IOException {
        shell = new ProcessBuilder("su").redirectErrorStream(true).start();
        shellOut = new BufferedReader(new InputStreamReader(shell.getInputStream(), StandardCharsets.UTF_8));
        shellIn = new OutputStreamWriter(shell.getOutputStream(), StandardCharsets.UTF_8);
    }

    private static void close() {
        if (shell != null) shell.destroy();
        shell = null;
    }
}
