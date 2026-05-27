# Installing My Namaz on a Real Device

This guide covers installing a production build of the app on your own iPhone or Android phone — no App Store / Play Store required.

---

## 📱 iPhone (iOS)

### Option A — Sideload with a free Apple ID (easiest, expires every 7 days)

You don't need a paid Apple Developer account. The free tier lets you install the app on **your own** device for 7 days at a time, after which you re-run the install.

**Requirements**
- A Mac with Xcode 15+ installed
- A USB-C / Lightning cable
- Your free Apple ID

**Steps**

1. **Open the project in Xcode**
   ```bash
   cd /Users/Shared/sites/personal/my_namaz
   open ios/Runner.xcworkspace
   ```
   (Open the `.xcworkspace`, **not** `.xcodeproj`.)

2. **Set your signing team**
   - In Xcode, click the `Runner` project in the left sidebar
   - Select the `Runner` target → **Signing & Capabilities** tab
   - Tick **Automatically manage signing**
   - Team: choose your personal team (your Apple ID). If none, click "Add account..." and sign in with your Apple ID
   - Change the **Bundle Identifier** to something unique like `com.yourname.mynamaz` (Apple won't let two people use the same one)

3. **Plug in your iPhone and trust the Mac**
   - On the phone, tap "Trust This Computer"
   - In Xcode's top toolbar, pick your iPhone from the device dropdown (not a simulator)

4. **Enable Developer Mode on the iPhone** (iOS 16+)
   - Settings → Privacy & Security → Developer Mode → On
   - Phone will reboot and re-prompt to enable; tap **Turn On**

5. **Run from Xcode** — press **▶ (Cmd+R)**.
   The first run will fail with "Untrusted Developer". To trust:
   - On the iPhone: Settings → General → VPN & Device Management → tap your Apple ID under **Developer App** → Trust
   - Tap ▶ again in Xcode

6. **App is now installed**. Unplug the phone — you can open it from the home screen for 7 days.

To **renew after 7 days**, just plug back in and press ▶ in Xcode again.

### Option B — Build IPA and install with sideloading tools

If you want to install without rebuilding every week, you can build an `.ipa` and use a tool like [AltStore](https://altstore.io) or [Sideloadly](https://sideloadly.io).

```bash
flutter build ios --release --no-codesign
# Then open Xcode, Product > Archive, Distribute App > Development > Export as IPA
```

Drop the resulting `.ipa` into AltStore / Sideloadly. Same 7-day limit applies but the tool can auto-resign.

### Option C — Paid Apple Developer account ($99/year)

Lets you:
- Install on your own devices for **1 year** instead of 7 days
- Distribute via **TestFlight** to up to 10,000 testers (great for sharing with family/friends)
- Publish to the App Store

Sign up at https://developer.apple.com/programs, then in Xcode's Signing tab, pick the paid team. Build + archive + Distribute App → App Store Connect → upload to TestFlight.

---

## 🤖 Android

Android is much simpler — no developer account needed. Just sideload the APK.

### One-time setup (this Mac)

Install the Android SDK. Easiest:

```bash
# Install Android Studio (one-time)
brew install --cask android-studio
```

Then open Android Studio once → it'll download the SDK. After that:

```bash
flutter doctor                       # verify Android SDK is detected
flutter doctor --android-licenses    # accept all the SDK licenses
```

### Build a release APK

```bash
cd /Users/Shared/sites/personal/my_namaz
flutter build apk --release
```

The APK appears at:
```
build/app/outputs/flutter-apk/app-release.apk
```

For a smaller download tailored to each CPU architecture, use:
```bash
flutter build apk --release --split-per-abi
```
You'll get three APKs in the same folder (`app-arm64-v8a-release.apk` is the one for modern phones).

### Sign the APK (required for installation on most phones)

Flutter signs release APKs with a debug key by default, which works on your own device but is not safe to share. For a real release key:

1. **Generate a keystore** (one-time)
   ```bash
   keytool -genkey -v -keystore ~/my-namaz-release.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias my-namaz
   ```
   Save the password somewhere safe — losing it means you can never update the app.

2. **Create `android/key.properties`** (do not commit this file)
   ```
   storePassword=YOUR_PASSWORD
   keyPassword=YOUR_PASSWORD
   keyAlias=my-namaz
   storeFile=/Users/yourname/my-namaz-release.jks
   ```

3. **Wire it into `android/app/build.gradle.kts`** — at the top of the file, before `android { ... }`:
   ```kotlin
   import java.util.Properties
   import java.io.FileInputStream

   val keystoreProperties = Properties()
   val keystorePropertiesFile = rootProject.file("key.properties")
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(FileInputStream(keystorePropertiesFile))
   }
   ```
   Then inside `android { ... }`, add:
   ```kotlin
   signingConfigs {
       create("release") {
           keyAlias = keystoreProperties["keyAlias"] as String
           keyPassword = keystoreProperties["keyPassword"] as String
           storeFile = file(keystoreProperties["storeFile"] as String)
           storePassword = keystoreProperties["storePassword"] as String
       }
   }
   buildTypes {
       getByName("release") {
           signingConfig = signingConfigs.getByName("release")
       }
   }
   ```

4. **Rebuild** — `flutter build apk --release` now produces a properly signed APK.

### Install on your phone

**Easiest — USB cable:**

```bash
# Enable Developer Options on the phone:
#   Settings → About phone → tap "Build number" 7 times
# Then enable USB debugging:
#   Settings → Developer options → USB debugging → On

flutter install                   # auto-detects connected device
# or
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Easiest — no cable:**

1. Copy the APK to Google Drive / email / AirDrop to the phone
2. Tap the APK on the phone
3. Phone will prompt "Install unknown apps" — allow it for the source (e.g., Drive)
4. Install. Done.

### Share with others (Android)

For Android you can just send the `.apk` file via WhatsApp, Telegram, Drive, or any file-sharing method. Recipients install it the same way (allow unknown sources for that one source).

For a more polished distribution, use:
- **Google Play Store** — $25 one-time fee, public listing
- **Internal testing** track on Play — share via email list, free
- **Firebase App Distribution** — free, send install link to up to 200 testers

---

## TL;DR

| Want | iPhone | Android |
|------|--------|---------|
| Install on **your own** phone | Plug in, Xcode ▶ (free, 7 days) | `flutter build apk --release`, copy APK to phone |
| Share with friends | TestFlight ($99/yr) | Send APK file directly (free) |
| Public release | App Store ($99/yr) | Play Store ($25 one-time) |

Android is dramatically friendlier for self-distribution — no developer account, no signing dance unless you want it, and recipients install with a single tap.
