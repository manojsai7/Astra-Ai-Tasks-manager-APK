# Flutter plugins are discovered dynamically. Keep their public entry points
# while R8 removes unused application and Android resources in release builds.
-keep class io.flutter.plugins.** { *; }
