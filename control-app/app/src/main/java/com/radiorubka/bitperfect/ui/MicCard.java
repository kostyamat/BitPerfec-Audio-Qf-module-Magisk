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
 * noise reduction on/off. The module owns the rule ({@code bp_ctl.sh mic}); one change = one audioserver restart,
 * so the level is sent when the slider is let go, not while it moves.
 */
public final class MicCard {

    private static final String[] CHANNELS = {"SIM", "VOIP", "BT"};

    private final Activity act;
    private final ExecutorService io;
    private final Handler ui = new Handler(Looper.getMainLooper());
    private final MaterialButton[] btnCh = new MaterialButton[3];
    private final MaterialButton btnAec, btnNr, btnReset;
    private final TextView tvGain, tvResult;
    private final SeekBar sbGain;
    /** channel -> {gain_db, aec, nr} as the module reports them. */
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
        btnReset = act.findViewById(R.id.btn_mic_reset);
        tvGain = act.findViewById(R.id.tv_mic_gain);
        tvResult = act.findViewById(R.id.tv_mic_result);
        sbGain = act.findViewById(R.id.sb_mic_gain);
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
        btnReset.setOnClickListener(v -> resetChannel());
        for (MaterialButton b : new MaterialButton[]{btnAec, btnNr, btnReset}) TouchGlow.attach(b);
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
        return s != null ? s : new int[]{0, 1, 1};
    }

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
                    if (f.length < 4) continue;
                    try {
                        state.put(f[0], new int[]{Integer.parseInt(f[1]), Integer.parseInt(f[2]), Integer.parseInt(f[3])});
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
        for (int i = 0; i < 3; i++) btnCh[i].setChecked(i == channel);
        applyTheme();
    }

    /** value "" = BitPerfect's own (the line is removed from mic.conf). */
    private void set(String control, String value) {
        String ch = CHANNELS[channel];
        tvResult.setText(R.string.status_loading);
        io.execute(() -> {
            ModuleControl.Result r = ModuleControl.micSet(ch, control, value);
            ui.post(() -> {
                showResult(r);
                load();
            });
        });
    }

    private void resetChannel() {
        String ch = CHANNELS[channel];
        tvResult.setText(R.string.status_loading);
        io.execute(() -> {
            ModuleControl.micSet(ch, "aec", "");
            ModuleControl.micSet(ch, "nr", "");
            ModuleControl.Result r = ModuleControl.micSet(ch, "gain_db", "");
            ui.post(() -> {
                showResult(r);
                load();
            });
        });
    }

    private void showResult(ModuleControl.Result r) {
        String res = r.get("mic_result");
        if (!r.ok()) tvResult.setText(act.getString(R.string.usb_result_error, r.error));
        else if ("changed".equals(res)) tvResult.setText(R.string.usb_result_changed);
        else if ("same".equals(res)) tvResult.setText(R.string.usb_result_same);
        else if ("saved_in_call".equals(res)) tvResult.setText(R.string.mic_saved_in_call);
        else tvResult.setText(act.getString(R.string.usb_result_error, res));
    }

    public void applyTheme() {
        for (MaterialButton b : btnCh) ToggleStyler.apply(b);
        ToggleStyler.apply(btnAec);
        ToggleStyler.apply(btnNr);
        ToggleStyler.apply(btnReset);
    }
}
