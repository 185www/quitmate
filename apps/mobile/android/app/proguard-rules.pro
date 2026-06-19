# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Riverpod
-dontwarn com.riverpod.**

# GoRouter
-dontwarn go_router.**

# sqflite
-keep class com.example.lib.** { *; }

# http
-dontwarn dio.**
-dontwarn http.**
