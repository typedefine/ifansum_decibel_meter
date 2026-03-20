plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ifansum.decibelmeter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ifansum.decibelmeter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
    }


    signingConfigs {
//        release {
//            storeFile = file('../decibel_meter_release_key-key.jks')
//            storePassword = '123456'
//            keyAlias = 'decibel_meter_release'
//            keyPassword = '123456'
//        }

        create("release") {
            storeFile = file("../decibel_meter_release_key.keystore")
            storePassword = "123456"
            keyAlias = "decibel_meter_release"
            keyPassword = "123456"
        }

    }

    buildTypes {
//        release {
//            // TODO: Add your own signing config for the release build.
//            // Signing with the debug keys for now, so `flutter run --release` works.
////            signingConfig = signingConfigs.getByName("debug")
//            signingConfig = signingConfigs.release
//        }
//        debug{
//            signingConfig = signingConfigs.debug
//        }

        getByName("debug") {
//            signingConfig = signingConfigs.getByName("debug")
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }

        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            //关闭混淆
            isMinifyEnabled = true
            //删除无用资源
            isShrinkResources = true
        }

    }
}

flutter {
    source = "../.."
}
