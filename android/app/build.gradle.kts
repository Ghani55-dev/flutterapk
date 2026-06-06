plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.incite_flutter"
    compileSdk = flutter.compileSdkVersion
    // Set explicit NDK version required by some plugins (backward-compatible)
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.incite_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Replace with your release signing config (keystore) before publishing.
                signingConfig = signingConfigs.getByName("debug")
                // Temporarily disable minification and resource shrinking to diagnose release crash
                isMinifyEnabled = false
                isShrinkResources = false
            proguardFiles += getDefaultProguardFile("proguard-android-optimize.txt")
            proguardFiles += file("proguard-rules.pro")
        }
    }

    dependencies {
        // Required for core library desugaring (java.time, etc.) used by some plugins
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    }

    // Add Play Core libraries for Play Store deferred components / splitcompat
    dependencies {
        implementation("com.google.android.play:core:1.10.3")
        implementation("com.google.android.play:core-ktx:1.8.1")
    }
}

flutter {
    source = "../.."
}
