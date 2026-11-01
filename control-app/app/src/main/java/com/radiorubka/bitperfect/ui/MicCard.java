package com.radiorubka.bitperfect.ui;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.widget.SeekBar;
import android.widget.TextView;

import com.google.android.material.button.MaterialButton;
import com.radiorubka.bitperfect.R;
import com.radiorubka.bitperfect.core.ModuleControl;
import com.radiorubka.bitperfect.ui.theme.ToggleStyler;
import com.radiorubka.bitperfect.ui.theme.TouchGlow;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;

/**
 * Call microphone per channel (SIM, VoIP, Bluetooth): level relative to BitPerfect's tuning, echo cancelling and
 * noise reduction on/off, noise reduction depth, and named presets of the whole set. The module owns the rule
 * ({@code bp_ctl.sh mic}); one change = one audioserver restart, so a slider is sent when it is let go.
 */
public final class MicCard {

    private static final String[] CHANNELS = {"SIM", "VOIP", "BT"};

    private final Activity act;
    private final ExecutorService io;
    private final Handler ui = new Handler(Looper.getMainLooper());
    private final MaterialButton[] btnCh = new MaterialButton[3];
    private final MaterialButton btnAec, btnNr, btnPresets, btnReset;
    private final TextView tvGain, tvDepth, tvResult;
    private final SeekBar sbGain, sbDepth;
    /** channel -> {gain_db, aec, nr, nr_depth} as the module reports them (nr_depth 0 = BitPerfect's). */
    private final Map<String, int[]> state = new HashMap<>();
    private int channel;

    public MicCard(Activity act, ExecutorService io) {
        this.act = act;
        this.io = io;
        btnCh[0] = act.findViewById(R.id.btn_mic_sim);
        btnCh[1] = act.findViewById(R.id.btn_mic_voip);
        btnCh[2] = act.findViewById(R.id.btn_mic_bt);
        btnAec = act.findViewById(R.id.btn_mic_aec);
        btnNr = act.findViewById(R.id.btn_mic_nr);
        btnPresets = act.findViewById(R.id.btn_mic_presets);
        btnReset = act.findViewById(R.id.btn_mic_reset);
        tvGain = act.findViewById(R.id.tv_mic_gain);
        tvDepth = act.findViewById(R.id.tv_mic_nr_depth);
        tvResult = act.findViewById(R.id.tv_mic_result);
        sbGain = act.findViewById(R.id.sb_mic_gain);
        sbDepth = act.findViewById(R.id.sb_mic_nr_depth);
        for (int i = 0; i < 3; i++) {
            final int c = i;
            btnCh[i].setOnClickListener(v -> {
                channel = c;
                render();
            });
            TouchGlow.attach(btnCh[i]);
        }
        btnAec.setOnClickListener(v -> set("aec", cur()[1] == 1 ? "0" : ""));
        btnNr.setOnClickListener(v -> set("nr", cur()[2] == 1 ? "0" : ""));
        btnReset.setOnClickListener(v -> apply(() -> ModuleControl.micReset(CHANNELS[channel])));
        btnPresets.setOnClickListener(v -> showPresets());
        for (MaterialButton b : new MaterialButton[]{btnAec, btnNr, btnPresets, btnReset}) TouchGlow.attach(b);
        sbDepth.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar s, int p, boolean fromUser) {
                if (fromUser) tvDepth.setText(act.getString(R.string.mic_nr_depth, String.valueOf(depthOf(p))));
            }

