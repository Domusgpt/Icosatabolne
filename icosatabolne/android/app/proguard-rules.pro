# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# VIB3 Plugin
-keep class com.vib3.flutter.** { *; }
-keep class com.vib3.engine.** { *; }

# JNI
-keepclasseswithmembernames class * {
    native <methods>;
}

# Ensure native lib isn't stripped aggressively (though typical R8 rules don't strip .so files, they strip the Java hooks)
