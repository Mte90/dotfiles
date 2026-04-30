# Delivering the APK to an End User

## 11.1 Release Signing (Not Debug!)

The debug keystore is fine for local testing but **must NOT** be used for distribution. Reasons:

- Every developer has the same debug keystore — anyone could impersonate your build
- It uses weak credentials (password: `android`)
- Android may display security warnings
- You cannot update the app later if you switch to a real keystore

**Create a release keystore (one time)**:

```bash
keytool -genkey -v -keystore ~/release.keystore \
    -alias myapp \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000
```

You'll be prompted for: keystore password (use something STRONG), key password, name, organization, city, state, country code. **BACKUP THIS FILE. If you lose it, users must uninstall and reinstall.**

**Sign for release**:

```bash
zipalign -v -p 4 rebuilt.apk rebuilt_aligned.apk
apksigner sign \
    --ks ~/release.keystore \
    --ks-key-alias myapp \
    --ks-pass pass:YOUR_PASSWORD \
    --key-pass pass:YOUR_KEY_PASSWORD \
    --v1-signing-enabled true \
    --v2-signing-enabled true \
    --v3-signing-enabled true \
    rebuilt_aligned.apk
```

**Verify**:

```bash
apksigner verify --verbose --print-certs rebuilt_aligned.apk
```

Expected output:
- `Verified using v1 scheme (JAR signing): true`
- `Verified using v2 scheme (APK Signature Scheme v2): true`
- `Verified using v3 scheme (APK Signature Scheme v3): true`
- `Number of signers: 1`

## 11.2 What the End User Must Do Before Installing

**The user needs to perform these steps on their phone**:

1. **Uninstall the original app (CRITICAL)**
   
   Since your APK is signed with a different key than the original (from Play Store or OEM), Android will refuse to install it as an update. The user **must uninstall the original first**:
   
   ```
   Settings → Apps → [App Name] → Uninstall
   ```
   
   **Warning**: This will delete all app data (logged-in sessions, saved preferences, local files). If the user has important data, they should back it up first.

2. **Enable installation from unknown sources**
   
   On Android 8+:
   ```
   Settings → Apps → Special App Access → Install Unknown Apps
   → Select your browser or file manager → Allow
   ```
   
   On older Android:
   ```
   Settings → Security → Unknown Sources → Enable
   ```

3. **Disable Play Store auto-updates**
   
   If the Play Store auto-updates the app, it will reinstall the original version, overwriting your patch:
   ```
   Play Store → [App Name] → ⋮ menu → Uncheck "Enable auto-update"
   ```
   
   Or globally:
   ```
   Play Store → Profile → Settings → Network → Auto-update apps → Don't auto-update apps
   ```

4. **(If using split APKs) Install a split APK installer**
   
   Users cannot install split APKs natively. They need an app like **SAI (Split APKs Installer)**:
   ```
   Download from: https://github.com/aefyr/SAI
   Or from F-Droid
   ```

## 11.3 Distribution Methods

**Method A: Direct APK file transfer (simplest for single APK)**

- **USB cable**: Copy to phone's Download/ folder
- **File sharing**: Telegram, WhatsApp, email (if < 25MB)
- **Cloud**: Upload to Google Drive / Dropbox / Mega, share link
- **Direct download**: Host on your server, send URL
- **QR code**: Generate from download URL for easy phone scanning

**Method B: .apks bundle (for split APKs)**

```bash
# Create a bundletool-compatible .apks file
java -jar bundletool.jar build-bundle \
    --modules=base_signed.apk,split_config.arm64_v8a_signed.apk \
    --output=myapp_patched.apks
```

**Method C: .apkm file (APKMirror format, compatible with SAI)**

```bash
cp myapp_patched.apks myapp_patched.apkm
```

**Method D: ADB install via USB (for technical users)**

```bash
# User enables Developer Options + USB Debugging:
# Settings → About Phone → Tap "Build number" 7 times
# Settings → Developer Options → USB Debugging → Enable

adb devices
adb install myapp_patched_signed.apk
```

## 11.4 Preventing Play Store Overwrites

After the user installs your patched APK, the Play Store will eventually try to "update" it back to the original version. Prevention strategies:

**Strategy 1: Disable Play Store notifications (least invasive)**

```
Play Store → Profile → Settings → Notifications → Uncheck "App updates available"
```

**Strategy 2: Use a package name prefix (advanced)**

If you change the package name in `AndroidManifest.xml` (e.g., from `com.example.app` to `com.example.app.patched`), the Play Store won't recognize it as the same app and won't try to update it. However, the patched app becomes a separate installation — it won't share data with the original.

**Strategy 3: Freeze the app in Play Store (requires root)**

With Magisk + App Manager / Icebox: "Freeze" the Play Store version so it can't auto-update.

**Strategy 4: Disable auto-updates globally**

```
Play Store → Profile → Settings → Network → Auto-update apps → Don't auto-update apps
```
