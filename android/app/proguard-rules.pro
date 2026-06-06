# Keep Flutter engine classes
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep common libraries used by plugins
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep OkHttp/Dio related classes sometimes accessed via reflection
-dontwarn okhttp3.**
-dontwarn okio.**

# Keep PDF native bindings (pdfx uses native libs)
-keep class com.pspdfkit.** { *; }

# Remove logging calls in Release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
}

# Prevent stripping of annotation used by some JSON libs
-keepattributes *Annotation*

# Keep Play Core classes used by deferred components / splitcompat
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Additional safe keep rules
# Flutter core
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-dontwarn com.google.firebase.**

# Play Core (already present above but reinforce keep/dontwarn)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# ExoPlayer / just_audio
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# pdfx (alternative package)
-keep class io.scer.pdfx.** { *; }

# Kotlin warnings
-dontwarn kotlin.**
