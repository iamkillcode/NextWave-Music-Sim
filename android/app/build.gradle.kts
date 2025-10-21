plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nextwave.musicgame"
    compileSdk = 35  // Updated from flutter.compileSdkVersion to support flutter_plugin_android_lifecycle
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Match GitHub Actions Java 17 environment
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs += listOf("-Xjvm-default=all")
    }

    defaultConfig {
        applicationId = "com.nextwave.musicgame"
        minSdk = flutter.minSdkVersion
        targetSdk = 35  // Updated to match compileSdk
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packaging {
        resources.excludes.add("META-INF/*")
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 🧩 Modern Java APIs on older Android versions
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // ⚡ Keep Gradle from re-downloading dependencies unnecessarily
    configurations.all {
        resolutionStrategy.cacheChangingModulesFor(24, "hours")
    }
}
