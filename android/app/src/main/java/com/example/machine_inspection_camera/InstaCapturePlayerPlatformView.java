package com.example.machine_inspection_camera;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;

import com.arashivision.sdkmedia.player.capture.InstaCapturePlayerView;

import io.flutter.plugin.platform.PlatformView;

public class InstaCapturePlayerPlatformView implements PlatformView {
    private final InstaCapturePlayerView playerView;

    public InstaCapturePlayerPlatformView(Context context) {
        // Initialize the InstaCapturePlayerView
        playerView = new InstaCapturePlayerView(context);

        // Example: Set a background color to confirm rendering
        playerView.setBackgroundColor(0xFF000000); // Black background for visibility
    }

    @Override
    public View getView() {
        return playerView;
    }

    @Override
    public void dispose() {
        playerView.destroy();
    }

    
}

