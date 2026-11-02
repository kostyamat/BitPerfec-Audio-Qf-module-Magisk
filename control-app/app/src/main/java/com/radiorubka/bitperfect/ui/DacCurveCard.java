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
 * restarts, so the person can tune it by ear with music on; a slider is sent when it is let go. Moving one point
 * stretches the points to its right like rubber; those to its left stay, so a curve is built from left to right, and
 * two points never share a level (owner 02.11).
 */
public final class DacCurveCard {

    private static final int[] KNOB = {1, 8, 16, 24, 32};

    private final Activity act;
    private final ExecutorService io;
    private final View panel;
    private final TextView tvNow;
    private final MaterialButton btnDefault;
    private final TextView[] tvPoint = new TextView[KNOB.length];
    private final SeekBar[] sb = new SeekBar[KNOB.length];
    private final Runnable changed;
    private static final int SCALE = 1000; // a slider holds tenths of a percent
    private final int[] atStart = new int[KNOB.length];
    private int top = 100;
    private boolean dragging;

    public DacCurveCard(Activity act, ExecutorService io, Runnable changed) {
        this.act = act;
        this.io = io;
        this.changed = changed;
        panel = act.findViewById(R.id.panel_dac_curve);
        tvNow = act.findViewById(R.id.tv_dac_curve_now);
        btnDefault = act.findViewById(R.id.btn_dac_curve_default);
        btnDefault.setOnClickListener(v -> send("default"));
        TouchGlow.attach(btnDefault);
        LinearLayout rows = act.findViewById(R.id.dac_curve_rows);
        for (int i = 0; i < KNOB.length; i++) {
            final int at = i;
            tvPoint[i] = new TextView(act, null, 0, R.style.BpCardNote);
            rows.addView(tvPoint[i]);
            sb[i] = new SeekBar(act);
            sb[i].setMax(SCALE);
            rows.addView(sb[i]);
            sb[i].setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
                @Override
                public void onProgressChanged(SeekBar s, int p, boolean fromUser) {
                    if (fromUser && dragging) carry(at, p);
                    label();
                }

                @Override
                public void onStartTrackingTouch(SeekBar s) {
                    dragging = true;
                    for (int j = 0; j < sb.length; j++) atStart[j] = sb[j].getProgress();
                }

                @Override
                public void onStopTrackingTouch(SeekBar s) {
                    dragging = false;
                    StringBuilder c = new StringBuilder();
                    for (int j = 0; j < sb.length; j++) c.append(j == 0 ? "" : ",").append(percent(sb[j].getProgress()));
                    send(c.toString());
                }
            });
        }
    }

    /** From each status: {@code show} = the DAC is followed and has its own control. */
    public void update(ModuleControl.Result r, boolean show) {
        panel.setVisibility(show ? View.VISIBLE : View.GONE);
        if (!show || dragging) return;
        String[] c = r.get("usb_curve").trim().split("\\s+");
        if (c.length == KNOB.length) {
            for (int i = 0; i < KNOB.length; i++) sb[i].setProgress(Math.round(Float.parseFloat(c[i]) * SCALE / 100));
        }
        label();
        String[] now = r.get("usb_dac_level").trim().split("\\s+");
        tvNow.setText(now.length == 3 ? act.getString(R.string.dac_curve_now, now[0], now[1], now[2]) : "");
        if (now.length == 3) top = Math.max(1, Integer.parseInt(now[2]));
    }

    public void applyTheme() {
        ToggleStyler.apply(btnDefault);
    }

    /**
     * Point {@code at} dragged to {@code to}, measured from where all stood when the finger came down: the points to its
     * right stretch or squeeze between it and the last point, the last stays unless it is the one dragged. The points to
     * its left stay, and give way only when pushed. Neighbours stay at least one step of this DAC apart.
     */
    private void carry(int at, int to) {
        int n = sb.length, last = n - 1;
        int gap = Math.max(SCALE / top + 1, 5);
        int end = atStart[last];
        int lo = at * gap;
        int hi = at == last ? SCALE : end - (last - at) * gap;
        int p = Math.max(lo, Math.min(hi, to));
        int[] v = new int[n];
        for (int i = 0; i < n; i++) {
            if (i <= at) v[i] = i == at ? p : atStart[i];
            else v[i] = p + Math.round((atStart[i] - atStart[at]) * (float) (end - p) / (end - atStart[at]));
        }
        for (int i = at + 1; i < n; i++) v[i] = Math.max(v[i], v[i - 1] + gap);
        for (int i = at - 1; i >= 0; i--) v[i] = Math.min(v[i], v[i + 1] - gap);
        for (int i = 0; i < n; i++) sb[i].setProgress(v[i]);
    }

    private static String percent(int progress) {
        return String.format(Locale.US, "%.1f", progress * 100f / SCALE);
    }

    private void label() {
        for (int i = 0; i < KNOB.length; i++) {
            tvPoint[i].setText(act.getString(R.string.dac_curve_point, KNOB[i], percent(sb[i].getProgress())));
        }
    }

    private void send(String curve) {
        io.execute(() -> {
            ModuleControl.Result r = ModuleControl.setUsbCurve(curve);
            act.runOnUiThread(changed);
        });
    }
}
