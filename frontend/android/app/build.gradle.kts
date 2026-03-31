plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nelna.maintenance"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.nelna.maintenance"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Set these four properties in your local ~/.gradle/gradle.properties
            // (never commit the keystore or passwords to source control):
            //   NELNA_KEY_STORE_PATH=/path/to/nelna-release.jks
            //   NELNA_KEY_ALIAS=nelna
            //   NELNA_KEY_PASSWORD=<key-password>
            //   NELNA_STORE_PASSWORD=<store-password>
            val keystorePath = System.getenv("NELNA_KEY_STORE_PATH")
                ?: project.findProperty("NELNA_KEY_STORE_PATH") as String?
            val keyAlias = System.getenv("NELNA_KEY_ALIAS")
                ?: project.findProperty("NELNA_KEY_ALIAS") as String?
            val keyPassword = System.getenv("NELNA_KEY_PASSWORD")
                ?: project.findProperty("NELNA_KEY_PASSWORD") as String?
            val storePassword = System.getenv("NELNA_STORE_PASSWORD")
                ?: project.findProperty("NELNA_STORE_PASSWORD") as String?

            if (keystorePath != null) {
                storeFile = file(keystorePath)
                this.storePassword = storePassword ?: ""
                this.keyAlias = keyAlias ?: ""
                this.keyPassword = keyPassword ?: ""
            }
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.findByName("release")
            signingConfig = if (releaseSigning?.storeFile != null) releaseSigning
                            else signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
