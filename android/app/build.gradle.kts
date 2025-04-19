plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fitstride.runningapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Define flavor dimension
    flavorDimensions += "environment"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fitstride.runningapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Define product flavors
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            // Add specific configurations for dev if needed
            // Example: resValue("string", "app_name", "FitStride Dev")
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            // Add specific configurations for staging if needed
            // Example: resValue("string", "app_name", "FitStride Staging")
        }
        create("prod") {
            dimension = "environment"
            // No suffix for production
            // Add specific configurations for prod if needed
            // Example: resValue("string", "app_name", "FitStride")
        }
    }
}

flutter {
    source = "../.."
}
