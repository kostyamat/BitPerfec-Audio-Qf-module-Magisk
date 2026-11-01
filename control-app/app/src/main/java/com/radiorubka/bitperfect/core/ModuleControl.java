package com.radiorubka.bitperfect.core;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.FutureTask;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.regex.Pattern;

/**
 * Talks to the BitPerfect module through its one control entry point, {@code common/bp_ctl.sh}, as root.
 * The app never writes the module's files itself: the module owns every rule (paths, the policy include,
 * when audioserver must restart), the app only asks. Blocking calls - run them off the main thread.
 */
public final class ModuleControl {

    public static final String MODULE_DIR = "/data/adb/modules/BitPerfect.module";
    private static final String CTL = MODULE_DIR + "/common/bp_ctl.sh";
    // su waits while the person answers the Magisk prompt; a microphone change also restarts audioserver.
    private static final long TIMEOUT_S = 90;

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

    /** full = the DAC at its maximum; follow = its own volume control follows the head unit's knob. */
    public static Result setUsbVolume(boolean follow) {
        return run("usb_volume " + (follow ? "follow" : "full"));
    }

    /** Where knob 1, 8, 16, 24, 32 land on this DAC, in % of its control: "a,b,c,d,e", or "default". */
    public static Result setUsbCurve(String curve) {
        if (!USB_CURVE.matcher(curve).matches()) {
            Result r = new Result();
            r.values.put("usb_curve_result", "bad_value");
            return r;
        }
        return run("usb_curve " + curve);
    }

    private static final Pattern USB_CURVE = Pattern.compile("default|[0-9]{1,3}(\\.[0-9]{1,3})?(,[0-9]{1,3}(\\.[0-9]{1,3})?){4}");
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
    private static boolean answered; // this shell has answered at least once
    private static volatile boolean rootRefused;

    /** Ask Magisk again on the next call: only on the person's request, never from the status poll. */
    public static void retryRoot() {
        rootRefused = false;
    }

    private static synchronized Result run(String args) {
        Result r = new Result();
        if (rootRefused) {
            r.error = "no_root";
            return r;
        }
        try {
            if (shell == null || !shell.isAlive()) open();
            shellIn.write("sh " + CTL + " " + args + " 2>&1; echo " + END + " $?\n");
            shellIn.flush();
            // Read on the side: a hung su blocks readLine for good, and everything else waits for this lock.
            final BufferedReader out = shellOut;
            FutureTask<Boolean> read = new FutureTask<>(() -> readAnswer(out, r));
            Thread reader = new Thread(read, "bp-shell-read");
            reader.setDaemon(true);
            reader.start();
            if (read.get(TIMEOUT_S, TimeUnit.SECONDS)) {
                answered = true;
                return r;
            }
            return failed(r.values.isEmpty()); // the shell ended without the end mark: su refused, or it died
        } catch (TimeoutException e) {
            return failed(true);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            close();
            Result gone = new Result();
            gone.error = "timeout";
            return gone;
        } catch (Exception e) {
            return failed(true);
        }
    }

    /** Parses one command's output into {@code r}. True at the end mark, false if the shell ended first. */
    private static boolean readAnswer(BufferedReader out, Result r) throws IOException {
        String line;
        while ((line = out.readLine()) != null) {
            if (line.startsWith(END)) {
                if (!line.trim().endsWith(" 0") && r.values.isEmpty()) r.error = "no_module";
                return true;
            }
            int eq = line.indexOf('=');
            if (eq > 0) {
                String k = line.substring(0, eq).trim();
                String v = line.substring(eq + 1).trim();
                String prev = r.values.get(k);
                r.values.put(k, prev == null ? v : prev + "\n" + v); // repeated keys (playing=) are joined
            }
        }
        return false;
    }

    /** A new Result: a timed-out reader may still be writing into the old one. */
    private static Result failed(boolean nothingCame) {
        Result r = new Result();
        // A shell that never answered means no root: stop asking Magisk until the person says so.
        if (nothingCame && !answered) {
            rootRefused = true;
            r.error = "no_root";
        } else {
            r.error = "timeout";
        }
        close();
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
        answered = false;
    }
}
