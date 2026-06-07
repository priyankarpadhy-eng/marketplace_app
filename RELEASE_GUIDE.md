# App Release Final Steps: Market App

Great! Now that you've generated the `upload-keystore.jks`, follow these final configuration steps.

---

## Step 1: Create `android/key.properties`

Create a file at `android/key.properties`. This file is used by Gradle to sign your app.

**File Contents:**
```properties
storePassword=[your_password]
keyPassword=[your_password]
keyAlias=upload
storeFile=upload-keystore.jks
```

> [!WARNING]
> Do NOT share this file or upload it to GitHub. It contains your private keys.

---

## Step 2: Update `android/app/build.gradle.kts`

Open `android/app/build.gradle.kts` and update the `android` block to read your properties:

```kotlin
import java.util.Properties
import java.io.FileInputStream

// 1. Add this at the TOP of the file (below plugins)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    ...
    // 2. Register the 'release' signing configuration
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // 3. Update this line to use the 'release' config
            signingConfig = signingConfigs.getByName("release")
            
            // Optional: for performance and security
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}
```

---

## Step 3: Firebase & Supabase SHA-1

You must add your **Release Fingerprint** to Firebase and Supabase, or logins won't work in the final app.

1.  **Get fingerprints**:
    ```powershell
    & "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore android/app/upload-keystore.jks -alias upload
    ```
2.  **Add to Dashboards**: Copy the `SHA1` output and paste it into:
    *   **Firebase**: Project Settings -> Your Android App.
    *   **Supabase**: Under Google Authentication settings.

---

## Step 4: Final Build

Run one of these commands to build your app for the store:

```powershell
# For Play Store (recommended)
flutter build appbundle

# For direct sharing (APK)
flutter build apk --release
```

The output will be found in: `build/app/outputs/flutter-apk/app-release.apk`
