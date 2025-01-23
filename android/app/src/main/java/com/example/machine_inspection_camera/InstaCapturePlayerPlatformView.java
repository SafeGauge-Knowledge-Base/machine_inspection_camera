package com.example.machine_inspection_camera;

import android.content.Context;
import android.util.Log;
import android.view.SurfaceView;
import android.view.View;
import android.widget.FrameLayout;

import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;

import com.arashivision.sdkcamera.camera.InstaCameraManager;
import com.arashivision.sdkcamera.camera.callback.IPreviewStatusListener;
import com.arashivision.sdkmedia.player.capture.CaptureParamsBuilder;
import com.arashivision.sdkmedia.player.capture.InstaCapturePlayerView;
import com.arashivision.sdkmedia.player.listener.PlayerViewListener;

import java.util.Arrays;
import java.util.List;

import io.flutter.plugin.platform.PlatformView;

public class InstaCapturePlayerPlatformView implements PlatformView {

    private final InstaCapturePlayerView mCapturePlayerView;
    private final FrameLayout mLayoutSurfaceContainer;
    private SurfaceView mSurfaceView;

    public InstaCapturePlayerPlatformView(Context context) {
        mLayoutSurfaceContainer = new FrameLayout(context);

        // Initialize InstaCapturePlayerView
        mCapturePlayerView = new InstaCapturePlayerView(context);

        // Ensure the context is a LifecycleOwner
        Lifecycle lifecycle = null;
        if (context instanceof LifecycleOwner) {
            lifecycle = ((LifecycleOwner) context).getLifecycle();
        } else {
            throw new IllegalArgumentException("Context is not a LifecycleOwner");
        }

        mCapturePlayerView.setLifecycle(lifecycle);

        // Create the SurfaceView for custom rendering
        createSurfaceView(context);

        // Set up InstaCapturePlayerView callbacks
        setupCapturePlayerView();
    }

    private void setupCapturePlayerView() {
        InstaCameraManager.getInstance().setPreviewStatusChangedListener(new IPreviewStatusListener() {
            @Override
            public void onOpening() {
                Log.d("InstaCapturePlayer", "Preview Opening");
                createSurfaceView(mLayoutSurfaceContainer.getContext());
            }

            @Override
            public void onOpened() {
                Log.d("InstaCapturePlayer", "Preview Opened");
                InstaCameraManager.getInstance().setStreamEncode();

                mCapturePlayerView.setPlayerViewListener(new PlayerViewListener() {
                    @Override
                    public void onLoadingFinish() {
                        Log.d("InstaCapturePlayer", "Loading Finished");
                        InstaCameraManager.getInstance().setPipeline(mCapturePlayerView.getPipeline());
                    }

                    @Override
                    public void onReleaseCameraPipeline() {
                        InstaCameraManager.getInstance().setPipeline(null);
                    }

                });

                // Prepare and start playing
                mCapturePlayerView.prepare(createParams());
                mCapturePlayerView.play();
                mCapturePlayerView.setKeepScreenOn(true);
            }
            

            


            @Override
            public void onIdle() {
                Log.d("InstaCapturePlayer", "Preview Idle");
                cleanup();
            }

            @Override
            public void onError() {
                Log.e("InstaCapturePlayer", "Preview Error");
            }


       
            // public void onVideoData(byte[] videoData) {
            //         Log.d("InstaCapturePlayer", "Video Data Received: " + videoData.length + " bytes");
            //      }

           
            // public void onGyroData(List<float[]> gyroDataList) {
            //     Log.d("InstaCapturePlayer", "Gyro Data Received: " + gyroDataList.size());
            //         }
          
            // public void onExposureData(float[] exposureData) {
            //      Log.d("InstaCapturePlayer", "Exposure Data Received: " + Arrays.toString(exposureData));
            // }
        });

        // Start preview stream
        InstaCameraManager.getInstance().startPreviewStream();
    }

    private void createSurfaceView(Context context) {
        if (mSurfaceView == null) {
            mSurfaceView = new SurfaceView(context);
            mLayoutSurfaceContainer.addView(mSurfaceView, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            ));
        }
    }

    private CaptureParamsBuilder createParams() {
        return new CaptureParamsBuilder()
            .setCameraRenderSurfaceInfo(
                mSurfaceView.getHolder().getSurface(),
                mSurfaceView.getWidth(),
                mSurfaceView.getHeight()
            );
    }

    private void cleanup() {
        if (mSurfaceView != null) {
            mSurfaceView.getHolder().getSurface().release();
            mLayoutSurfaceContainer.removeView(mSurfaceView);
            mSurfaceView = null;
        }

        mCapturePlayerView.destroy();
    }

    @Override
    public View getView() {
        return mLayoutSurfaceContainer;
    }

    @Override
    public void dispose() {
        cleanup();
    }
}
