plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin must be applied after Android/Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // <- do NOT add version here
}

android {
    namespace = "com.example.fprojects"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.14206865"

    defaultConfig {
        applicationId = "com.example.my_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}