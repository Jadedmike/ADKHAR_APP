# Flutter ProGuard/R8 Rules for Production Optimization & Shrinking

# Preserve Flutter engine & plugin entrypoints
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve generated plugin registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Ignore warnings for unused Play Core deferred component classes
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
