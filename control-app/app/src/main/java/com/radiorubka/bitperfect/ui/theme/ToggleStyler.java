package com.radiorubka.bitperfect.ui.theme;

import android.content.Context;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.CompoundButton;
import android.widget.ToggleButton;

import androidx.core.graphics.ColorUtils;

import com.google.android.material.button.MaterialButton;

/**
 * Checked / unchecked look of every toggle-like control, in one place.
 *
 * In wDSP this lived as {@code MainActivity.updateToggleStyle}, so {@link TouchGlow} had to find the
 * activity to restore a toggle after a touch. Here it is a helper of the theme, and both the screens and
 * TouchGlow call it directly.
 */
public final class ToggleStyler {

    private ToggleStyler() {
    }

    public static void apply(View v) {
        if (v == null) return;
        Context ctx = v.getContext();
        boolean night = ThemeManager.isNight(ctx);
        int accent = ThemeManager.accent(ctx, night);
        int onAccent = ThemeManager.onAccent(ctx, night);
        int textPrimary = ThemeManager.textPrimary(ctx, night);
        int border = ThemeManager.panelBorder(ctx, night);
        int substrate = ThemeManager.dockSubstrateColor(ctx, night);
        float density = ctx.getResources().getDisplayMetrics().density;

        if (v instanceof MaterialButton) {
            MaterialButton mb = (MaterialButton) v;
            boolean checked = mb.isChecked();
            if (ThemeManager.isClassic(ctx)) {
                int uncheckedBg = night ? Color.parseColor("#1F33373B") : Color.parseColor("#15000000");
                int uncheckedBorder = night ? Color.parseColor("#44FFFFFF") : Color.parseColor("#33000000");
                mb.setBackgroundTintList(ColorStateList.valueOf(checked ? accent : uncheckedBg));
                mb.setStrokeColor(ColorStateList.valueOf(checked ? accent : uncheckedBorder));
                mb.setStrokeWidth(Math.max(1, (int) (1.2f * density)));
                mb.setCornerRadius((int) (10 * density));
                mb.setRippleColor(ColorStateList.valueOf(ColorUtils.setAlphaComponent(accent, 40)));
            } else {
                mb.setBackgroundTintList(null);
                mb.setStrokeWidth(0);
                mb.setRippleColor(null);
                mb.setBackground(ThemeManager.pillDrawable(ctx, checked, night, 14f, accent, border));
            }
            setText(mb, checked, onAccent, textPrimary, substrate);
            mb.setAlpha(mb.isEnabled() ? 1.0f : 0.45f);
            return;
        }
        if (v instanceof ToggleButton) {
            ToggleButton tb = (ToggleButton) v;
            boolean checked = tb.isChecked();
            tb.setBackground(ThemeManager.pillDrawable(ctx, checked, night, 10f, accent, border));
            setText(tb, checked, onAccent, textPrimary, substrate);
            return;
        }
        if (v instanceof CompoundButton) {
            CompoundButton cb = (CompoundButton) v;
            boolean checked = cb.isChecked();
            cb.setPadding((int) (14 * density), (int) (6 * density), (int) (14 * density), (int) (6 * density));
            cb.setGravity(Gravity.CENTER);
            cb.setBackground(ThemeManager.pillDrawable(ctx, checked, night, 14f, accent, border));
            setText(cb, checked, onAccent, textPrimary, substrate);
        }
    }

    private static void setText(android.widget.TextView tv, boolean checked, int onAccent, int textPrimary,
                                int substrate) {
        int fg = checked ? onAccent : ThemeManager.contrastText(textPrimary, substrate);
        tv.setTextColor(fg);
        tv.setTypeface(null, Typeface.BOLD);
        tv.getPaint().setFakeBoldText(true);
    }
}
