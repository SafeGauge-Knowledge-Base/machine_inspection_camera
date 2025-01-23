package com.example.machine_inspection_camera;

import android.content.Context;
import android.content.ContextWrapper;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.widget.FrameLayout;
import android.graphics.PixelFormat;
import android.graphics.Color;
import android.view.View;

import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;

import com.arashivision.sdkmedia.player.config.InstaStabType;
import com.arashivision.insta360.basecamera.camera.BaseCamera;
import com.arashivision.insta360.basemedia.asset.WindowCropInfo;
import com.arashivision.insta360.basemedia.model.offset.OffsetData;
import com.arashivision.sdkcamera.camera.InstaCameraManager;
import com.arashivision.sdkcamera.camera.callback.IPreviewStatusListener;
import com.arashivision.sdkmedia.player.capture.CaptureParamsBuilder;
import com.arashivision.sdkmedia.player.capture.InstaCapturePlayerView;
import com.arashivision.sdkmedia.player.listener.PlayerViewListener;

import io.flutter.plugin.platform.PlatformView;

public class InstaCapturePlayerPlatformView implements PlatformView {

    private static final String TAG = "InstaCapturePlayer";
    private final Resolution mCurrentResolution = new Resolution(5760, 720, 29);
    private final InstaCapturePlayerView mCapturePlayerView;
    private final FrameLayout mLayoutSurfaceContainer;
    private SurfaceView mSurfaceView;

    public InstaCapturePlayerPlatformView(Context context) {


        // Initialize layout container
        mLayoutSurfaceContainer = new FrameLayout(context);

        // Add a background view
        View backgroundView = new View(context);
        backgroundView.setLayoutParams(new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ));
        backgroundView.setBackgroundColor(Color.parseColor("#FFDDDD")); // Light red
        mLayoutSurfaceContainer.addView(backgroundView);

        // Initialize InstaCapturePlayerView
        mCapturePlayerView = new InstaCapturePlayerView(context);

        // Retrieve the Lifecycle from the Context
        Lifecycle lifecycle = getLifecycleFromContext(context);
        if (lifecycle == null) {
            throw new IllegalArgumentException("Context is not a LifecycleOwner or does not provide a valid Lifecycle.");
        }

        // Attach lifecycle to the player view
        mCapturePlayerView.setLifecycle(lifecycle);

        // Create and configure SurfaceView
        createSurfaceView(context);

        // Setup capture player view
        setupCapturePlayerView();
    }

    private Lifecycle getLifecycleFromContext(Context context) {
        // Check if the context itself is a LifecycleOwner
        if (context instanceof LifecycleOwner) {
            return ((LifecycleOwner) context).getLifecycle();
        }

        // Check if the context is wrapped (e.g., ContextWrapper)
        if (context instanceof ContextWrapper) {
            return getLifecycleFromContext(((ContextWrapper) context).getBaseContext());
        }

        // No valid LifecycleOwner found
        return null;
    }

    private void createSurfaceView(Context context) {
        if (mSurfaceView == null) {
            Log.d(TAG, "Creating new SurfaceView.");
            mSurfaceView = new SurfaceView(context);

            // Set the pixel format for compatibility
            mSurfaceView.getHolder().setFormat(PixelFormat.RGBA_8888);

            // Add SurfaceView to the layout container
            mLayoutSurfaceContainer.addView(mSurfaceView, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            ));

            // Add SurfaceHolder callbacks
            mSurfaceView.getHolder().addCallback(new SurfaceHolder.Callback() {
                @Override
                public void surfaceCreated(SurfaceHolder holder) {
                    Log.d(TAG, "Surface created and ready for rendering.");
                    mCapturePlayerView.prepare(createParams());
                    mCapturePlayerView.play();
                }

                @Override
                public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
                    Log.d(TAG, "Surface changed: Width = " + width + ", Height = " + height);
                }

                @Override
                public void surfaceDestroyed(SurfaceHolder holder) {
                    Log.d(TAG, "Surface destroyed.");
                    cleanup();
                }
            });
        } else {
            Log.d(TAG, "SurfaceView already exists.");
        }
    }

    private void setupCapturePlayerView() {
        InstaCameraManager.getInstance().setPreviewStatusChangedListener(new IPreviewStatusListener() {
            @Override
            public void onOpening() {
                Log.d(TAG, "Preview Opening");
                createSurfaceView(mLayoutSurfaceContainer.getContext());
            }

            @Override
            public void onOpened() {
                InstaCameraManager.getInstance().setStreamEncode();
                Log.d(TAG, "Preview Opened");
                if (mSurfaceView != null && mSurfaceView.getHolder().getSurface().isValid()) {
                    Log.d(TAG, "Surface is valid, starting preview...");
                    mCapturePlayerView.prepare(createParams());
                    mCapturePlayerView.play();
                    mCapturePlayerView.setKeepScreenOn(true);
                } else {
                    Log.e(TAG, "Surface is not valid for rendering");
                }
            }

            @Override
            public void onIdle() {
                Log.d(TAG, "Preview Idle");
                cleanup();
            }

            @Override
            public void onError() {
                Log.e(TAG, "Preview Error");
            }
        });

        InstaCameraManager.getInstance().startPreviewStream();
    }

    private CaptureParamsBuilder createParams() {
        return new CaptureParamsBuilder()
            .setCameraType(InstaCameraManager.getInstance().getCameraType())
            .setMediaOffset(InstaCameraManager.getInstance().getMediaOffset())
            .setMediaOffsetV2(InstaCameraManager.getInstance().getMediaOffsetV2())
            .setMediaOffsetV3(InstaCameraManager.getInstance().getMediaOffsetV3())
            .setCameraSelfie(InstaCameraManager.getInstance().isCameraSelfie())
            .setGyroTimeStamp(InstaCameraManager.getInstance().getGyroTimeStamp())
            .setBatteryType(InstaCameraManager.getInstance().getBatteryType())
            .setLive(true)
            .setRenderModelType(CaptureParamsBuilder.RENDER_MODE_PLANE_STITCH)
            .setScreenRatio(2, 1)
            .setResolutionParams(mCurrentResolution.width, mCurrentResolution.height, mCurrentResolution.fps)
            .setStabEnabled(true)
            .setStabType(InstaStabType.STAB_TYPE_AUTO)
            .setGestureEnabled(true)
            .setCameraRenderSurfaceInfo(
                mSurfaceView.getHolder().getSurface(),
                mSurfaceView.getWidth(),
                mSurfaceView.getHeight()
            );
    }

    private void cleanup() {
        if (mSurfaceView != null) {
            Log.d(TAG, "Cleaning up SurfaceView and Player.");
            mSurfaceView.getHolder().getSurface().release();
            mLayoutSurfaceContainer.removeView(mSurfaceView);
            mSurfaceView = null;
        }

        if (mCapturePlayerView != null) {
            mCapturePlayerView.destroy();
        }
    }

    @Override
    public android.view.View getView() {
        Log.d(TAG, "Returning platform view.");
        return mLayoutSurfaceContainer;
    }

    @Override
    public void dispose() {
        cleanup();
    }
}
