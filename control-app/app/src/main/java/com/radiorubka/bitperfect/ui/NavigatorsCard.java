package com.radiorubka.bitperfect.ui;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.os.Handler;
import android.os.Looper;
import android.util.TypedValue;
import android.view.ViewGroup;
import android.widget.CheckBox;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.TextView;

import com.google.android.material.button.MaterialButton;
import com.radiorubka.bitperfect.R;
import com.radiorubka.bitperfect.core.ModuleControl;
import com.radiorubka.bitperfect.ui.theme.ThemeManager;
import com.radiorubka.bitperfect.ui.theme.ToggleStyler;
import com.radiorubka.bitperfect.ui.theme.TouchGlow;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ExecutorService;

/**
 * The navigator list (the platform's NaviApp.ini): which apps are navigators, and for each whether its
 * own volume control sets the prompt volume and how loud the music stays under a prompt. The module
 * owns the file ({@code bp_ctl.sh navi ...}); the user's entries live in
 * /sdcard/BitPerfectAudio/navigators.conf. The platform reads the list at boot, so changes apply after a reboot.
 */
public final class NavigatorsCard {

    /** One line of the live list. */
    private static final class Navi {
        String pkg, mix, origin;
        boolean adjust;
        String label; // null = not installed
    }

    private final Activity act;
    private final ExecutorService io;
    private final Handler ui = new Handler(Looper.getMainLooper());
    private final LinearLayout rows;
    private final TextView tvResult;
    private final MaterialButton btnAdd, btnAll;
    private final List<Navi> navis = new ArrayList<>();
    private boolean showAll;

    public NavigatorsCard(Activity act, ExecutorService io) {
        this.act = act;
        this.io = io;
        rows = act.findViewById(R.id.ll_navi_rows);
        tvResult = act.findViewById(R.id.tv_navi_result);
        btnAdd = act.findViewById(R.id.btn_navi_add);
        btnAll = act.findViewById(R.id.btn_navi_all);
        btnAdd.setOnClickListener(v -> pickApp());
        btnAll.setOnClickListener(v -> {
            showAll = !showAll;
            render();
        });
        TouchGlow.attach(btnAdd);
        TouchGlow.attach(btnAll);
    }

    public void load() {
        io.execute(() -> {
            ModuleControl.Result r = ModuleControl.naviList();
            List<Navi> list = new ArrayList<>();
            PackageManager pm = act.getPackageManager();
            for (String line : r.get("navi").split("\n")) {
                String[] f = line.trim().split("\\s+");
                if (f.length < 4) continue;
                Navi n = new Navi();
                n.pkg = f[0];
                n.adjust = "true".equals(f[1]);
                n.mix = f[2];
                n.origin = f[3];
                try {
                    n.label = pm.getApplicationLabel(pm.getApplicationInfo(n.pkg, 0)).toString();
                } catch (PackageManager.NameNotFoundException e) {
                    n.label = null;
                }
                list.add(n);
            }
            ui.post(() -> {
                navis.clear();
                navis.addAll(list);
                if (!r.ok()) tvResult.setText(act.getString(R.string.navi_error, r.error));
                render();
            });
        });
    }

    /** Installed navigators first (by name); with "show all", the rest of the list after them. */
    private void render() {
        rows.removeAllViews();
        List<Navi> installed = new ArrayList<>(), absent = new ArrayList<>();
        for (Navi n : navis) (n.label != null ? installed : absent).add(n);
        Collections.sort(installed, (a, b) -> a.label.compareToIgnoreCase(b.label));
        for (Navi n : installed) rows.addView(row(n));
        if (showAll) for (Navi n : absent) rows.addView(row(n));
        if (installed.isEmpty() && !showAll) rows.addView(note(act.getString(R.string.navi_none_installed)));
        btnAll.setText(showAll ? act.getString(R.string.navi_show_installed)
                : act.getString(R.string.navi_show_all, navis.size()));
        applyTheme();
    }

    private TextView row(Navi n) {
        TextView tv = new TextView(act);
        String name = n.label != null ? n.label : n.pkg;
        String origin = act.getString("user".equals(n.origin) ? R.string.navi_origin_user
                : "bitperfect".equals(n.origin) ? R.string.navi_origin_bitperfect : R.string.navi_origin_factory);
        tv.setText(act.getString(R.string.navi_row, name, n.pkg, origin,
                act.getString(n.adjust ? R.string.navi_adjust_on : R.string.navi_adjust_off), mixText(n.mix)));
        tv.setTextSize(TypedValue.COMPLEX_UNIT_PX, act.getResources().getDimension(R.dimen.text_size_note));
        int pad = (int) ThemedDialog.dp(act, 12);
        tv.setPadding(pad, pad / 2, pad, pad / 2);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.topMargin = (int) ThemedDialog.dp(act, 6);
        tv.setLayoutParams(lp);
        tv.setOnClickListener(v -> rowActions(n));
        TouchGlow.attach(tv);
        return tv;
    }

    private TextView note(String text) {
        TextView tv = new TextView(act);
        tv.setText(text);
        tv.setTextSize(TypedValue.COMPLEX_UNIT_PX, act.getResources().getDimension(R.dimen.text_size_note));
        return tv;
    }

    private String mixText(String mix) {
        return "appset".equals(mix) ? act.getString(R.string.navi_mix_car) : act.getString(R.string.navi_mix_pct, mix);
    }

