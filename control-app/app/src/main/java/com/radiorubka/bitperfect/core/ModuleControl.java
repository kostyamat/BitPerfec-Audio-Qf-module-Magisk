package com.radiorubka.bitperfect.core;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.regex.Pattern;

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

    /** {@code usb_mode_result}: changed (audioserver restarted), saved (USB off), same, bad_value. */
    public static Result setUsbMode(String mode) {
        if (!USB_MODE.matcher(mode).matches()) {
            Result r = new Result();
            r.values.put("usb_mode_result", "bad_value");
            return r;
        }
        return run("usb_mode " + mode);
    }

    private static final Pattern USB_MODE = Pattern.compile("auto|S(16|24|32)_(3)?LE/[0-9]{4,6}");

    /** {@code mic} lines: "channel gain_db aec nr nr_depth" (SIM, VOIP, BT; UIS7862 only; nr_depth 0 = BitPerfect's). */
    public static Result micShow() {
        return run("mic show");
    }

    /** value "" = back to BitPerfect's. {@code mic_result}: changed|same|saved_in_call|bad_value. */
    public static Result micSet(String channel, String control, String value) {
        if (!MIC_CH.matcher(channel).matches() || !MIC_CTL.matcher(control).matches()
                || !(value.isEmpty() || MIC_VAL.matcher(value).matches())) {
            Result r = new Result();
            r.values.put("mic_result", "bad_value");
            return r;
        }
        return run("mic set " + channel + " " + control + (value.isEmpty() ? "" : " " + value));
    }

    /** The channel back to BitPerfect's tuning, one audioserver restart. */
    public static Result micReset(String channel) {
        if (!MIC_CH.matcher(channel).matches()) return bad("mic_result");
        return run("mic reset " + channel);
    }

    /** {@code preset} lines: the saved names. */
    public static Result micPresets() {
        return run("mic preset list");
    }

    /** action save|load|del. {@code mic_result}: saved|changed|same|saved_in_call|bad_value|no_preset. */
    public static Result micPreset(String action, String name) {
        if (!MIC_PRESET_ACT.matcher(action).matches() || !MIC_PRESET.matcher(name).matches()) return bad("mic_result");
        return run("mic preset " + action + " " + name);
    }

    private static Result bad(String key) {
        Result r = new Result();
        r.values.put(key, "bad_value");
        return r;
    }

    private static final Pattern MIC_CH = Pattern.compile("SIM|VOIP|BT");
    private static final Pattern MIC_CTL = Pattern.compile("gain_db|aec|nr|nr_depth");
    private static final Pattern MIC_PRESET_ACT = Pattern.compile("save|load|del");
    /** The module's rule too: letters of any script, digits, '-', '_' - nothing a shell or a path reads. */
    public static final Pattern MIC_PRESET = Pattern.compile("[\\p{L}\\p{N}_-]{1,48}");
    private static final Pattern MIC_VAL = Pattern.compile("-?[0-9]{1,2}");

    /** {@code navi} lines: "package adjust mix origin" (origin factory|bitperfect|user). */
    public static Result naviList() {
        return run("navi list");
    }

    /** Add or change the user's entry; mix = "appset" or 0..100. {@code navi_result}: saved|bad_value|no_base. */
    public static Result naviSet(String pkg, boolean adjust, String mix) {
        if (!PKG.matcher(pkg).matches() || !MIX.matcher(mix).matches()) {
            Result r = new Result();
            r.values.put("navi_result", "bad_value");
            return r;
        }
        return run("navi set " + pkg + " " + adjust + " " + mix);
    }

    /** Remove the user's entry (a factory or BitPerfect line comes back as it was). */
    public static Result naviDel(String pkg) {
        if (!PKG.matcher(pkg).matches()) {
            Result r = new Result();
            r.values.put("navi_result", "bad_value");
            return r;
        }
        return run("navi del " + pkg);
    }

    // Checked here as well as in the module: these strings go into a root shell command line.
    private static final Pattern PKG = Pattern.compile("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z0-9_]+)+");
    private static final Pattern MIX = Pattern.compile("appset|[0-9]{1,2}|100");

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
