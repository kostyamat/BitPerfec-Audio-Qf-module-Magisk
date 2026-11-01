package com.radiorubka.bitperfect.ui;

import android.app.Activity;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.view.View;
import android.widget.TextView;

import com.google.android.material.button.MaterialButton;
import com.radiorubka.bitperfect.R;
import com.radiorubka.bitperfect.ui.theme.ToggleStyler;
import com.radiorubka.bitperfect.ui.theme.TouchGlow;

/**
 * Shown when the module cannot be reached: says why and what to do, and asks for root again only on the button.
 * The Magisk app decides most of it (owner 02.11.2026): 30.6 works; 27 may not install the module completely;
 * 31.1 and later give apps no root on a kernel patched with Magisk 27.
 */
public final class RootCard {

    private static final String MAGISK = "com.topjohnwu.magisk";
    private static final long MAGISK_GOOD = 30600;

    private final Activity act;
    private final View card;
    private final TextView tvHelp;
    private final MaterialButton btnRetry;

    public RootCard(Activity act, Runnable retry) {
        this.act = act;
        card = act.findViewById(R.id.card_root);
        tvHelp = act.findViewById(R.id.tv_root_help);
        btnRetry = act.findViewById(R.id.btn_root_retry);
        btnRetry.setOnClickListener(v -> retry.run());
        TouchGlow.attach(btnRetry);
    }

    public void hide() {
        card.setVisibility(View.GONE);
    }

    /** {@code error}: no_root, no_module or timeout, from ModuleControl. */
    public void show(String error) {
        if ("no_root".equals(error)) {
            tvHelp.setText(act.getString(R.string.root_help) + "\n\n" + magiskAdvice());
        } else if ("no_module".equals(error)) {
            tvHelp.setText(R.string.root_no_module_help);
        } else {
            tvHelp.setText(R.string.root_no_answer_help);
        }
        card.setVisibility(View.VISIBLE);
    }

    public void applyTheme() {
        ToggleStyler.apply(btnRetry);
    }

    private String magiskAdvice() {
        try {
            PackageInfo p = act.getPackageManager().getPackageInfo(MAGISK, 0);
            long code = p.getLongVersionCode();
            int text = code == MAGISK_GOOD ? R.string.root_magisk_good
                    : code > MAGISK_GOOD ? R.string.root_magisk_new : R.string.root_magisk_old;
            return act.getString(text, p.versionName);
        } catch (PackageManager.NameNotFoundException e) {
            return act.getString(R.string.root_magisk_unknown); // not installed, or hidden under another name
        }
    }
}
