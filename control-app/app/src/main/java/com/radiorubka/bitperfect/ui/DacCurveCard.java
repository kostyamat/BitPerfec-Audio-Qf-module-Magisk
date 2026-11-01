package com.radiorubka.bitperfect.ui;

import android.app.Activity;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.TextView;

import com.google.android.material.button.MaterialButton;
import com.radiorubka.bitperfect.R;
import com.radiorubka.bitperfect.core.ModuleControl;
import com.radiorubka.bitperfect.ui.theme.ToggleStyler;
import com.radiorubka.bitperfect.ui.theme.TouchGlow;

import java.util.Locale;
import java.util.concurrent.ExecutorService;

/**
 * Where each position of the head unit's knob lands on this DAC's own volume scale. Every DAC has its own steps and
 * its own feel (owner 02.11: «у мене початок не чутливий, у гось таке буде в кінці. А в когось лінія»), so the module
 * keeps a curve per DAC model ({@code bp_ctl.sh usb_curve}, common/bp_usbvol.sh). A change applies at once, nothing
 * restarts, so the person can tune it by ear with music on; a slider is sent when it is let go.
 */
public final class DacCurveCard {

    private static final int[] KNOB = {1, 8, 16, 24, 32};
    private static final String EVEN_STEPS = "3,25,50,75,100";

    private final Activity act;
    private final ExecutorService io;
    private final View panel;
    private final TextView tvNow;
    private final MaterialButton btnDefault, btnEven;
    private final TextView[] tvPoint = new TextView[KNOB.length];
    private final SeekBar[] sb = new SeekBar[KNOB.length];
    private final Runnable changed;
    private int dbMin, dbMax;
    private boolean hasDb, dragging;

    public DacCurveCard(Activity act, ExecutorService io, Runnable changed) {
        this.act = act;
        this.io = io;
        this.changed = changed;
        panel = act.findViewById(R.id.panel_dac_curve);
        tvNow = act.findViewById(R.id.tv_dac_curve_now);
        btnDefault = act.findViewById(R.id.btn_dac_curve_default);
        btnEven = act.findViewById(R.id.btn_dac_curve_even);
        btnDefault.setOnClickListener(v -> send("default"));
        btnEven.setOnClickListener(v -> send(EVEN_STEPS));
        TouchGlow.attach(btnDefault);
        TouchGlow.attach(btnEven);
        LinearLayout rows = act.findViewById(R.id.dac_curve_rows);
        for (int i = 0; i < KNOB.length; i++) {
            final int at = i;
            tvPoint[i] = new TextView(act, null, 0, R.style.BpCardNote);
            rows.addView(tvPoint[i]);
            sb[i] = new SeekBar(act);
            sb[i].setMax(100);
            rows.addView(sb[i]);
            sb[i].setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
                @Override
                public void onProgressChanged(SeekBar s, int p, boolean fromUser) {
                    if (fromUser) keepRising(at);
                    label();
                }

                @Override
                public void onStartTrackingTouch(SeekBar s) {
                    dragging = true;
                }

                @Override
                public void onStopTrackingTouch(SeekBar s) {
                    dragging = false;
                    StringBuilder c = new StringBuilder();
                    for (int j = 0; j < sb.length; j++) c.append(j == 0 ? "" : ",").append(sb[j].getProgress());
                    send(c.toString());
                }
            });
        }
    }

    /** From each status: {@code show} = the DAC is followed and has its own control. */
    public void update(ModuleControl.Result r, boolean show) {
        panel.setVisibility(show ? View.VISIBLE : View.GONE);
        if (!show || dragging) return;
        String[] db = r.get("usb_dac_db").trim().split("\\s+");
        hasDb = db.length == 2;
        if (hasDb) {
            dbMin = Integer.parseInt(db[0]);
            dbMax = Integer.parseInt(db[1]);
        }
        String[] c = r.get("usb_curve").trim().split("\\s+");
        if (c.length == KNOB.length) {
            for (int i = 0; i < KNOB.length; i++) sb[i].setProgress(Integer.parseInt(c[i]));
        }
        label();
        String[] now = r.get("usb_dac_level").trim().split("\\s+");
        tvNow.setText(now.length == 3 ? act.getString(R.string.dac_curve_now, now[0], now[1], now[2]) : "");
    }

    public void applyTheme() {
        ToggleStyler.apply(btnDefault);
        ToggleStyler.apply(btnEven);
    }

    /** A curve never falls: a slider pushes its neighbours along. */
    private void keepRising(int at) {
        int v = sb[at].getProgress();
        for (int i = at + 1; i < sb.length; i++) if (sb[i].getProgress() < v) sb[i].setProgress(v);
        for (int i = at - 1; i >= 0; i--) if (sb[i].getProgress() > v) sb[i].setProgress(v);
    }

    private void label() {
        for (int i = 0; i < KNOB.length; i++) {
            int p = sb[i].getProgress();
            String text = act.getString(R.string.dac_curve_point, KNOB[i], p);
            if (hasDb) {
                double db = (dbMin + (dbMax - dbMin) * p / 100.0) / 100.0;
                text += act.getString(R.string.dac_curve_db, String.format(Locale.US, "%.0f", db));
            }
            tvPoint[i].setText(text);
        }
    }

    private void send(String curve) {
        io.execute(() -> {
            ModuleControl.Result r = ModuleControl.setUsbCurve(curve);
            act.runOnUiThread(changed);
        });
    }
}
