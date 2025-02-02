package com.example.machine_inspection_camera;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends FlutterFragmentActivity {

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Register the custom platform view factory
        flutterEngine
            .getPlatformViewsController()
            .getRegistry()
            .registerViewFactory(
                "com.arashivision.sdkmedia.player.capture.InstaCapturePlayerView",
                new InstaCapturePlayerViewFactory()
            );
    }
}