            @Override
            public void onStartTrackingTouch(SeekBar s) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar s) {
                set("nr_depth", String.valueOf(depthOf(s.getProgress())));
            }
        });
        sbGain.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar s, int p, boolean fromUser) {
                tvGain.setText(act.getString(R.string.mic_gain, signed(p - 12)));
            }

            @Override
            public void onStartTrackingTouch(SeekBar s) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar s) {
                int db = s.getProgress() - 12;
                set("gain_db", db == 0 ? "" : String.valueOf(db));
            }
        });
    }

    private int[] cur() {
        int[] s = state.get(CHANNELS[channel]);
        return s != null ? s : new int[]{0, 1, 1, 0};
    }

    /** Depth slider: left -3 dB (gentle) .. right -24 dB (strong). */
    private static int depthOf(int progress) {
        return -(3 + progress);
    }

    private static final int DEPTH_BITPERFECT = -10; // the slider's nearest step to BitPerfect's -10.5 dB

    private static String signed(int db) {
        return db > 0 ? "+" + db : String.valueOf(db);
    }

    public void load() {
        io.execute(() -> {
            ModuleControl.Result r = ModuleControl.micShow();
            ui.post(() -> {
                state.clear();
                for (String line : r.get("mic").split("\n")) {
                    String[] f = line.trim().split("\\s+");
                    if (f.length < 5) continue;
                    try {
                        state.put(f[0], new int[]{Integer.parseInt(f[1]), Integer.parseInt(f[2]),
                                Integer.parseInt(f[3]), Integer.parseInt(f[4])});
                    } catch (NumberFormatException ignored) {
                    }
                }
                if (state.isEmpty()) tvResult.setText(R.string.mic_only_7862);
                render();
            });
        });
    }

    private void render() {
        int[] s = cur();
        sbGain.setProgress(s[0] + 12);
        tvGain.setText(act.getString(R.string.mic_gain, signed(s[0])));
        btnAec.setChecked(s[1] == 1);
        btnNr.setChecked(s[2] == 1);
        int depth = s[3] != 0 ? s[3] : DEPTH_BITPERFECT;
        sbDepth.setProgress(-depth - 3);
        sbDepth.setEnabled(s[2] == 1);
        tvDepth.setText(s[2] != 1 ? act.getString(R.string.mic_nr_depth_off)
                : s[3] == 0 ? act.getString(R.string.mic_nr_depth_bp)
                : act.getString(R.string.mic_nr_depth, String.valueOf(s[3])));
        for (int i = 0; i < 3; i++) btnCh[i].setChecked(i == channel);
        applyTheme();
    }

    /** value "" = BitPerfect's own (the line is removed from mic.conf). */
    private void set(String control, String value) {
        String ch = CHANNELS[channel];
        apply(() -> ModuleControl.micSet(ch, control, value));
    }

    private interface Call {
        ModuleControl.Result run();
    }

    private void apply(Call call) {
        tvResult.setText(R.string.status_loading);
        io.execute(() -> {
            ModuleControl.Result r = call.run();
            ui.post(() -> {
                showResult(r);
                load();
            });
        });
    }

    /** Saved presets first, then "save current as..."; a preset opens load / delete. */
    private void showPresets() {
        io.execute(() -> {
            ModuleControl.Result r = ModuleControl.micPresets();
            String all = r.get("preset");
            String[] names = all.isEmpty() ? new String[0] : all.split("\n");
            ui.post(() -> {
                String[] items = new String[names.length + 1];
                System.arraycopy(names, 0, items, 0, names.length);
                items[names.length] = act.getString(R.string.mic_preset_save);
                ThemedDialog.showList(act, act.getString(R.string.mic_preset_title), items, (d, which) -> {
                    if (which == names.length) askName();
                    else presetActions(names[which]);
                });
                if (names.length == 0) tvResult.setText(R.string.mic_preset_none);
            });
        });
    }

    private void askName() {
        ThemedDialog.showInput(act, act.getString(R.string.mic_preset_name),
                act.getString(R.string.mic_preset_name_hint), "",
                act.getString(R.string.navi_save), act.getString(R.string.navi_cancel), (d, text) -> {
                    String name = text.trim().replace(' ', '_');
                    if (!ModuleControl.MIC_PRESET.matcher(name).matches()) {
                        tvResult.setText(R.string.mic_bad_name);
                        return;
                    }
                    apply(() -> ModuleControl.micPreset("save", name));
                });
    }

    private void presetActions(String name) {
        String[] items = {act.getString(R.string.mic_preset_load), act.getString(R.string.mic_preset_delete)};
        ThemedDialog.showList(act, name, items, (d, which) -> {
            if (which == 0) apply(() -> ModuleControl.micPreset("load", name));
            else ThemedDialog.showConfirmation(act, name, act.getString(R.string.mic_preset_delete_ask, name),
                    act.getString(R.string.mic_preset_delete), act.getString(R.string.navi_cancel), true,
                    () -> apply(() -> ModuleControl.micPreset("del", name)));
        });
    }

    private void showResult(ModuleControl.Result r) {
        String res = r.get("mic_result");
        if (!r.ok()) tvResult.setText(act.getString(R.string.usb_result_error, r.error));
        else if ("changed".equals(res)) tvResult.setText(R.string.usb_result_changed);
        else if ("same".equals(res)) tvResult.setText(R.string.usb_result_same);
        else if ("saved_in_call".equals(res)) tvResult.setText(R.string.mic_saved_in_call);
        else if ("saved".equals(res)) tvResult.setText(R.string.mic_done);
        else if ("no_preset".equals(res)) tvResult.setText(R.string.mic_no_preset);
        else tvResult.setText(act.getString(R.string.usb_result_error, res));
    }

    public void applyTheme() {
        for (MaterialButton b : btnCh) ToggleStyler.apply(b);
        ToggleStyler.apply(btnAec);
        ToggleStyler.apply(btnNr);
        ToggleStyler.apply(btnPresets);
        ToggleStyler.apply(btnReset);
    }
}
