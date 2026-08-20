plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "dev.codehunters.astra"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "dev.codehunters.astra"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// ─── Auto-copy release arm64 APK to releases/arm64/ ─────────────────────────
//
// After running:
//   flutter build apk --release --target-platform android-arm64
//
// The APK is automatically copied to:
//   releases/arm64/astra-arm64-v<versionName>-<versionCode>.apk
//
afterEvaluate {
    tasks.matching { it.name == "assembleRelease" }.configureEach {
        doLast {
            val versionName = android.defaultConfig.versionName ?: "unknown"
            val versionCode = android.defaultConfig.versionCode ?: 0

            val srcArm64 = file("${layout.buildDirectory.get()}/outputs/apk/release/app-arm64-v8a-release.apk")
            val srcUniversal = file("${layout.buildDirectory.get()}/outputs/apk/release/app-release.apk")

            // releases/arm64/ folder sits at workspace root level (sibling of android/)
            val destDir = rootProject.rootDir.parentFile.resolve("releases/arm64")
            destDir.mkdirs()

            val src = when {
                srcArm64.exists()    -> srcArm64
                srcUniversal.exists() -> srcUniversal
                else                 -> null
            }

            if (src != null) {
                val destName = "astra-arm64-v${versionName}-${versionCode}.apk"
                val destFile = destDir.resolve(destName)
                try {
                    if (destFile.exists()) {
                        destFile.delete()
                    }
                    src.copyTo(destFile, overwrite = true)
                    println("\n✅  APK copied  →  releases/arm64/$destName\n")
                } catch (e: Exception) {
                    try {
                        destFile.writeBytes(src.readBytes())
                        println("\n✅  APK copied via writeBytes  →  releases/arm64/$destName\n")
                    } catch (e2: Exception) {
                        println("\n⚠️  Could not copy release APK to releases/arm64/$destName (${e.message})\n")
                    }
                }
            } else {
                println("\n⚠️  Release APK not found — run with --target-platform android-arm64\n")
            }
        }
    }
}
