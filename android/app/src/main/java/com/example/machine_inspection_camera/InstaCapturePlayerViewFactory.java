package com.example.machine_inspection_camera;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;

import androidx.annotation.NonNull;

import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class InstaCapturePlayerViewFactory extends PlatformViewFactory {
    public InstaCapturePlayerViewFactory() {
        super(StandardMessageCodec.INSTANCE);
    }

    @Override
    public PlatformView create(Context context, int id, Object args) {
        return new InstaCapturePlayerPlatformView(context);
    }
}
