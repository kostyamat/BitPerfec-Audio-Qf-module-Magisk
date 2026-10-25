package com.radiorubka.bitperfect.ui;

import android.app.Dialog;
import android.content.ActivityNotFoundException;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.net.Uri;
import android.util.DisplayMetrics;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ScrollView;
import android.widget.Toast;

import com.radiorubka.bitperfect.R;

/**
 * The developer-support dialog of the automotive-support-badge standard (golden master: QF_NetworkBurst
 * {@code MainActivity.showSupportDialog}), as a helper instead of a block inside the activity.
 * The Telegram card points at the BitPerfect support group.
 */
public final class SupportDialog {

    private static final String TG_GROUP = "https://t.me/kostyamat_dev/3";

    private SupportDialog() {
    }

    public static Dialog show(Context ctx) {
        final Dialog dialog = new Dialog(ctx);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.setContentView(R.layout.dialog_support);
        dialog.setCancelable(true);
        dialog.setCanceledOnTouchOutside(true);

        Window window = dialog.getWindow();
        if (window != null) {
            window.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
            window.setGravity(Gravity.CENTER);
            DisplayMetrics dm = ctx.getResources().getDisplayMetrics();
            int width = Math.min((int) (dm.widthPixels * 0.90f), (int) (520 * dm.density));
            window.setLayout(width, WindowManager.LayoutParams.WRAP_CONTENT);
            final ScrollView scroll = dialog.findViewById(R.id.scroll_support_items);
            // header (~70dp) + close button (~52dp) + padding (36dp) stay outside the scroll
            final int maxScroll = (int) (dm.heightPixels * 0.88f) - (int) (158 * dm.density);
            if (scroll != null && maxScroll > 80) {
                scroll.getViewTreeObserver().addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
                    @Override
                    public void onGlobalLayout() {
                        scroll.getViewTreeObserver().removeOnGlobalLayoutListener(this);
                        if (scroll.getHeight() > maxScroll) {
                            ViewGroup.LayoutParams lp = scroll.getLayoutParams();
                            lp.height = maxScroll;
                            scroll.setLayoutParams(lp);
                        }
                    }
                });
            }
        }

        bind(dialog, R.id.card_support_paypal, "https://www.paypal.com/paypalme/kostyamat",
                "https://www.paypal.com/paypalme/kostyamat", null);
        bind(dialog, R.id.card_support_revolut, "https://revolut.me/kostyamat",
                "https://revolut.me/kostyamat", null);
        bind(dialog, R.id.card_support_ton, "UQCqracCOo_DEwVWQjPVYkKak-gSZx1TXQOxICi_9frpdr5j",
                "ton://transfer/UQCqracCOo_DEwVWQjPVYkKak-gSZx1TXQOxICi_9frpdr5j",
                "https://tonviewer.com/UQCqracCOo_DEwVWQjPVYkKak-gSZx1TXQOxICi_9frpdr5j");
        bind(dialog, R.id.card_support_tron, "TCSvCEyX1Zxb9E97oTpxHsBCLiDZLPTvzk",
                "tron:TCSvCEyX1Zxb9E97oTpxHsBCLiDZLPTvzk",
                "https://tronscan.org/#/address/TCSvCEyX1Zxb9E97oTpxHsBCLiDZLPTvzk");
        bind(dialog, R.id.card_support_tg_post, TG_GROUP, "tg://resolve?domain=kostyamat_dev&post=3", TG_GROUP);

        View close = dialog.findViewById(R.id.btn_dialog_close);
        if (close != null) close.setOnClickListener(v -> dialog.dismiss());
        dialog.show();
        return dialog;
    }

    private static void bind(Dialog dialog, int id, String copy, String primary, String fallback) {
        View card = dialog.findViewById(id);
        if (card == null) return;
        card.setOnClickListener(v -> open(v.getContext(), copy, primary, fallback));
    }

    /** Copy to the clipboard, then open the target, with a web fallback when no app handles it. */
    private static void open(Context ctx, String copy, String primary, String fallback) {
        try {
            ClipboardManager cm = (ClipboardManager) ctx.getSystemService(Context.CLIPBOARD_SERVICE);
            if (cm != null) cm.setPrimaryClip(ClipData.newPlainText("BitPerfect_Support", copy));
            Toast.makeText(ctx, ctx.getString(R.string.toast_copied, copy), Toast.LENGTH_SHORT).show();
        } catch (Throwable ignored) {
        }
        try {
            ctx.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(primary)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
        } catch (ActivityNotFoundException e) {
            if (fallback != null) {
                try {
                    ctx.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(fallback)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
                } catch (Throwable ignored) {
                }
            }
        } catch (Throwable ignored) {
        }
    }
}