    private void rowActions(Navi n) {
        if (!"user".equals(n.origin)) {
            edit(n.pkg, n.label != null ? n.label : n.pkg, n.adjust, n.mix);
            return;
        }
        String[] items = {act.getString(R.string.navi_action_edit), act.getString(R.string.navi_action_remove)};
        ThemedDialog.showList(act, n.label != null ? n.label : n.pkg, items, (d, which) -> {
            if (which == 0) edit(n.pkg, n.label != null ? n.label : n.pkg, n.adjust, n.mix);
            else apply(() -> ModuleControl.naviDel(n.pkg));
        });
    }

    /** Launchable apps that are not in the list yet, by name. */
    private void pickApp() {
        io.execute(() -> {
            PackageManager pm = act.getPackageManager();
            Set<String> listed = new HashSet<>();
            for (Navi n : navis) listed.add(n.pkg);
            Intent main = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER);
            List<String[]> apps = new ArrayList<>();
            Set<String> seen = new HashSet<>();
            for (ResolveInfo ri : pm.queryIntentActivities(main, 0)) {
                ApplicationInfo ai = ri.activityInfo.applicationInfo;
                if (listed.contains(ai.packageName) || !seen.add(ai.packageName)
                        || ai.packageName.equals(act.getPackageName())) continue;
                apps.add(new String[]{pm.getApplicationLabel(ai).toString(), ai.packageName});
            }
            Collections.sort(apps, (a, b) -> a[0].compareToIgnoreCase(b[0]));
            ui.post(() -> {
                String[] items = new String[apps.size()];
                for (int i = 0; i < items.length; i++) items[i] = apps.get(i)[0] + "\n" + apps.get(i)[1];
                ThemedDialog.showList(act, act.getString(R.string.navi_pick_title), items,
                        (d, which) -> edit(apps.get(which)[1], apps.get(which)[0], true, "appset"));
            });
        });
    }

    /** The two settings of one navigator; saving writes the user's entry. */
    private void edit(String pkg, String name, boolean adjust, String mix) {
        LinearLayout box = new LinearLayout(act);
        box.setOrientation(LinearLayout.VERTICAL);
        int text = ThemeManager.contrastText(ThemeManager.textPrimary(act), ThemeManager.cardBackground(act));

        TextView tvPkg = note(pkg);
        tvPkg.setTextColor(text);
        CheckBox cbAdjust = new CheckBox(act);
        cbAdjust.setText(R.string.navi_adjust_label);
        cbAdjust.setChecked(adjust);
        cbAdjust.setTextColor(text);
        CheckBox cbCar = new CheckBox(act);
        cbCar.setText(R.string.navi_mix_car_label);
        cbCar.setChecked("appset".equals(mix));
        cbCar.setTextColor(text);
        TextView tvMix = note("");
        tvMix.setTextColor(text);
        SeekBar sb = new SeekBar(act);
        sb.setMax(100);
        sb.setProgress("appset".equals(mix) ? 30 : Integer.parseInt(mix));
        Runnable sync = () -> {
            sb.setEnabled(!cbCar.isChecked());
            tvMix.setText(cbCar.isChecked() ? act.getString(R.string.navi_mix_car)
                    : act.getString(R.string.navi_mix_label, sb.getProgress()));
        };
        cbCar.setOnCheckedChangeListener((b, c) -> sync.run());
        sb.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar s, int p, boolean fromUser) {
                sync.run();
            }

            @Override
            public void onStartTrackingTouch(SeekBar s) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar s) {
            }
        });
        sync.run();
        for (android.view.View v : new android.view.View[]{tvPkg, cbAdjust, cbCar, tvMix, sb}) box.addView(v);

        ThemedDialog.showCustom(act, name, box, act.getString(R.string.navi_save), () -> {
            String m = cbCar.isChecked() ? "appset" : String.valueOf(sb.getProgress());
            boolean a = cbAdjust.isChecked();
            apply(() -> ModuleControl.naviSet(pkg, a, m));
        }, act.getString(R.string.navi_cancel), null);
    }

    private interface Call {
        ModuleControl.Result run();
    }

    private void apply(Call call) {
        tvResult.setText(R.string.status_loading);
        io.execute(() -> {
            ModuleControl.Result r = call.run();
            ui.post(() -> {
                String res = r.get("navi_result");
                if (!r.ok()) tvResult.setText(act.getString(R.string.navi_error, r.error));
                else if ("saved".equals(res)) tvResult.setText(R.string.navi_saved);
                else tvResult.setText(act.getString(R.string.navi_error, res));
                load();
            });
        });
    }

    /** Rows are built in code, so they take the palette here rather than from the activity's text pass. */
    public void applyTheme() {
        boolean night = ThemeManager.isNight(act);
        int card = ThemeManager.cardBackground(act, night);
        int border = ThemeManager.panelBorder(act, night);
        int primary = ThemeManager.contrastText(ThemeManager.textPrimary(act, night), card);
        for (int i = 0; i < rows.getChildCount(); i++) {
            TextView tv = (TextView) rows.getChildAt(i);
            tv.setTextColor(primary);
            if (tv.isClickable()) tv.setBackground(ThemeManager.roundedDrawable(act, 12, card, border, 1.2f));
        }
        ToggleStyler.apply(btnAdd);
        ToggleStyler.apply(btnAll);
    }
}
