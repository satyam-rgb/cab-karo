# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Prevent ProGuard from stripping out classes that you may need for reflection or libraries
-keepattributes *Annotation*

# Keep classes with @Keep annotation
-keep @interface androidx.annotation.Keep
-keepclassmembers class ** {
    @androidx.annotation.Keep *;
}

# Keep Gson library classes if you're using them
-keep class com.google.gson.** { *; }

# If you are using libraries that need reflection, keep these classes
-keep class **.R$* { *; }
-keep class com.google.** { *; }

# Keep generated model classes for Flutter's Dart-Java/Kotlin bridge
-keep class GeneratedPluginRegistrant { *; }
