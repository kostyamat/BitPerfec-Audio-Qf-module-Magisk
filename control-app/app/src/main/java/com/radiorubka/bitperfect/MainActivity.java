package com.radiorubka.bitperfect;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.google.android.material.button.MaterialButton;
import com.radiorubka.bitperfect.core.ModuleControl;
import com.radiorubka.bitperfect.ui.ShimmerBadgeLayout;
import com.radiorubka.bitperfect.ui.SupportDialog;
import com.radiorubka.bitperfect.ui.theme.ThemeManager;
import com.radiorubka.bitperfect.ui.theme.ToggleStyler;
import com.radiorubka.bitperfect.ui.theme.TouchGlow;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * The one screen of v1: what the unit is and what BitPerfect does on it, the USB DAC switch, the style.
 * Every action goes to the module through {@link ModuleControl}; this class only shows and asks.
 */
public class MainActivity extends Activity {

    private final ExecutorService io = Executors.newSingleThreadExecutor();
    private final Handler ui = new Handler(Looper.getMainLooper());

    private TextView tvPlatform, tvPlatformNote, tvPath, tvPathNote, tvModule, tvModuleNote, tvUsbResult, tvThemeNote;
    private MaterialButton btnUsbOff, btnUsbOn, btnModern, btnHyper, btnAuto, btnDay, btnNight, btnRefresh;
    private boolean usbWanted;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        tvPlatform = findViewById(R.id.tv_platform);
        tvPlatformNote = findViewById(R.id.tv_platform_note);
        tvPath = findViewById(R.id.tv_path);
        tvPathNote = findViewById(R.id.tv_path_note);
        tvModule = findViewById(R.id.tv_module);
        tvModuleNote = findViewById(R.id.tv_module_note);
        tvUsbResult = findViewById(R.id.tv_usb_result);
        tvThemeNote = findViewById(R.id.tv_theme_note);
        btnUsbOff = findViewById(R.id.btn_usb_off);
        btnUsbOn = findViewById(R.id.btn_usb_on);
        btnModern = findViewById(R.id.btn_style_modern);
        btnHyper = findViewById(R.id.btn_style_hyper);
        btnAuto = findViewById(R.id.btn_mode_auto);
        btnDay = findViewById(R.id.btn_mode_day);
        btnNight = findViewById(R.id.btn_mode_night);
        btnRefresh = findViewById(R.id.btn_refresh);

        btnUsbOff.setOnClickListener(v -> applyUsb(false));
        btnUsbOn.setOnClickListener(v -> applyUsb(true));
        btnModern.setOnClickListener(v -> setStyle(ThemeManager.UI_STYLE_MODERN));
        btnHyper.setOnClickListener(v -> setStyle(ThemeManager.UI_STYLE_HYPER));
        btnAuto.setOnClickListener(v -> setMode(ThemeManager.THEME_MODE_AUTO));
        btnDay.setOnClickListener(v -> setMode(ThemeManager.THEME_MODE_DAY));
        btnNight.setOnClickListener(v -> setMode(ThemeManager.THEME_MODE_NIGHT));
        btnRefresh.setOnClickListener(v -> refresh());
        View badge = findViewById(R.id.btn_donate_badge);
        badge.setOnClickListener(v -> SupportDialog.show(this));

