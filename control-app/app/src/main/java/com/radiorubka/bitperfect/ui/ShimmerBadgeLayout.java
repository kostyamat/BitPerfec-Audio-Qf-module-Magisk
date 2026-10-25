package com.radiorubka.bitperfect.ui;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ValueAnimator;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.LinearGradient;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.util.AttributeSet;
import android.view.View;
import android.view.animation.AccelerateDecelerateInterpolator;
import android.widget.LinearLayout;
import android.widget.TextView;
import com.radiorubka.bitperfect.R;

/**
 * ShimmerBadgeLayout: Hardware-accelerated typewriter + shimmering badge layout.
 *
 * Recreates the GitHub/XDA animated typewriter banner:
 * - "☕ Buy me a coffee" / "☕ Пригостити кавою"
 * - "💖 Support my projects" / "💖 Підтримуй мої проекти"
 * - "🚀 Keep updates coming!" / "🚀 Більше оновлень!"
 *
 * Types character-by-character, sweeps a specular liquid-gold/diamond glint across
 * the badge upon completion, holds for a calm pause, backspaces, and rotates to next slogan.
 * Fully localized via R.array.donate_typing_lines.
 */
public class ShimmerBadgeLayout extends LinearLayout {

    private String[] mTypingLines;

    private final Paint mShimmerPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Matrix mMatrix = new Matrix();
    private ValueAnimator mSweepAnimator;

    private TextView mTvBadge;
    private int mLineIndex = 0;
    private int mCharIndex = 0;
    private boolean mIsDeleting = false;

    private float mProgress = -1.0f;
    private boolean mIsSweeping = false;
    private LinearGradient mGradient;
    private int mLastWidth = 0;
    private int mLastHeight = 0;

    private final Runnable mTypewriterRunnable = new Runnable() {
        @Override
        public void run() {
            if (mTvBadge == null || !isAttachedToWindow() || getVisibility() != View.VISIBLE) {
                return;
            }

            if (mTypingLines == null || mTypingLines.length == 0) {
                initLines();
            }

            String currentLine = mTypingLines[mLineIndex % mTypingLines.length];

            if (!mIsDeleting) {
                mCharIndex++;
                if (mCharIndex <= currentLine.length()) {
                    mTvBadge.setText(currentLine.substring(0, mCharIndex));
                    postDelayed(this, 50); // 50ms per character
                } else {
                    startSweepAnimation();
                    mIsDeleting = true;
                    postDelayed(this, 2200); // 2.2s hold with shimmer
                }
            } else {
                mCharIndex--;
                if (mCharIndex >= 0) {
                    mTvBadge.setText(currentLine.substring(0, mCharIndex));
                    postDelayed(this, 25); // 25ms backspace
                } else {
                    mIsDeleting = false;
                    mCharIndex = 0;
                    mLineIndex = (mLineIndex + 1) % mTypingLines.length;
                    postDelayed(this, 300); // pause before next line
                }
            }
        }
    };

    public ShimmerBadgeLayout(Context context) {
        super(context);
        init();
    }

    public ShimmerBadgeLayout(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public ShimmerBadgeLayout(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void initLines() {
        try {
            mTypingLines = getResources().getStringArray(R.array.donate_typing_lines);
        } catch (Throwable ignored) {}
        if (mTypingLines == null || mTypingLines.length == 0) {
            mTypingLines = new String[]{
                    "☕ Buy me a coffee",
                    "💖 Support my projects",
                    "🚀 Keep updates coming!"
            };
        }
    }

    private void init() {
        setWillNotDraw(false);
        initLines();
        mShimmerPaint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.SRC_ATOP));

        mSweepAnimator = ValueAnimator.ofFloat(0.0f, 1.0f);
        mSweepAnimator.setDuration(1100);
        mSweepAnimator.setInterpolator(new AccelerateDecelerateInterpolator());
        mSweepAnimator.addUpdateListener(animation -> {
            mProgress = (float) animation.getAnimatedValue();
            invalidate();
        });
        mSweepAnimator.addListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator animation) {
                mIsSweeping = false;
                mProgress = -1.0f;
                invalidate();
            }

            @Override
            public void onAnimationCancel(Animator animation) {
                mIsSweeping = false;
                mProgress = -1.0f;
            }
        });
    }

    @Override
    protected void onFinishInflate() {
        super.onFinishInflate();
        for (int i = 0; i < getChildCount(); i++) {
            View child = getChildAt(i);
            if (child instanceof TextView) {
                mTvBadge = (TextView) child;
                mTvBadge.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
                break;
            }
        }
    }

    public void startSweepAnimation() {
        if (!isAttachedToWindow() || getVisibility() != View.VISIBLE || getWindowVisibility() != View.VISIBLE) {
            return;
        }
        if (mSweepAnimator != null && !mSweepAnimator.isRunning()) {
            mIsSweeping = true;
            mSweepAnimator.start();
        }
    }

    private void startTypewriter() {
        removeCallbacks(mTypewriterRunnable);
        if (mTvBadge != null) {
            mCharIndex = 0;
            mIsDeleting = false;
            mTvBadge.setText("");
            postDelayed(mTypewriterRunnable, 400);
        }
    }

    private void stopTypewriter() {
        removeCallbacks(mTypewriterRunnable);
        if (mSweepAnimator != null && mSweepAnimator.isRunning()) {
            mSweepAnimator.cancel();
        }
        mIsSweeping = false;
        mProgress = -1.0f;
        invalidate();
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        startTypewriter();
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        stopTypewriter();
    }

    @Override
    protected void onVisibilityChanged(View changedView, int visibility) {
        super.onVisibilityChanged(changedView, visibility);
        if (visibility == View.VISIBLE) {
            startTypewriter();
        } else {
            stopTypewriter();
        }
    }

    @Override
    protected void onWindowVisibilityChanged(int visibility) {
        super.onWindowVisibilityChanged(visibility);
        if (visibility == View.VISIBLE) {
            startTypewriter();
        } else {
            stopTypewriter();
        }
    }

    @Override
    public void draw(Canvas canvas) {
        int width = getWidth();
        int height = getHeight();

        if (width <= 0 || height <= 0 || !mIsSweeping || mProgress < 0.0f) {
            super.draw(canvas);
            return;
        }

        int saveCount = canvas.saveLayer(0, 0, width, height, null);
        super.draw(canvas);

        if (width != mLastWidth || height != mLastHeight || mGradient == null) {
            mLastWidth = width;
            mLastHeight = height;
            float beamWidth = width * 0.45f;

            mGradient = new LinearGradient(
                    0, 0, beamWidth, 0,
                    new int[]{
                            0x00FFFFFF,
                            0x35FFE082,
                            0xF5FFFFFF,
                            0x75FFD54F,
                            0x00FFA726
                    },
                    new float[]{0.0f, 0.35f, 0.50f, 0.65f, 1.0f},
                    Shader.TileMode.CLAMP
            );
        }

        float beamWidth = width * 0.45f;
        float startX = -beamWidth * 1.4f;
        float totalTravel = width + beamWidth * 2.8f;
        float currentX = startX + totalTravel * mProgress;

        mMatrix.reset();
        mMatrix.setRotate(24, beamWidth * 0.5f, height * 0.5f);
        mMatrix.postTranslate(currentX, 0);
        mGradient.setLocalMatrix(mMatrix);
        mShimmerPaint.setShader(mGradient);

        canvas.drawRect(0, 0, width, height, mShimmerPaint);
        canvas.restoreToCount(saveCount);
    }
}
