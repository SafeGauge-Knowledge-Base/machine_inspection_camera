package com.example.machine_inspection_camera;

import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.arashivision.sdkmedia.player.capture.InstaCapturePlayerView;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformViewFactory;
import io.flutter.plugin.platform.PlatformView;

public class MainActivity extends FlutterActivity {

    private InstaCapturePlayerView mCapturePlayerView;



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
//       @Override
// protected void onCreate(@Nullable Bundle savedInstanceState) {
//     super.onCreate(savedInstanceState);
//     setContentView(R.layout.activity_preview);

//     mCapturePlayerView = findViewById(R.id.player_capture);

// }
}
