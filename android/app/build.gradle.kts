import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is read from android/key.properties, which is git-ignored and
// must never be committed. Absent (a normal dev checkout), release builds fall
// back to the debug key and the guard below refuses to let that ship.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}
val hasReleaseSigning = keystoreProperties.containsKey("storeFile")

android {
    namespace = "com.example.chronos_planner"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications: it uses java.time on API
        // levels below 26, and minSdk here is 24.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // NOTE: still the Flutter template default. Google Play rejects any
        // `com.example.*` id, and the id is permanent once published, so it has
        // to be a domain you control. The release guard below fails the build
        // rather than letting this ship by accident.
        applicationId = "com.example.chronos_planner"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = keystoreProperties.getProperty("storeFile")
                    ?.let { rootProject.file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                // Keeps `flutter run --release` working locally; the guard below
                // stops an unsigned-for-distribution artifact being mistaken for
                // a shippable one.
                signingConfigs.getByName("debug")
            }
        }
    }
}

// Fails loudly rather than shipping something Play will reject or that is
// signed with a key anyone can reproduce. Runs only for bundles and release
// APKs, so ordinary development is untouched.
tasks.matching { it.name == "bundleRelease" || it.name == "assembleRelease" }
    .configureEach {
        doFirst {
            val bypass = project.findProperty("allowUnshippableRelease") == "true"
            val problems = mutableListOf<String>()
            if (android.defaultConfig.applicationId?.startsWith("com.example") == true) {
                problems += "applicationId is still '${android.defaultConfig.applicationId}'. " +
                    "Google Play rejects com.example.*; set a domain you control " +
                    "in android/app/build.gradle.kts (and the matching namespace)."
            }
            if (!hasReleaseSigning) {
                problems += "No android/key.properties, so this build is signed with the " +
                    "debug key and cannot be distributed. See android/key.properties.example."
            }
            if (problems.isNotEmpty()) {
                val detail = problems.joinToString("\n  - ")
                if (bypass) {
                    logger.warn(
                        "WARNING: this release cannot be distributed:\n  - " + detail,
                    )
                } else {
                    throw GradleException(
                        "Release build blocked:\n  - " + detail +
                            "\n\nTo build anyway, for local verification only, pass " +
                            "-PallowUnshippableRelease=true",
                    )
                }
            }
        }
    }

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
