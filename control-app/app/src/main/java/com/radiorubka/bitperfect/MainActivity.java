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
import com.radiorubka.bitperfect.ui.DacCurveCard;
import com.radiorubka.bitperfect.ui.MicCard;
import com.radiorubka.bitperfect.ui.NavigatorsCard;
import com.radiorubka.bitperfect.ui.RootCard;
import com.radiorubka.bitperfect.ui.ShimmerBadgeLayout;
import com.radiorubka.bitperfect.ui.ThemedDialog;
import com.radiorubka.bitperfect.ui.SupportDialog;
import com.radiorubka.bitperfect.ui.theme.ThemeManager;
import com.radiorubka.bitperfect.ui.theme.ToggleStyler;
import com.radiorubka.bitperfect.ui.theme.TouchGlow;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

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
    private NavigatorsCard navi;
    private MicCard mic;
    private RootCard rootCard;
    private DacCurveCard dacCurve;
    private final AtomicBoolean polling = new AtomicBoolean();

    // One section open at a time, picked from the tabs under the status cards (remembered between starts).
    private static final int[] TAB_IDS = {R.id.tab_usb, R.id.tab_mic, R.id.tab_navi, R.id.tab_theme};
    private static final int[] SECTION_IDS = {R.id.card_usb, R.id.card_mic, R.id.card_navi, R.id.card_theme};
    private final MaterialButton[] tabs = new MaterialButton[TAB_IDS.length];

    /** Without the module nothing below the status is known: a switch would show a state it never read. */
    private void showSections(boolean on) {
        View row = findViewById(R.id.row_tabs);
        if (on == (row.getVisibility() == View.VISIBLE)) return;
        row.setVisibility(on ? View.VISIBLE : View.GONE);
        if (on) {
            showSection(getPreferences(MODE_PRIVATE).getInt("section", 0));
        } else {
            for (int id : SECTION_IDS) findViewById(id).setVisibility(View.GONE);
        }
    }

    private void showSection(int s) {
        if (s < 0 || s >= SECTION_IDS.length) s = 0;
        for (int i = 0; i < SECTION_IDS.length; i++) {
            findViewById(SECTION_IDS[i]).setVisibility(i == s ? View.VISIBLE : View.GONE);
            check(tabs[i], i == s);
        }
        getPreferences(MODE_PRIVATE).edit().putInt("section", s).apply();
    }
    private TextView tvUsbDac;
    private MaterialButton btnUsbMode, btnUsbVolume;
    private String usbMode = "auto";
    private final List<String> usbModes = new ArrayList<>();

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
        tvUsbDac = findViewById(R.id.tv_usb_dac);
        btnUsbMode = findViewById(R.id.btn_usb_mode);
        btnUsbMode.setText(getString(R.string.usb_mode_btn, getString(R.string.usb_mode_auto)));
        btnUsbMode.setOnClickListener(v -> pickUsbMode());
        TouchGlow.attach(btnUsbMode);
        btnUsbVolume = findViewById(R.id.btn_usb_volume);
        btnUsbVolume.setOnClickListener(v -> applyUsbVolume(btnUsbVolume.isChecked()));
        TouchGlow.attach(btnUsbVolume);

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
        for (int i = 0; i < TAB_IDS.length; i++) {
            final int s = i;
            tabs[i] = findViewById(TAB_IDS[i]);
            tabs[i].setOnClickListener(v -> showSection(s));
            TouchGlow.attach(tabs[i]);
        }
        navi = new NavigatorsCard(this, io);
        mic = new MicCard(this, io);
        dacCurve = new DacCurveCard(this, io, () -> refresh(true));
        rootCard = new RootCard(this, () -> {
            ModuleControl.retryRoot();
            refresh();
            navi.load();
            mic.load();
        });
        showSection(getPreferences(MODE_PRIVATE).getInt("section", 0));
        applyTheme();
        refresh();
        navi.load();
        mic.load();
    }

    @Override
    protected void onDestroy() {
        io.shutdownNow();
        super.onDestroy();
    }

    // ---------------------------------------------------------------- state

    // While the screen is visible the state follows the unit by itself (one root shell, no prompt per poll).
    private static final long POLL_MS = 3000;
    private final Runnable poll = new Runnable() {
        @Override
        public void run() {
            refresh(true);
            ui.postDelayed(this, POLL_MS);
        }
    };

    @Override
    protected void onResume() {
        super.onResume();
        rootCard.onResume();
        ui.postDelayed(poll, POLL_MS);
    }

    @Override
    protected void onPause() {
        ui.removeCallbacks(poll);
        super.onPause();
    }

    private void refresh() {
        refresh(false);
    }

    private void refresh(boolean quiet) {
        // the poll waits for its previous turn: a Magisk prompt can hold the shell for a minute
        if (quiet && !polling.compareAndSet(false, true)) return;
        if (!quiet) tvPlatform.setText(R.string.status_loading);
        io.execute(() -> {
            ModuleControl.Result r = ModuleControl.status();
            if (quiet) polling.set(false);
            ui.post(() -> show(r));
        });
    }

    /** "usb card1/pcm0p S16_LE 2 48000" -> {kind, "16-bit / 48 kHz, stereo"}; null when unreadable. */
    private String[] describePlaying(String line) {
        String[] f = line.trim().split("\\s+");
        if (f.length < 5) return null;
        String bits = f[2].replaceAll("^[SU](\\d+).*$", "$1");
        int rate;
        try {
            rate = Integer.parseInt(f[4]);
        } catch (NumberFormatException e) {
            return null;
        }
        String khz = rate % 1000 == 0 ? String.valueOf(rate / 1000) : String.valueOf(rate / 1000.0);
        String ch = "2".equals(f[3]) ? getString(R.string.ch_stereo) : "1".equals(f[3]) ? getString(R.string.ch_mono)
                : getString(R.string.ch_n, f[3]);
        return new String[]{f[0], getString(R.string.fmt_desc, bits, khz, ch)};
    }

    private void show(ModuleControl.Result r) {
        if (!r.ok()) {
            tvPlatform.setText("no_root".equals(r.error) ? R.string.status_root_none
                    : "no_module".equals(r.error) ? R.string.status_no_module : R.string.status_no_answer);
            // red, readable on both the night and the day card
            tvPlatform.setTextColor(ThemeManager.isNight(this) ? ThemeManager.HYPER_RED : 0xFFC62828);
            tvPlatformNote.setText("");
            rootCard.show(r.error);
            showSections(false);
            tvPath.setText("");
            tvModule.setText("");
            return;
        }
        rootCard.hide();
        showSections(true);
        boolean night = ThemeManager.isNight(this);
        tvPlatform.setTextColor(ThemeManager.contrastText(ThemeManager.textPrimary(this, night), ThemeManager.cardBackground(this, night)));
        String platform = r.get("platform");
        boolean is7862 = "ums512".equals(platform);
        boolean is8581 = "sp9863a".equals(platform);
        tvPlatform.setText(is7862 ? getString(R.string.platform_7862)
                : is8581 ? getString(R.string.platform_8581) : getString(R.string.platform_other, platform));
        tvPlatformNote.setText(r.get("mcu"));

        // The title is what really plays now (USB first: when the DAC plays, that is where the sound goes);
        // idle, it is the path the unit is set up for.
        String[] usb = null, internal = null;
        // card=<cardN> <usb|internal> <usbid|-> <name>: each card as it names itself
        Map<String, String> cardNames = new HashMap<>();
        String usbName = null, usbId = null;
        for (String line : r.get("card").split("\n")) {
            String[] f = line.trim().split("\\s+", 4);
            if (f.length < 4) continue;
            boolean isUsb = "usb".equals(f[1]);
            cardNames.put(f[0], isUsb ? getString(R.string.card_usb, f[3], f[2]) : getString(R.string.card_internal, f[3]));
            if (isUsb && usbName == null) {
                usbName = f[3];
                usbId = f[2];
            }
        }
        StringBuilder pcms = new StringBuilder();
        for (String line : r.get("playing").split("\n")) {
            String[] d = describePlaying(line);
            if (d == null) continue;
            if ("usb".equals(d[0]) && usb == null) usb = d;
            else if (internal == null) internal = d;
            String pcm = line.trim().split("\\s+")[1];
            String name = cardNames.get(pcm.split("/")[0]);
            if (pcms.length() > 0) pcms.append(", ");
            pcms.append(name != null ? name : pcm);
        }
        showUsbDac(r, usbName, usbId);
        if (usb != null) {
            tvPath.setText(getString(R.string.path_usb_now, usb[1]));
        } else if (internal != null) {
            tvPath.setText(getString(is8581 ? R.string.path_internal_now : R.string.path_i2s_now, internal[1]));
        } else if (is8581) {
            tvPath.setText(R.string.path_8581);
        } else {
            tvPath.setText(r.get("i2s_width").contains(">WD_24BIT") || "true".equals(r.get("i2s"))
                    ? R.string.path_i2s_24 : R.string.path_analogue);
        }
        tvPathNote.setText(pcms.length() == 0 ? getString(R.string.path_idle)
                : getString(R.string.path_playing, pcms.toString()));

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

    /** The plugged DAC's own name, id and declared stereo modes; the mode button shows the saved mode. */
    private void showUsbDac(ModuleControl.Result r, String name, String id) {
        usbModes.clear();
        StringBuilder declared = new StringBuilder();
        for (String line : r.get("usb_caps").split("\n")) {
            String[] f = line.trim().split("\\s+"); // cardN FORMAT CHANNELS RATE,RATE
            if (f.length < 4) continue;
            // "S16_LE 2 32000,44100,48000" -> "16-bit, stereo: 32 / 44.1 / 48 kHz"
            StringBuilder khz = new StringBuilder();
            for (String rate : f[3].split(",")) {
                if (!rate.matches("[0-9]{4,6}")) continue;
                int hz = Integer.parseInt(rate);
                if (khz.length() > 0) khz.append(" / ");
                khz.append(hz % 1000 == 0 ? String.valueOf(hz / 1000) : String.valueOf(hz / 1000.0));
            }
            String ch = "2".equals(f[2]) ? getString(R.string.ch_stereo) : "1".equals(f[2]) ? getString(R.string.ch_mono)
                    : getString(R.string.ch_n, f[2]);
            if (declared.length() > 0) declared.append("; ");
            declared.append(getString(R.string.caps_line, f[1].replaceAll("^[SU](\\d+).*$", "$1"), ch, khz));
            if (!"2".equals(f[2])) continue;
            for (String rate : f[3].split(",")) {
                if (rate.matches("[0-9]{4,6}")) usbModes.add(f[1] + "/" + rate);
            }
        }
        tvUsbDac.setText(name == null ? getString(R.string.usb_dac_none)
                : getString(R.string.usb_dac_info, name, id, declared.toString()));
        usbMode = r.get("usb_mode").isEmpty() ? "auto" : r.get("usb_mode");
        btnUsbMode.setText(getString(R.string.usb_mode_btn, modeLabel(usbMode)));
        if (name != null && !"auto".equals(usbMode) && !usbModes.contains(usbMode)) {
            tvUsbResult.setText(R.string.usb_mode_not_supported);
        }
        // the DAC's own volume control or none: without one there is nothing to follow (Android never cuts it)
        boolean noControl = name != null && "none".equals(r.get("usb_dac_volctl"));
        btnUsbVolume.setChecked("follow".equals(r.get("usb_volume")) && !noControl);
        btnUsbVolume.setEnabled(!noControl);
        btnUsbVolume.setText(noControl ? R.string.usb_volume_none : R.string.usb_volume_follow);
        ToggleStyler.apply(btnUsbVolume);
        dacCurve.update(r, name != null && btnUsbVolume.isChecked());
    }

    private void applyUsbVolume(boolean follow) {
        tvUsbResult.setText(R.string.status_loading);
        io.execute(() -> {
            ModuleControl.Result r = ModuleControl.setUsbVolume(follow);
            ui.post(() -> {
                if (!r.ok()) tvUsbResult.setText(getString(R.string.usb_result_error, r.error));
                else if ("saved".equals(r.get("usb_volume_result")))
                    tvUsbResult.setText(follow ? R.string.usb_volume_saved_follow : R.string.usb_volume_saved_full);
                else tvUsbResult.setText(getString(R.string.usb_result_error, r.get("usb_volume_result")));
                refresh();
            });
        });
    }

    /** "S16_LE/44100" -> "16-bit / 44.1 kHz"; auto -> its label. */
    private String modeLabel(String mode) {
        if ("auto".equals(mode)) return getString(R.string.usb_mode_auto);
        String[] d = describePlaying("usb - " + mode.replace("/", " 2 "));
        return d == null ? mode : d[1].replaceAll(",[^,]*$", "");
    }

    private void pickUsbMode() {
        if (usbModes.isEmpty()) {
            tvUsbResult.setText(R.string.usb_mode_unplugged);
        }
        List<String> values = new ArrayList<>();
        values.add("auto");
        values.addAll(usbModes);
        String[] items = new String[values.size()];
        for (int i = 0; i < items.length; i++) items[i] = modeLabel(values.get(i));
        ThemedDialog.showList(this, getString(R.string.usb_mode_title), items, (d, which) -> applyUsbMode(values.get(which)));
    }

    private void applyUsbMode(String mode) {
        tvUsbResult.setText(R.string.status_loading);
        io.execute(() -> {
            ModuleControl.Result r = ModuleControl.setUsbMode(mode);
            ui.post(() -> {
                String res = r.get("usb_mode_result");
                if (!r.ok()) tvUsbResult.setText(getString(R.string.usb_result_error, r.error));
                else if ("changed".equals(res)) tvUsbResult.setText(R.string.usb_result_changed);
                else if ("saved".equals(res)) tvUsbResult.setText(R.string.usb_mode_saved);
                else if ("same".equals(res)) tvUsbResult.setText(R.string.usb_result_same);
                else tvUsbResult.setText(getString(R.string.usb_result_error, res));
                refresh();
            });
        });
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
        for (int id : new int[]{R.id.card_root, R.id.card_platform, R.id.card_path, R.id.card_module, R.id.card_usb, R.id.card_mic, R.id.card_navi, R.id.card_theme}) {
            findViewById(id).setBackground(ThemeManager.cardDrawable(this, night, 16f));
        }
        int primary = ThemeManager.textPrimary(this, night);
        int secondary = ThemeManager.textSecondary(this, night);
        int card = ThemeManager.cardBackground(this, night);
        ((TextView) findViewById(R.id.tv_title)).setTextColor(ThemeManager.contrastText(primary, ThemeManager.background(this, night)));
        tintTexts((ViewGroup) findViewById(R.id.content), primary, secondary, card);
        if (navi != null) navi.applyTheme();
        if (mic != null) mic.applyTheme();
        if (rootCard != null) rootCard.applyTheme();
        if (dacCurve != null) dacCurve.applyTheme();
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
        ToggleStyler.apply(btnUsbMode);
        ToggleStyler.apply(btnUsbVolume);
        for (MaterialButton t : tabs) if (t != null) ToggleStyler.apply(t);
    }

    private static void check(MaterialButton b, boolean on) {
        b.setChecked(on);
        ToggleStyler.apply(b);
    }
}
