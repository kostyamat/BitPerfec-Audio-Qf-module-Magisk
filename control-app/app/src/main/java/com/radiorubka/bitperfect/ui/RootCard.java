package com.radiorubka.bitperfect.ui;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.view.View;
import android.widget.TextView;

import com.google.android.material.button.MaterialButton;
import com.radiorubka.bitperfect.R;
import com.radiorubka.bitperfect.ui.theme.ToggleStyler;
import com.radiorubka.bitperfect.ui.theme.TouchGlow;

/**
 * Shown when the module cannot be reached: says why and what to do. A refusal is remembered by Magisk, so asking again
 * changes nothing: the button opens Magisk on the right screen (owner 02.11), and root is asked again on the way back.
 * "Try again" stays only where it can help: the module did not answer, or the Magisk app cannot be found.
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
    private final Runnable retry;
    private String magiskSection; // null = the button tries again
    private boolean wentToMagisk;

    public RootCard(Activity act, Runnable retry) {
        this.act = act;
        this.retry = retry;
        card = act.findViewById(R.id.card_root);
        tvHelp = act.findViewById(R.id.tv_root_help);
        btnRetry = act.findViewById(R.id.btn_root_retry);
        btnRetry.setOnClickListener(v -> press());
        TouchGlow.attach(btnRetry);
    }

    public void hide() {
        card.setVisibility(View.GONE);
    }

    /** {@code error}: no_root, no_module or timeout, from ModuleControl. */
    public void show(String error) {
        magiskSection = null;
        if ("no_root".equals(error)) {
            tvHelp.setText(act.getString(R.string.root_help) + "\n\n" + magiskAdvice());
            magiskSection = "superuser";
        } else if ("no_module".equals(error)) {
            tvHelp.setText(R.string.root_no_module_help);
            magiskSection = "modules";
        } else {
            tvHelp.setText(R.string.root_no_answer_help);
        }
        if (magiskIntent() == null) magiskSection = null;
        btnRetry.setText(magiskSection != null ? R.string.root_open_magisk : R.string.root_retry);
        card.setVisibility(View.VISIBLE);
    }

    /** Back from Magisk, sent there by the button: the person may have just allowed it. */
    public void onResume() {
        if (wentToMagisk) {
            wentToMagisk = false;
            retry.run();
        }
    }

    private void press() {
        Intent open = magiskSection == null ? null : magiskIntent();
        if (open == null) {
            retry.run();
            return;
        }
        // 📻 Magisk 30.6 opens on that screen: extra "section" = superuser | modules (stand 194, 02.11)
        open.putExtra("section", magiskSection);
        wentToMagisk = true;
        act.startActivity(open);
    }

    private Intent magiskIntent() {
        return act.getPackageManager().getLaunchIntentForPackage(MAGISK);
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
