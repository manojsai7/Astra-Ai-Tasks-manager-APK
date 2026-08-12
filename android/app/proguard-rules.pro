# Flutter ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# SQLite / Drift rules
-keepclassmembers class * extends androidx.room.RoomDatabase { *; }
-dontwarn sqlite3.**
-dontwarn com.google.api.**
-dontwarn com.google.auth.**

# Package Info Plus & Google Sign In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