        for (View v : new View[]{btnUsbOff, btnUsbOn, btnModern, btnHyper, btnAuto, btnDay, btnNight, btnRefresh}) {
            TouchGlow.attach(v);
        }
        applyTheme();
        refresh();
    }

    @Override
    protected void onDestroy() {
        io.shutdownNow();
        super.onDestroy();
    }

    // ---------------------------------------------------------------- state

    private void refresh() {
        tvPlatform.setText(R.string.status_loading);
        io.execute(() -> {
            ModuleControl.Result r = ModuleControl.status();
            ui.post(() -> show(r));
        });
    }

    private void show(ModuleControl.Result r) {
        if (!r.ok()) {
            tvPlatform.setText(R.string.status_no_root);
            tvPlatformNote.setText(r.error);
            tvPath.setText("");
            tvModule.setText("");
            return;
        }
        String platform = r.get("platform");
        boolean is7862 = "ums512".equals(platform);
        boolean is8581 = "sp9863a".equals(platform);
        tvPlatform.setText(is7862 ? getString(R.string.platform_7862)
                : is8581 ? getString(R.string.platform_8581) : getString(R.string.platform_other, platform));
        tvPlatformNote.setText(r.get("mcu"));

        if (is8581) {
            tvPath.setText(R.string.path_8581);
        } else {
            tvPath.setText(r.get("i2s_width").contains(">WD_24BIT") || "true".equals(r.get("i2s"))
                    ? R.string.path_i2s_24 : R.string.path_analogue);
        }
        String playing = r.get("playing");
        tvPathNote.setText(playing.isEmpty() ? getString(R.string.path_idle)
                : getString(R.string.path_playing, playing.replace("/proc/asound/", "")));

        String version = r.get("module_version");
        if ("1".equals(r.get("module_disabled"))) {
            tvModule.setText(R.string.module_disabled);
        } else if ("1".equals(r.get("enabled"))) {
            tvModule.setText(getString(R.string.module_active, version));
        } else {
            tvModule.setText(getString(R.string.module_inactive, version));
        }
        tvModuleNote.setText("1".equals(r.get("nav_policy")) ? R.string.module_nav_policy_on : R.string.module_nav_policy_off);

        usbWanted = "1".equals(r.get("usb_wanted"));
        styleChoices();
    }

    // ---------------------------------------------------------------- actions

    private void applyUsb(boolean on) {
        usbWanted = on;
        styleChoices();
        tvUsbResult.setText(R.string.status_loading);
        io.execute(() -> {
            ModuleControl.Result r = ModuleControl.setUsbDac(on);
            ui.post(() -> {
                String res = r.get("usb_result");
                if (!r.ok()) tvUsbResult.setText(getString(R.string.usb_result_error, r.error));
                else if ("changed".equals(res)) tvUsbResult.setText(R.string.usb_result_changed);
                else if ("same".equals(res)) tvUsbResult.setText(R.string.usb_result_same);
                else if ("unsupported".equals(res)) tvUsbResult.setText(R.string.usb_result_unsupported);
                else tvUsbResult.setText(getString(R.string.usb_result_error, res));
                refresh();
            });
        });
    }

    private void setStyle(int style) {
        ThemeManager.setUiStyle(this, style);
        applyTheme();
    }

    private void setMode(int mode) {
        if (ThemeManager.isHyper(this)) {
            styleChoices();
            return; // Hyper is night-only; the mode stays for when Modern comes back
        }
        ThemeManager.setThemeMode(this, mode);
        applyTheme();
    }

    // ---------------------------------------------------------------- theme

    private void applyTheme() {
        boolean night = ThemeManager.isNight(this);
        View root = findViewById(R.id.root_scroll);
        root.setBackground(ThemeManager.wallpaperBackground(this, night));
        getWindow().setStatusBarColor(ThemeManager.background(this, night));
        for (int id : new int[]{R.id.card_platform, R.id.card_path, R.id.card_module, R.id.card_usb, R.id.card_theme}) {
            findViewById(id).setBackground(ThemeManager.cardDrawable(this, night, 16f));
        }
        int primary = ThemeManager.textPrimary(this, night);
        int secondary = ThemeManager.textSecondary(this, night);
        int card = ThemeManager.cardBackground(this, night);
        ((TextView) findViewById(R.id.tv_title)).setTextColor(ThemeManager.contrastText(primary, ThemeManager.background(this, night)));
        tintTexts((ViewGroup) findViewById(R.id.content), primary, secondary, card);
        styleChoices();
    }

    /** Titles and values in the primary colour, notes in the secondary - each checked against the card. */
    private void tintTexts(ViewGroup group, int primary, int secondary, int card) {
        for (int i = 0; i < group.getChildCount(); i++) {
            View v = group.getChildAt(i);
            if (v instanceof ShimmerBadgeLayout || v instanceof MaterialButton) continue;
            if (v instanceof ViewGroup) {
                tintTexts((ViewGroup) v, primary, secondary, card);
            } else if (v instanceof TextView && v.getId() != R.id.tv_title) {
                TextView tv = (TextView) v;
                boolean note = tv.getTextSize() < getResources().getDimension(R.dimen.text_size_label);
                tv.setTextColor(ThemeManager.contrastText(note ? secondary : primary, card));
            }
        }
    }

    private void styleChoices() {
        boolean hyper = ThemeManager.isHyper(this);
        int mode = ThemeManager.getThemeMode(this);
        for (MaterialButton b : new MaterialButton[]{btnAuto, btnDay, btnNight}) b.setEnabled(!hyper);
        check(btnUsbOff, !usbWanted);
        check(btnUsbOn, usbWanted);
        check(btnModern, !hyper);
        check(btnHyper, hyper);
        check(btnAuto, !hyper && mode == ThemeManager.THEME_MODE_AUTO);
        check(btnDay, !hyper && mode == ThemeManager.THEME_MODE_DAY);
        check(btnNight, hyper || mode == ThemeManager.THEME_MODE_NIGHT);
        tvThemeNote.setText(hyper ? getString(R.string.hyper_night_only) : "");
        ToggleStyler.apply(btnRefresh);
    }

    private static void check(MaterialButton b, boolean on) {
        b.setChecked(on);
        ToggleStyler.apply(b);
    }
}
