# Keep Insta360 SDK packages
-keep class com.arashivision.** { *; }
-keep class com.arashivision.insta360.** { *; }
-keep class com.arashivision.insta360.basecamera.** { *; }
-keep class com.arashivision.insta360.basemedia.** { *; }

# Keep JNI calls
-keep class com.machine_inspection_camera.jni.** { *; }

# Don't warn
-dontwarn com.arashivision.**
-dontwarn com.arashivision.insta360.**
