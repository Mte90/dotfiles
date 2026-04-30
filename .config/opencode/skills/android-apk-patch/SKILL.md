# Android APK Patching & Repackaging Skill  
**Version**: 4.0 | **Last Updated**: 2025-07 | **Difficulty**: Expert

> A complete, self-contained reference for modifying Android APKs — from decompilation to adding features, signing, testing, and local delivery. Covers split APKs, GApps, signing schemes, and dynamic analysis. No Xposed/LSPatch dependency.

---

## Table of Contents

1. [Toolchain Setup & Version Requirements](#1-toolchain-setup--version-requirements)
2. [Decompilation & Recompilation Workflow](#2-decompilation--recompilation-workflow)
3. [Split APK Handling (.apks / .apkm / .xapk)](#3-split-apk-handling)
4. [Signing: Schemes, Pitfalls, and Fix Procedures](#4-signing-schemes-pitfalls-and-fix-procedures)
5. [Dependency Hell: Frameworks, AndroidX, OEM Resources](#5-dependency-hell-frameworks-androidx-oem-resources)
6. [GApps-Dependent APKs: Patching & Workarounds](#6-gapps-dependent-apks-patching--workarounds)
7. [Testing Without a Physical Device](#7-testing-without-a-physical-device)
8. [Local Testing: Redroid & Waydroid](#8-local-testing-redroid--waydroid)
9. [Advanced Patching Techniques](#9-advanced-patching-techniques) → [references/advanced-patching.md](references/advanced-patching.md)
10. [Adding Features to an APK](#10-adding-features-to-an-apk) → [references/adding-features.md](references/adding-features.md)
11. [Delivering the APK to an End User](#11-delivering-the-apk-to-an-end-user) → [references/delivery.md](references/delivery.md)
12. [End-to-End Workflow: Zero to Delivery](#12-end-to-end-workflow-zero-to-delivery) → [references/end-to-end-workflow.md](references/end-to-end-workflow.md)
13. [Troubleshooting: Common Failures & Resolutions](#13-troubleshooting-common-failures--resolutions) → [references/troubleshooting.md](references/troubleshooting.md)
14. [Quick Reference Cheat Sheet](#14-quick-reference-cheat-sheet) → [references/quick-reference.md](references/quick-reference.md)

---

## 1. Toolchain Setup & Version Requirements

### 1.1 Mandatory Tools (Current Stable Versions)

| Tool | Version | Purpose | URL |
|---|---|---|---|
| **Apktool** | **v2.11.0** (Jan 2025) | Decompile/recompile APKs | https://github.com/iBotPeaches/Apktool |
| **jadx** | **v1.5.1** | Read-only Java decompiler | https://github.com/skylot/jadx |
| **smali/baksmali** | **v3.0.9** (bundled in Apktool 2.11.0) | DEX bytecode assembly/disassembly | https://github.com/baksmali/smali |
| **APKEditor** | Latest | Merge/split APK handling | https://github.com/pxb1988/APKEditor |
| **apksigner** | SDK Build Tools **35.0.x** | APK signing (v1/v2/v3/v4) | Part of Android SDK |
| **zipalign** | SDK Build Tools **35.0.x** | APK alignment before signing | Part of Android SDK |
| **Frida** | **v17.9.0** | Dynamic instrumentation | https://frida.re |
| **ADB** | Platform Tools **35.0.x** | Device/emulator communication | Part of Android SDK |

### 1.2 Why Old Tool Versions Will Fail You

- **Apktool < 2.9.0** — Cannot handle API 34+ resources. Decompilation of Android 14+ APKs will crash with obscure AAPT errors or produce corrupted `resources.arsc` output.
- **Apktool < 2.6.0** — Uses legacy AAPT (v1) instead of AAPT2. Causes massive resource recompilation failures with any app using AndroidX, Material Components, or modern resource features.
- **smali < 3.0.5** — Cannot disassemble DEX format 038+ (Android 13+). baksmali will fail with `"Unsupported DEX format"` on any app compiled with `minSdkVersion 33+`.
- **jarsigner (any version)** — Only produces v1 (JAR) signatures. Modern Android (7.0+) requires at minimum v2 signatures. Using jarsigner will result in `INSTALL_PARSE_FAILED_NO_CERTIFICATES` or silent signature rejection.

### 1.3 Environment Setup

```bash
# Java 11+ required (Java 17 recommended)
java -version  # verify
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# Install Apktool
# Download latest from https://github.com/iBotPeaches/Apktool/releases
# Move apktool.jar to PATH
chmod +x apktool
sudo mv apktool /usr/local/bin/

# Install Android SDK Build Tools (for apksigner + zipalign)
sdkmanager "build-tools;35.0.0"
sdkmanager "platform-tools"

# Install jadx
# Download from https://github.com/skylot/jadx/releases
# Extract and add bin/ to PATH

# Install Frida
pip install frida-tools

# Install APKEditor
# Download APKEditor.jar from https://github.com/pxb1988/APKEditor/releases
```

---

## 2. Decompilation & Recompilation Workflow

### 2.1 Standard Single APK Workflow

```bash
# Step 1: Analyze with jadx first (understand what you're modifying)
jadx-gui target.apk  # GUI for exploration
# or
jadx -d analysis_output/ target.apk  # CLI

# Step 2: Decompile with apktool
apktool d target.apk -o decompiled/ -f
# -f = force overwrite existing output directory
# --api 35 = force target API level (use if resource errors occur)

# Step 3: Make modifications
# - Edit smali files in decompiled/smali*/  (Java bytecode)
# - Edit resources in decompiled/res/       (layouts, strings, drawables)
# - Edit AndroidManifest.xml               (permissions, components)
# - Edit assets/                           (bundled files, web content)

# Step 4: Recompile
apktool b decompiled/ -o rebuilt.apk
# Use --use-aapt2 flag if not on 2.11.0 (now default)

# Step 5: Align (CRITICAL - must be BEFORE signing)
zipalign -v -p 4 rebuilt.apk rebuilt_aligned.apk

# Step 6: Sign
apksigner sign --ks ~/.android/debug.keystore \
    --ks-pass pass:android \
    --key-pass pass:android \
    rebuilt_aligned.apk

# Step 7: Verify
apksigner verify --verbose --print-certs rebuilt_aligned.apk

# Step 8: Install
adb install -r rebuilt_aligned.apk
```

### 2.2 Important Decompilation Flags

```bash
# Force specific API level (fixes many resource resolution issues)
apktool d target.apk -o out/ -f --api 35

# Ignore missing resources (new in 2.11.x, for XAPK/base APK decompilation)
apktool d target.apk -o out/ -f --ignore-missing-resources

# Keep original sources only (skip resources, faster)
apktool d target.apk -o out/ -f -s

# Decode only resources (skip smali, for resource-only mods)
apktool d target.apk -o out/ -f -r

# For Samsung/Android 15 framework JARs with DEX format 039
apktool d framework.jar -api 29 -o out/

# Use a custom framework file (for OEM system APKs)
apktool if /path/to/oem-framework.apk
apktool d system_app.apk -o out/ -f
```

### 2.3 Understanding the Decompiled Structure

```
decompiled/
├── AndroidManifest.xml        # App manifest (XML format, editable)
├── apktool.yml                # Apktool metadata (DO NOT manually edit version fields)
├── assets/                    # Raw asset files
├── lib/                       # Native libraries (.so files) by architecture
│   ├── arm64-v8a/
│   ├── armeabi-v7a/
│   └── x86_64/
├── original/                  # Original files (META-INF, etc.)
├── res/                       # Compiled resources (XML format, editable)
│   ├── values/                # String values, styles, colors, dimensions
│   ├── layout/                # Layout XML files
│   ├── drawable/              # Vector drawables, layer lists
│   ├── xml/                   # Preferences, searchable config, etc.
│   └── mipmap-*/              # App icons by density
├── smali/                     # Disassembled DEX bytecode (MAIN CODE)
│   ├── com/
│   │   └── example/
│   │       └── app/
│   │           ├── MainActivity.smali
│   │           └── ...
│   └── android/
│       └── ...
└── smali_classes2/            # Additional DEX files (multi-dex apps)
    └── ...
```

### 2.4 Smali Editing Basics

Smali is a human-readable representation of DEX bytecode. Key patterns you'll encounter:

```smali
# Class declaration
.class public Lcom/example/app/MainActivity;
.super Landroidx/appcompat/app/AppCompatActivity;

# Method declaration
.method public onCreate(Landroid/os/Bundle;)V
    .registers 4
    
    # Calling super
    invoke-super {p0, p1}, Landroidx/appcompat/app/AppCompatActivity;->onCreate(Landroid/os/Bundle;)V
    
    # Setting a field
    const-string v0, "patched_value"
    iput-object v0, p0, Lcom/example/app/MainActivity;->mStatus:Ljava/lang/String;
    
    # Conditional check
    if-eqz v0, :cond_skip
    # ... code ...
    :cond_skip
    return-void
.end method

# Common patches:

# 1. Force a boolean method to always return true
.method public isPremium()Z
    .registers 2
    const/4 v0, 0x1        # true
    return v0
.end method

# 2. NOP out a method call (comment effect by replacing with nop)
# Replace: invoke-virtual {v0}, Lcom/example/Payroll;->show()V
# With:    nop

# 3. Remove a permission check
# Replace: if-eqz v0, :cond_deny
# With:    nop              # always falls through
```

### 2.5 Resource Editing

Resources are stored as compiled XML (AXML) that apktool decodes. Common modifications:

```xml
<!-- res/values/strings.xml - Change app name -->
<string name="app_name">My Patched App</string>

<!-- res/values/colors.xml - Change theme colors -->
<color name="primary">#FF6200EE</color>

<!-- AndroidManifest.xml - Add permissions -->
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />

<!-- AndroidManifest.xml - Export an activity (make it launchable) -->
<activity android:name=".HiddenActivity" android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
</activity>

<!-- res/layout/activity_main.xml - Modify UI -->
<TextView
    android:id="@+id/status_text"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:text="PATCHED" />
```

---

## 3. Split APK Handling

### 3.1 Understanding Split APK Formats

Modern Play Store apps use Android App Bundles (AAB), which are split into multiple APKs:

| Format | Source | Extension | Contents |
|---|---|---|---|
| **Bundletool** | Google Play / developer tools | `.apks` | ZIP with base + splits + toc.pb (protobuf metadata) |
| **APKMirror** | APKMirror downloads | `.apkm` | Same as .apks, renamed |
| **APKPure** | APKPure downloads | `.xapk` | Similar concept, slightly different metadata |
| **Individual** | Manual extraction | `.apk` each | Each split as separate APK file |

**Split types you'll encounter**:
- `base.apk` — Core app code, shared resources, manifest
- `split_config.arm64_v8a.apk` — ARM64 native libraries
- `split_config.armeabi_v7a.apk` — ARMv7 native libraries
- `split_config.x86_64.apk` — x86_64 native libraries
- `split_config.xxhdpi.apk` — Screen density-specific resources
- `split_config.en.apk` — Language-specific resources
- `split_config.google_apis.apk` — Google APIs integration code
- `split_config.firebase.apk` — Firebase integration code

### 3.2 Extraction & Merging Workflow

```bash
# Step 1: Extract splits from bundle format
# .apks and .apkm are just ZIP files
mkdir splits/ && cd splits/
unzip ../input.apks          # or .apkm
# This produces: base.apk, split_config.*.apk, toc.pb, etc.

# For .xapk, same approach:
unzip ../input.xapk

# Step 2: Merge into a single "fat APK" using APKEditor
java -jar APKEditor.jar m -i base.apk split_config.arm64_v8a.apk \
    split_config.xxhdpi.apk split_config.en.apk -o merged.apk

# APKEditor intelligently merges resource tables from all splits.
# The resulting merged.apk is self-contained for decompilation.

# Step 3: Decompile the merged APK
apktool d merged.apk -o decompiled/ -f

# Step 4: Make your modifications (smali, resources, manifest)

# Step 5: Recompile
apktool b decompiled/ -o modified_base.apk

# Step 6: Align and sign (see Section 4)
zipalign -v -p 4 modified_base.apk modified_base_aligned.apk
apksigner sign --ks ~/.android/debug.keystore \
    --ks-pass pass:android --key-pass pass:android \
    modified_base_aligned.apk
```

### 3.3 Re-installing Modified Split APKs

**Option A: Replace base APK only (recommended when possible)**

If you only modified the base APK (most common scenario), you can keep the original split APKs:

```bash
# Uninstall the app first (signature mismatch will block update)
adb uninstall com.example.app

# Install base + original splits together
adb install-multiple modified_base_aligned.apk \
    splits/split_config.arm64_v8a.apk \
    splits/split_config.xxhdpi.apk \
    splits/split_config.en.apk
```

**Option B: Re-sign ALL APKs with the same key**

If splits fail because of signature mismatch (some splits embed signature checks):

```bash
# Sign every APK with the same keystore
for apk in modified_base_aligned.apk splits/split_config.*.apk; do
    apksigner sign --ks ~/.android/debug.keystore \
        --ks-pass pass:android --key-pass pass:android \
        "$apk"
done

# Install all at once
adb install-multiple modified_base_aligned.apk splits/split_config.*.apk
```

**Option C: Create a new bundle for distribution**

```bash
# Create .apks bundle using bundletool
java -jar bundletool.jar build-bundle \
    --modules=modified_base_aligned.apk,splits/split_config.arm64_v8a_apk \
    --output=patched.apks
```

### 3.4 Split APK Pitfalls

| Pitfall | Description | Fix |
|---|---|---|
| Missing native libs after merge | APKEditor may not merge all `lib/` directories from arch splits | Manually copy missing `.so` files into merged APK's `lib/` before decompiling |
| Resource conflicts during merge | Two splits define same resource ID with different values | Merge only base + arch split first, then add density/language splits one at a time |
| `toc.pb` metadata mismatch | Modified APK doesn't match original bundle metadata | Don't use bundletool for installation — use `adb install-multiple` directly |
| Feature module splits | Some splits contain code (not just resources) | Decompile the feature split separately, understand its code, and merge smali directories |
| Base APK decompilation produces `null` resources | Known apktool issue with some split APK bases | Merge with APKEditor first, or use `--ignore-missing-resources` flag |

---

## 4. Signing: Schemes, Pitfalls, and Fix Procedures

### 4.1 APK Signature Schemes Explained

| Scheme | Since | Mechanism | Tamper Resistance |
|---|---|---|---|
| **v1 (JAR signing)** | API 1 (all Android) | Signs individual file entries inside `META-INF/` | **Weak** — can strip and re-sign without app knowing |
| **v2 (APK Signature Scheme v2)** | API 24 (Android 7.0) | Binary signature block before ZIP central directory; verifies entire APK | **Strong** — any byte modification (even metadata) invalidates it |
| **v3 (APK Signature Scheme v3)** | API 28 (Android 9.0) | Same as v2 + supports **key rotation** via proof-of-rotation lineage | Same integrity + allows changing signing keys |
| **v4 (APK Signature Scheme v4)** | API 30 (Android 11) | Merkle hash tree stored separately; enables streaming verification during incremental installs | Same integrity + incremental install support |

**Critical rule**: v2/v3 are **whole-APK signatures**. Modifying even a single byte of smali code, a single resource string, or even the ZIP comment field invalidates them. This is why every recompilation requires a full re-sign.

**Android verification order**: v4 → v3 → v2 → v1 (falls back through each level).

### 4.2 apksigner vs jarsigner — Why jarsigner Is Dead

| Feature | apksigner | jarsigner |
|---|---|---|
| Signature schemes | v1, v2, v3, v4 | **v1 only** |
| Whole-APK verification | Yes | No |
| Key rotation support | Yes (v3) | No |
| Required for API 24+ | **Yes** | **No — will be rejected** |
| Alignment awareness | Yes | No |
| Source | Android SDK Build Tools | JDK |

**NEVER use jarsigner for APK signing.** Period. It produces v1-only signatures that modern Android (7.0+) silently rejects or explicitly denies installation.

### 4.3 Proper Signing Procedure

```bash
# === Creating a Custom Keystore (one-time) ===
keytool -genkey -v -keystore ~/release.keystore \
    -alias myapp \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000
# You'll be prompted for:
# - Keystore password (use something STRONG and memorable)
# - Key password (same or different)
# - Your name, organization, city, state, country code
# Store the keystore and passwords securely — you CANNOT change the key later

# === Using the Android Debug Keystore (for testing only) ===
# Location: ~/.android/debug.keystore
# Password: android
# Alias: androiddebugkey
# This keystore is identical on ALL Android SDK installations.
# DO NOT use for production — apps signed with it cannot be published or updated.

# === Full Signing Workflow ===

# Step 1: Align the APK (MUST be before signing)
zipalign -v -p 4 rebuilt.apk rebuilt_aligned.apk

# Step 2: Sign with apksigner (all three schemes for maximum compatibility)
apksigner sign \
    --ks ~/release.keystore \
    --ks-key-alias myapp \
    --ks-pass pass:your_keystore_password \
    --key-pass pass:your_key_password \
    --v1-signing-enabled true \
    --v2-signing-enabled true \
    --v3-signing-enabled true \
    rebuilt_aligned.apk
# Note: v4 is NOT signed here — it's computed on-demand during installation

# Step 3: Verify the signature
apksigner verify --verbose --print-certs rebuilt_aligned.apk
# Expected output:
# Verifies
# Verified using v1 scheme (JAR signing): true
# Verified using v2 scheme (APK Signature Scheme v2): true
# Verified using v3 scheme (APK Signature Scheme v3): true
# Number of signers: 1

# Step 4: Optional — Check what schemes are present
apksigner verify --print-certs -v rebuilt_aligned.apk
```

### 4.4 Signature-Related Failures and Fixes

| Error Message | Root Cause | Fix |
|---|---|---|
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | App already installed with different signing key | `adb uninstall com.example.app` then reinstall |
| `INSTALL_PARSE_FAILED_NO_CERTIFICATES` | APK not signed at all | Sign with `apksigner` |
| `INSTALL_FAILED_VERIFICATION_FAILURE` | Device requires verified installs (MIUI, Samsung Knox) | Disable MIUI optimization, or enable "Install via USB" in Developer Options |
| App installs but immediately crashes | Runtime signature self-check (`PackageManager.getPackageInfo()` with `GET_SIGNATURES`) | See Section 9.3 (Frida signature bypass) or patch smali signature check |
| `SecurityException: Signature not valid` | App explicitly checks caller signature | Patch the smali signature check, or use signature spoofing (see 6.4) |
| `INSTALL_FAILED_INVALID_APK` | APK corrupted or malformed after recompilation | Check for AAPT2 errors during build, verify zip integrity |
| Play Store says "App not installed" | Custom signature not recognized by Play Store | **Expected** — Play Store only accepts Google-signed updates for apps it manages |
| Splits fail with `INSTALL_FAILED_SESSION_INVALID` | Splits signed with different keys | Sign ALL splits with the same keystore before `install-multiple` |

### 4.5 Key Rotation with v3 Signing

If you need to change signing keys (e.g., you lost your keystore):

```bash
# Sign with the NEW key, providing the OLD key's lineage
apksigner sign \
    --ks new-release.keystore \
    --ks-key-alias newkey \
    --ks-pass pass:new_password \
    --v1-signing-enabled true \
    --v2-signing-enabled true \
    --v3-signing-enabled true \
    --lineage /path/to/lineage-file \
    rebuilt_aligned.apk

# To extract lineage from the OLD keystore:
apksigner sign \
    --ks old-release.keystore \
    --ks-key-alias oldkey \
    --ks-pass pass:old_password \
    --v3-signing-enabled true \
    --lineage /path/to/lineage-file \
    --next-signer new-release.keystore newkey pass:new_password \
    dummy.apk
```

**Caveat**: Key rotation only works if the app was PREVIOUSLY signed with v3. If the original app only has v1/v2, you're out of luck — you must uninstall and reinstall.

---

## 5. Dependency Hell: Frameworks, AndroidX, OEM Resources

### 5.1 Common Resource Dependency Errors

```
# Error 1: Missing AndroidX resources
error: resource 'com.example:id/material_textinput' not found

# Error 2: Styleable attribute not found
error: style attribute 'attr/layout_constraintBaseline_toBaselineOf' not found

# Error 3: AAPT2 crash
ERROR: AAPT2 aapt2(...) exited with code 1
brut.androlib.AndrolibException

# Error 4: Duplicate resource
error: resource 'style/Theme.MaterialComponents' has already been defined

# Error 5: Missing framework resource
error: resource '@android:configui_configFlags' not found
```

### 5.2 Systematic Dependency Resolution

**Step 1: Install ROM-specific frameworks**

For most third-party apps, Apktool's bundled framework (since 2.5.0) is sufficient. But for system apps, OEM apps, or apps that reference framework resources not in AOSP, you need:

```bash
# Install the standard Android framework (usually automatic)
apktool if framework-res.apk

# Pull framework files from a rooted device
adb pull /system/framework/ ./device_frameworks/

# Install OEM-specific frameworks
# Samsung:
apktool if device_frameworks/sec_platform_library.jar
apktool if device_frameworks/com.samsung.device.jar
apktool if device_frameworks/frameworksSamsungSDK.jar

# Xiaomi/MIUI:
apktool if device_frameworks/framework-miui-res.apk
apktool if device_frameworks/MiuiSdk.jar
apktool if device_frameworks/framework-mi.jar

# Huawei:
apktool if device_frameworks/HWExtension.jar
apktool if device_frameworks/hwsdk.jar

# OnePlus/Oplus:
apktool if device_frameworks/oplus-framework.jar
apktool if device_frameworks/oplus-res.apk

# Check what frameworks are currently installed
ls ~/.local/share/apktool/framework/
```

**Step 2: Install shared library APKs**

Some apps depend on vendor-shared library APKs:

```bash
# Find shared library APKs on device
adb shell pm list packages -f | grep shared
adb shell pm list packages -f | grep library

# Pull and install as framework
adb pull /system/app/SomeSharedLib/SomeSharedLib.apk
apktool if SomeSharedLib.apk
```

**Step 3: Force API level to resolve resource conflicts**

```bash
# If resources from newer APIs aren't found
apktool d target.apk -o out/ -f --api 35

# If dealing with legacy frameworks
apktool d target.apk -o out/ -f --api 29
```

**Step 4: Use the ignore flag for known non-critical missing resources**

```bash
# New in Apktool 2.11.x
apktool d target.apk -o out/ -f --ignore-missing-resources
```

### 5.3 AndroidX-Specific Issues

**Issue A: Cross-library resource references**

AndroidX migrated all `android.support.*` classes to `androidx.*` namespaces. This causes two major categories of issues:

- **Cross-library resource references**: AndroidX libraries reference resources across package boundaries. When decompiled, these may resolve incorrectly.
- **R8-obfuscated resource names**: When R8 shrinks an app, it may remove unused AndroidX resources. On recompilation, the remaining code may reference resources that were stripped.

**Fix**: Ensure Apktool 2.11.0+ is used (correctly handles AndroidX cross-references). For R8-obfuscated apps, manually add the required library `.aar` files as frameworks.

**Issue B: Obfuscation**

R8/ProGuard/DexGuard can strip resources. This is extremely hard to resolve automatically—your best options are:
1. Decompile the original APK without modification and immediately recompile (if that fails too, it's a tool limitation)
2. Manually add the missing resource definition to `res/values/` files
3. Use `--ignore-missing-resources` and accept that some features may break

### 5.4 AAPT2 Error Catalog

| Error | Cause | Fix |
|---|---|---|
| `resource has already been defined` | Duplicate resource entry in AAPT2 | Apktool 2.11.0+ handles most cases. If persists, search for duplicate definitions in `res/values/*.xml` |
| `failed to compile values files` | Style/attr references to undefined resources | Check `attrs.xml`, `styles.xml`, `themes.xml` for references to removed resources |
| `malformed compiled jar` | Samsung DEX format 039 in framework | `apktool d -api 29` |
| `no resource identifier found for attribute` | Missing library dependency | Install the required library APK as framework |
| `invalid file path` | Windows path length limit or special characters in resources | Move project to short path, rename files |
| `unmarshalling resource table` | Corrupted `resources.arsc` in original APK | Try `--ignore-missing-resources`, or use APKEditor to decompile instead |
| `Error: java.nio.BufferOverflowException` | Very large resource table (>2GB) | Use 64-bit Java and increase heap: `JAVA_OPTS="-Xmx4g" apktool b ...` |

---

## 6. GApps-Dependent APKs: Patching & Workarounds

### 6.1 The GApps Dependency Problem

Apps that depend on Google Play Services are the hardest to patch because:

1. **Split APK hell**: Play Services is distributed as ~100+ dynamic feature modules via split APKs
2. **Runtime signature verification**: Both the OS and other GApps verify Play Services' signature at runtime
3. **DroidGuard attestation**: Google's attestation service is deeply integrated into Play Services core
4. **Automatic updates**: The Play Store auto-updates Play Services, overwriting any patches
5. **Play Integrity API**: Modern apps use Play Integrity to verify device and app integrity — impossible to fully bypass on emulators

**Bottom line**: Do NOT try to directly patch `com.google.android.gms`. It's a losing battle. Instead, use the approaches in the following sections.

### 6.2 Strategy 1: MicroG (Recommended for GApps-Free Patching)

MicroG is a lightweight, open-source replacement for Google Play Services.

```bash
# MicroG provides:
# - Location services (via UnifiedNlp / OpenStreetMap backends)
# - Push notifications (via ntfy or custom push servers)
# - Device registration
# - Maps API (via OpenStreetMap)
# - Limited Google account support

# MicroG does NOT provide:
# - Play Integrity passing
# - Full DroidGuard attestation
# - SafetyNet compatibility
# - All Google API parity
# - Some Play Games features

# Setup MicroG:
# 1. Download GmsCore.apk from https://github.com/microg/GmsCore/releases
#    Or use "MicroG RE" (Redesign for ReVanced) for better compatibility
# 2. Install on your device/emulator
# 3. Install a push notification provider (e.g., ntfy)
# 4. Configure signature spoofing (see 6.4)
```

### 6.3 Strategy 2: Patching Individual GApps (YouTube, Maps, etc.)

**ReVanced** (the successor to Vanced) provides pre-made patches:
- https://github.com/ReVanced/revanced-patches
- Patches for: YouTube, YouTube Music, Google Photos, etc.
- Handles signature bypass, ad removal, background play, etc.

**Manual patching of GApps**:

The key challenge: GApps perform runtime signature verification. They check their own signature against a known Google certificate fingerprint and refuse to function if the signature doesn't match.

```bash
# The patching approach:

# 1. Decompile the app
apktool d google_app.apk -o decompiled/

# 2. Find the signature verification code
# Search smali for these patterns:
#   getPackageInfo
#   GET_SIGNATURES
#   PackageManager
#   MessageDigest
#   equals      (for signature comparison)
#   toByteArray (for signature byte extraction)

# 3. Patch or NOP the signature check
# Common pattern in smali:
#   const-string v0, "308203e3..."
#   invoke-virtual {v0}, Ljava/lang/String;->getBytes()[B
#   invoke-static {...}, Ljava/security/MessageDigest;->getInstance(...)L...
#   # Replace with: const/4 v_result, 0x1  (return true/valid)
```

### 6.4 Strategy 3: Signature Spoofing

**What it does**: Makes MicroG's signature appear as the real Google Play Services signature to other apps.

**ROM-level support** (cleanest approach):
- LineageOS: Settings → System → Developer options → "Allow signature spoofing"
- AXP.OS, /e/OS, CalyxOS: Built-in with per-app control

**Magisk module approach** (for stock ROMs):
- Patches `framework.jar` at runtime to allow apps to declare spoofing support
- MicroG declares spoofing support in its manifest
- Other apps query MicroG's signature and receive Google's signature bytes

```bash
# Install signature spoofing Magisk module:
# Search for "FakeGApps" or "sigspoof" in Magisk Modules repository
# Or use: https://github.com/microg/android_packages_apps_GmsCore/wiki/Installation
```

### 6.5 Strategy 4: Play Integrity Bypass (2025 State)

| Tool | Type | Works On | Status |
|---|---|---|---|
| **TrickyStore** | Magisk module | Android 8+ (with Zygisk) | Active — spoofs device attestation key |
| **Play Integrity Fix NEXT** | Magisk module | Android 8+ (with Zygisk) | Active — aims for valid attestation |
| **PIFork** | Magisk module | Pre-Android 13 | Active fork by osm0sis |

**Stack for passing Play Integrity (2025)**:
1. Root via Magisk / KernelSU / APatch
2. Install ZygiskNext
3. Install Play Integrity Fix (or NEXT/fork)
4. Install TrickyStore + TrickyStore Addon
5. Do NOT put `com.google.android.gms` on Magisk DenyList

**CRITICAL LIMITATION**: Play Integrity does NOT pass on any emulator. Emulators are detected via hardware attestation checks that cannot be spoofed in software. For Play Integrity testing, you MUST use a physical device.

---

## 7. Testing Without a Physical Device

### 7.1 Emulator Selection Matrix

| Emulator | Root Support | ARM Translation | GApps Support | Best For | Verdict |
|---|---|---|---|---|---|
| **Android Studio AVD** | Magisk via rootAVD | Native (ARM images) / Translated (x86) | Google APIs / Google Play images | Dev, security testing, patch verification | **Best choice** |
| **Genymotion** | Built-in basic root | libhoudini (not included by default since 3.x) | Requires manual GApps flash | Professional CI/CD testing | Good for automated testing |
| **Waydroid** | Magisk via script | libndk_translation (SSE 4.2 required) | Manual via waydroid_script | Linux desktop Android apps | Good for Linux users |
| **BlueStacks** | Difficult, no Magisk | Built-in | Pre-installed | Gaming only | **Not recommended** for dev work |
| **Nox** | Clunky, unreliable | Built-in | Partial | Gaming/automation | **Not recommended** for dev work |

### 7.2 Setting Up Android Studio AVD for APK Testing

```bash
# Step 1: Install Android Studio
# Download from https://developer.android.com/studio

# Step 2: Create an AVD (Virtual Device)
# Android Studio → Tools → Device Manager → Create Device
# Recommended configuration:
# - Device: Pixel 7 (or any recent phone profile)
# - System Image: API 35 (Android 15), x86_64 (for speed)
#   OR ARM64 if testing ARM-specific native libs
# - RAM: 4096 MB minimum (8192 MB preferred)
# - AVD Name: "test_device_api35"

# Step 3: Root the AVD with rootAVD
pip3 install rootAVD
rootAVD -s test_device_api35  # Root by AVD name

# Step 4: Verify root
emulator -avd test_device_api35 -no-snapshot-load
adb shell su -c "id"
# Expected: uid=0(root) gid=0(root)

# Step 5: Install Magisk modules (if needed)
# Push module zip to device and flash via Magisk app
adb push module.zip /sdcard/Download/
# Then flash in Magisk Manager app on the emulator

# Step 6: Install your patched APK
adb install -r patched.apk

# For split APKs:
adb install-multiple base.apk split_config.arm64_v8a.apk split_config.en.apk

# Force downgrade if version conflict:
adb install -r -d -t patched.apk

# Clean install if signature mismatch:
adb uninstall com.example.app
adb install patched.apk
```

### 7.3 GApps Testing on Emulator

**Option A: AVD with Google APIs image**

```bash
# Create AVD with "Google APIs" system image
# Android Studio → Device Manager → Create Device
# Choose system image: "Google APIs" (not "Google Play")
# This includes Play Services but allows more flexibility

# Caveat: Pre-installed Google Play Services CANNOT be replaced
# with patched versions because the system expects Google's signature
```

**Option B: AVD without Google APIs + MicroG (recommended for GApps-free testing)**

```bash
# Create AVD with "No Google APIs" / AOSP system image
# This gives you a clean slate

# Install MicroG:
adb install GmsCore.apk
adb install ntfy.apk  # Push notification provider

# Install your patched app:
adb install patched.apk

# Verify MicroG self-check:
# Open MicroG app → Self-check → All should be green (except Play Integrity)
```

### 7.4 x86 vs ARM Translation Issues

**Android Studio AVD**:
- **x86_64 images**: ~10x faster than ARM emulation. Uses native x86 execution.
- **ARM64 images**: Slower but runs ARM native libraries directly.
- **ARM translation**: When running x86_64 image with ARM APKs, the emulator translates ARM instructions to x86 transparently.
- **Problem**: Some native libraries (anti-tamper, anti-debug, DRM) detect the translation layer and refuse to run.
- **Fix**: Use ARM64 system images when testing apps with ARM-specific native code that performs translation detection.

**Genymotion**:
- Runs x86 images by default
- libhoudini for ARM translation (not included since Genymotion 3.x)
- Install via: https://github.com/vnsh01/Nyx (for Android 11)
- macOS Apple Silicon devices don't need translation (native ARM64)

**Waydroid**:
- Uses host Linux kernel directly (container, not emulation)
- ARM translation via libndk_translation
- Requires SSE 4.2 CPU instructions
- Install via waydroid_script: https://github.com/casualsnek/waydroid_script

### 7.5 Frida Setup on Emulator

```bash
# Install Frida tools
pip install frida-tools

# Download frida-server for the emulator's architecture
# Check architecture: adb shell getprop ro.product.cpu.abi
# For x86_64 emulator: download frida-server-x86_64.xz
# For arm64 emulator: download frida-server-arm64.xz

# Push and run frida-server
adb push frida-server /data/local/tmp/
adb shell "chmod 755 /data/local/tmp/frida-server"
adb shell "/data/local/tmp/frida-server -D &"

# Verify connection
frida-ps -U  # Should list running processes

# Run Frida REPL against a running app
frida -U -n com.example.app

# Spawn app with Frida injected
frida -U -f com.example.app -l hook.js --no-pause

# Run a JavaScript hook script
frida -U -l bypass_signature.js -n com.example.app
```

### 7.6 ADB Commands Reference for Testing

```bash
# === Installation ===
adb install -r app.apk              # Replace existing app
adb install -d app.apk              # Allow version downgrade
adb install -t app.apk              # Allow test APKs
adb install-multiple base.apk s1.apk s2.apk  # Split APKs
adb uninstall com.example.app       # Remove app + data

# === Debugging ===
adb logcat                          # View logs
adb logcat -s "ActivityManager"     # Filter by tag
adb logcat | grep -i "FATAL"        # Filter crash logs
adb shell dumpsys package com.example.app  # Package info

# === File operations ===
adb push file.txt /sdcard/          # Upload file
adb pull /sdcard/file.txt ./        # Download file

# === Root operations ===
adb shell su -c "command"           # Run as root
adb shell su -c "mount -o rw,remount /system"
adb push patched.apk /system/app/TargetApp/target.apk
adb shell su -c "chmod 644 /system/app/TargetApp/target.apk"

# === Emulator-specific ===
emulator -avd NAME -no-snapshot-load  # Start emulator fresh
adb reboot                          # Reboot emulator
```

### 7.7 ADB Install Flags Reference

| Flag | Meaning | Use Case |
|---|---|---|
| `-r` | Replace/reinstall existing app | Updating a patched APK |
| `-d` | Allow version downgrade | Installing older patched version |
| `-t` | Allow test APKs (`android:testOnly="true"`) | Debug/test builds |
| `-g` | Grant all runtime permissions | Testing with all permissions |
| `--force-install` | Force install (Android 13+) | Bypass signature/version checks |
| `-p` | Partial install (split APK mode) | Internal use for install-multiple |

---

## 8. Local Testing: Redroid & Waydroid

### 8.1 Signing for Local Testing: Everything You Need to Know

#### 8.1.1 The Debug Keystore (Quick & Dirty)

```
Location:  ~/.android/debug.keystore
Password:  android
Alias:     androiddebugkey
Key pass:  android
```

**When to use**: Local-only testing on redroid, Waydroid, your own devices, emulators.

**When NOT to use**: Distributing APKs to others, publishing to Play Store.

#### 8.1.2 Custom Keystore for Reproducible Signing

```bash
# One-time creation
keytool -genkey -v \
    -keystore ~/apk-testing.keystore \
    -alias testing \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000

# You'll be prompted for:
# - Keystore password (use something STRONG and memorable)
# - Key password (same or different)
# - Your name, organization, city, state, country code
# 
# BACKUP THIS FILE. If you lose it, you'll have to uninstall and reinstall every app you ever signed.
```

#### 8.1.3 The Critical Order: zipalign THEN sign

```bash
# CORRECT ORDER:
zipalign -v -p 4 rebuilt.apk rebuilt_aligned.apk    # Step 1: ALIGN first
apksigner sign --ks key.keystore aligned.apk        # Step 2: SIGN second

# WRONG ORDER (will break v2/v3 signatures):
apksigner sign --ks key.keystore rebuilt.apk          # Signing first
zipalign -v -p 4 rebuilt.apk aligned.apk              # Then aligning BREAKS the signature!
```

**Why**: v2/v3 signatures are computed over the entire APK binary, including the position of entries within the ZIP. `zipalign` moves entries around to 4-byte boundaries, which invalidates any signature computed before alignment.

#### 8.1.4 Signing Split APKs with the Same Key

When testing split APKs on redroid/Waydroid, ALL splits in a bundle must share the same signing key:

```bash
# Extract splits from .apks/.apkm
unzip input.apks -d splits/

# Align all APKs
for apk in splits/*.apk; do
    zipalign -v -p 4 "$apk" "${apk%.apk}_aligned.apk"
done

# Sign ALL splits with THE SAME key
for apk in splits/*_aligned.apk; do
    apksigner sign \
        --ks ~/apk-testing.keystore \
        --ks-key-alias testing \
        --ks-pass pass:your_password \
        --key-pass pass:your_password \
        "$apk"
done

# Install all at once via ADB
adb install-multiple splits/base_aligned.apk \
    splits/split_config.arm64_v8a_aligned.apk \
    splits/split_config.en_aligned.apk
```

#### 8.1.5 uber-apk-signer: All-in-One Alternative

If you want to skip the manual zipalign + apksigner dance:

```bash
# Download from https://github.com/patrickfav/uber-apk-signer/releases
java -jar uber-apk-signer.jar --apks rebuilt.apk
# Handles: zipalign + sign with debug keystore + verify
# Output: rebuilt-aligned-debugSigned.apk

# With custom keystore
java -jar uber-apk-signer.jar \
    --apks rebuilt.apk \
    --ks ~/apk-testing.keystore \
    --ksAlias testing \
    --ksPass your_password

# Sign multiple APKs at once (splits)
java -jar uber-apk-signer.jar --apks splits/
```

#### 8.1.6 Common Signing Mistakes & Symptoms

| Mistake | What Happens | Fix |
|---|---|---|
| zipalign AFTER sign | `INSTALL_FAILED_VERIFICATION` | Always zipalign first |
| Used jarsigner instead of apksigner | v2/v3 signatures missing; Android 7.0+ rejects | Use `apksigner` |
| Split APKs signed with different keys | `INSTALL_FAILED_SESSION_INVALID` | Sign ALL with same keystore |
| Modified APK after signing | Signature broken | Never modify post-sign |
| Wrong keystore password | `Keystore was tampered with, or password was incorrect` | Verify with `keytool -list` |
| Not aligned at all | App installs but runs slow; `INSTALL_PARSE_FAILED_UNEXPECTED_EXCEPTION` on some ROMs | Always run `zipalign -v -p 4` |
| Missing v2 scheme on API 24+ | Silent rejection or `INSTALL_PARSE_FAILED_NO_CERTIFICATES` | apksigner defaults to v1+v2; verify with `apksigner verify -v` |

### 8.2 Redroid: Android in Docker for Headless APK Testing

#### 8.2.1 What Is Redroid?

Redroid (Remote-android) runs a full Android system inside a Docker container. It does NOT use QEMU or virtualization — it runs Android userspace **natively** on the host Linux kernel using LXC primitives.

**Key characteristics**:
- Runs as a Docker container — fully containerized, reproducible, scriptable
- Root by default (uid=0 inside the container)
- ADB access via TCP on port 5555
- No display by default (headless) — use scrcpy for screen mirroring if needed
- Supports Android 11 through 15
- Perfect for CI/CD, batch testing, and automated APK validation

**Official resources**:
- Docs: https://github.com/remote-android/redroid-doc
- Docker Hub: https://hub.docker.com/r/redroid/redroid
- Kernel modules: https://github.com/remote-android/redroid-modules

#### 8.2.2 Prerequisites & Kernel Setup

```bash
# 1. Install Docker
sudo apt install docker.io docker-compose
sudo usermod -aG docker $USER   # Log out and back in

# 2. Install binder kernel module
sudo apt install linux-modules-extra-$(uname -r)

# 3. Load binder module
sudo modprobe binder_linux

# 4. Verify binder is available
ls /dev/binderfs 2>/dev/null && echo "OK: binderfs found" || echo "MISSING"

# 5. For Android 12+: ashmem is replaced by memfd (no extra module needed)
# For Android 11: also load ashmem
sudo modprobe ashmem_linux
```

**Kernel version requirement**: 4.14+ (virtually all modern distros satisfy this).

**WSL2 support**: Possible but requires a custom WSL2 kernel with binder modules. See https://github.com/remote-android/redroid-doc/blob/master/deploy/wsl.md. macOS is NOT directly supported (Docker Desktop on macOS lacks binder).

#### 8.2.3 Basic Docker Setup

**Minimal headless container** (for pure APK install/run testing):

```bash
docker run -d \
    --privileged \
    --name redroid14 \
    -p 5555:5555 \
    redroid/redroid:14.0.0-latest
```

**With GPU acceleration** (Intel/AMD via Mesa/virgl):

```bash
docker run -d \
    --privileged \
    --name redroid14 \
    -p 5555:5555 \
    -v /dev/dri:/dev/dri \
    redroid/redroid:14.0.0-latest \
    androidboot.redroid_width=1080 \
    androidboot.redroid_height=1920 \
    androidboot.redroid_dpi=320
```

**With persistent data** (apps survive container restart):

```bash
docker volume create redroid_data

docker run -d \
    --privileged \
    --name redroid14 \
    -p 5555:5555 \
    -v /dev/dri:/dev/dri \
    -v redroid_data:/data \
    redroid/redroid:14.0.0-latest \
    androidboot.redroid_width=1080 \
    androidboot.redroid_height=1920 \
    androidboot.redroid_dpi=320
```

**Docker Compose** (recommended for reproducible setups):

```yaml
# docker-compose.yml
services:
  redroid:
    image: redroid/redroid:14.0.0-latest
    container_name: redroid14
    privileged: true
    ports:
      - "5555:5555"
    volumes:
      - /dev/dri:/dev/dri
      - redroid_data:/data
    command:
      - "androidboot.redroid_width=1080"
      - "androidboot.redroid_height=1920"
      - "androidboot.redroid_dpi=320"

volumes:
  redroid_data:
```

```bash
docker compose up -d      # Start
docker compose logs -f    # View boot logs (wait for "Boot completed")
docker compose down       # Stop
```

#### 8.2.4 Available Docker Image Tags

| Tag | Android | Notes |
|---|---|---|
| `redroid/redroid:11.0.0-latest` | 11 | Stable, legacy |
| `redroid/redroid:12.0.0-latest` | 12 | Stable |
| `redroid/redroid:13.0.0-latest` | 13 | Stable |
| `redroid/redroid:14.0.0-latest` | 14 | **Recommended** — most stable |
| `redroid/redroid:15.0.0-latest` | 15 | Newer, check stability |
| `redroid/redroid:14.0.0_64only-latest` | 14 | 64-bit only (smaller, fewer compat issues) |
| `erstt/redroid` | Various | Pre-built with ARM translation |

#### 8.2.5 ADB Connection & APK Installation

```bash
# Wait for container to boot (check logs: "Boot completed")
docker logs redroid14 2>&1 | tail -5

# Connect ADB via TCP
adb connect localhost:5555
adb devices
# Expected: localhost:5555    device

# === Install patched APK ===
# Basic install
adb -s localhost:5555 install rebuilt_aligned.apk

# Reinstall over existing
adb -s localhost:5555 install -r rebuilt_aligned.apk

# Force install (bypass version/signature conflicts)
adb -s localhost:5555 install -d -t --force-install rebuilt_aligned.apk

# Install split APKs
adb -s localhost:5555 install-multiple base_aligned.apk \
    split_config.arm64_v8a_aligned.apk \
    split_config.xxhdpi_aligned.apk

# Grant all runtime permissions
adb -s localhost:5555 install -r -g rebuilt_aligned.apk

# === App management ===
adb -s localhost:5555 shell pm list packages          # List all
adb -s localhost:5555 shell pm list packages -3       # Third-party only
adb -s localhost:5555 uninstall com.example.app        # Remove
adb -s localhost:5555 shell am force-stop com.example.app  # Force stop
adb -s localhost:5555 shell am start -n com.example.app/.MainActivity  # Launch

# === Shell access (root by default!) ===
adb -s localhost:5555 shell
whoami   # root
id       # uid=0(root) gid=0(root)

# === Screen mirroring (if you need to see the UI) ===
# Use scrcpy (install: sudo apt install scrcpy)
scrcpy -s localhost:5555
```

#### 8.2.6 GApps, Magisk & ARM Translation on Redroid

All three can be installed via [redroid-script](https://github.com/abing7k/redroid-script) without rebuilding the Docker image:

```bash
git clone https://github.com/abing7k/redroid-script.git
cd redroid-script

# Install everything in one go
sudo python3 redroid-script.py redroid14 --gapps --magisk --libndk

# Or individually:
sudo python3 redroid-script.py redroid14 --gapps    # OpenGApps
sudo python3 redroid-script.py redroid14 --magisk   # Magisk
sudo python3 redroid-script.py redroid14 --libndk   # ARM translation (libndk_translation)
sudo python3 redroid-script.py redroid14 --houdini  # ARM translation (Intel Houdini)

# Restart container after installation
docker restart redroid14
```

**Note**: Magisk installation may require 2-3 container restarts to fully initialize, especially with Zygisk enabled.

#### 8.2.7 Complete Redroid APK Testing Workflow

```bash
# === One-time setup ===
sudo modprobe binder_linux
docker volume create redroid_data
docker run -d --privileged --name redroid14 -p 5555:5555 \
    -v redroid_data:/data redroid/redroid:14.0.0-latest
# Wait ~30s for boot, then:
adb connect localhost:5555

# === GApps + ARM translation (one-time, optional) ===
git clone https://github.com/abing7k/redroid-script.git
sudo python3 redroid-script.py redroid14 --gapps --libndk
docker restart redroid14
sleep 30
adb connect localhost:5555

# === Per-APK test cycle ===
# 1. Decompile, modify, recompile (see Section 2)
apktool d target.apk -o dec/ -f
# ... make modifications ...
apktool b dec/ -o rebuilt.apk

# 2. Sign
zipalign -v -p 4 rebuilt.apk rebuilt_aligned.apk
apksigner sign --ks ~/apk-testing.keystore \
    --ks-key-alias testing --ks-pass pass:your_password \
    --key-pass pass:your_password rebuilt_aligned.apk

# 3. Uninstall previous version (if exists)
adb -s localhost:5555 uninstall com.example.app 2>/dev/null

# 4. Install
adb -s localhost:5555 install rebuilt_aligned.apk

# 5. Launch and check logs
adb -s localhost:5555 shell am start -n com.example.app/.MainActivity
adb -s localhost:5555 logcat -s "AndroidRuntime:E" "*:S"

# 6. If needed, mirror screen with scrcpy
scrcpy -s localhost:5555

# === Cleanup ===
docker stop redroid14
docker rm redroid14
docker volume rm redroid_data
```

#### 8.2.8 Redroid Known Issues

| Issue | Workaround |
|---|---|
| Container won't start (binder missing) | `sudo modprobe binder_linux` + `linux-modules-extra-$(uname -r)` |
| Apps can't access internet | Use `--net=host` in docker run |
| Long first boot on WSL2 | Store data as Docker volume (not bind mount) |
| ARM app crashes on x86 host | Install ARM translation: `redroid-script.py <id> --libndk` |
| No audio output | Expected in headless mode; use scrcpy for visual only |
| Magisk instability after install | Restart container 2-3 times |
| GPU artifacts on NVIDIA | Use software rendering (remove `-v /dev/dri:/dev/dri`) |

---

### 8.3 Waydroid: Android Container with Desktop UI

#### 8.3.1 What Is Waydroid?

Waydroid runs Android as an LXC container with native desktop window integration. Unlike redroid, it displays Android apps as regular windows on your Linux desktop. It requires a Wayland compositor (GNOME Wayland, KDE Plasma Wayland, Sway, Hyprland, etc.).

**Key characteristics**:
- Android apps appear as native desktop windows
- Clipboard sync between Linux and Android (Wayland only)
- Audio via PulseAudio/PipeWire
- Requires Wayland compositor (or nested weston for X11)
- ADB access via local socket
- Single Android session (not multi-container like redroid)

**Official resources**:
- Website: https://waydro.id
- Docs: https://docs.waydro.id
- GitHub: https://github.com/waydroid/waydroid
- ArchWiki: https://wiki.archlinux.org/title/Waydroid

#### 8.3.2 Installation

```bash
# === Ubuntu 22.04 / 24.04 ===
sudo apt install curl ca-certificates
curl https://repo.waydro.id | sudo bash
sudo apt install waydroid

# === Debian ===
curl https://repo.waydro.id | sudo bash
sudo apt install waydroid

# === Arch Linux ===
sudo pacman -S waydroid

# === Fedora ===
sudo dnf install waydroid

# === Initialize (choose one) ===
sudo waydroid init                  # Vanilla (no Google services)
sudo waydroid init -s GAPS         # With OpenGApps (Play Store etc.)

# === Start ===
waydroid session start
waydroid show-full-ui               # Opens Android desktop window
```

#### 8.3.3 GApps, Magisk & ARM Translation via waydroid_script

[casualsnek/waydroid_script](https://github.com/casualsnek/waydroid_script) is the Swiss army knife for Waydroid:

```bash
git clone https://github.com/casualsnek/waydroid_script.git
cd waydroid_script
sudo pip3 install requests pyyaml   # Dependencies

# Install everything:
sudo python3 waydroid_script.py -g -m -l
# -g = GApps (OpenGApps)
# -m = Magisk
# -l = libndk_translation (ARM translation)

# Individual options:
sudo python3 waydroid_script.py -g                  # GApps only
sudo python3 waydroid_script.py -g --variant pico   # GApps, minimal variant
sudo python3 waydroid_script.py -g --microg         # MicroG instead of OpenGApps
sudo python3 waydroid_script.py -m                  # Magisk only
sudo python3 waydroid_script.py -l                  # libndk_translation
sudo python3 waydroid_script.py -L                  # libhoudini (alternative ARM translation)

# Restart Waydroid after installation
waydroid session stop
sudo systemctl restart waydroid-container
waydroid session start && waydroid show-full-ui
```

**ARM translation critical requirement**: Your CPU must support **SSE 4.2** instruction set:

```bash
# Check
cat /proc/cpuinfo | grep sse4_2
# If empty: your CPU doesn't support it — ARM translation won't work
```

#### 8.3.4 ADB Connection & APK Installation

```bash
# Waydroid exposes ADB via local socket (auto-configured)
adb devices
# Expected: waydroid0    device

# === Install patched APK ===
# Using waydroid CLI (recommended)
waydroid app install /path/to/rebuilt_aligned.apk

# Using ADB directly
adb install /path/to/rebuilt_aligned.apk
adb install -r /path/to/rebuilt_aligned.apk           # Reinstall
adb install -d -t --force-install /path/to/app.apk    # Force

# Install split APKs via ADB
adb install-multiple base.apk split_config.arm64_v8a.apk

# === App management ===
waydroid app list                     # List installed packages
waydroid app launch com.example.app   # Launch app
waydroid app remove com.example.app   # Uninstall
waydroid app list --show-package-name # Show package names

# === Shell access ===
adb shell                              # Regular shell
sudo waydroid shell                    # Root shell (if configured)

# === Screen recording / screenshots ===
waydroid ctrl +p                       # Screenshot (shortcut, if mapped)
```

#### 8.3.5 Complete Waydroid APK Testing Workflow

```bash
# === One-time setup ===
curl https://repo.waydro.id | sudo bash
sudo apt install waydroid
sudo waydroid init   # or: sudo waydroid init -s GAPS

# Install ARM translation + Magisk
git clone https://github.com/casualsnek/waydroid_script.git
cd waydroid_script
sudo python3 waydroid_script.py -g -m -l
cd ..
waydroid session stop && sudo systemctl restart waydroid-container
waydroid session start && waydroid show-full-ui

# === Per-APK test cycle ===
# 1. Decompile, modify, recompile
apktool d target.apk -o dec/ -f
# ... make modifications ...
apktool b dec/ -o rebuilt.apk

# 2. Sign
zipalign -v -p 4 rebuilt.apk rebuilt_aligned.apk
apksigner sign --ks ~/apk-testing.keystore \
    --ks-key-alias testing --ks-pass pass:your_password \
    --key-pass pass:your_password rebuilt_aligned.apk

# 3. Uninstall previous version
waydroid app remove com.example.app 2>/dev/null

# 4. Install
waydroid app install rebuilt_aligned.apk

# 5. Launch
waydroid app launch com.example.app

# 6. Check logs
adb logcat -s "AndroidRuntime:E" "*:S"
```

#### 8.3.6 NVIDIA GPU: Known Pain Point

Waydroid relies on **Mesa/GBM** for GPU rendering. NVIDIA's proprietary driver doesn't use Mesa:

```bash
# Workaround 1: Force software rendering
WAYDROID_DISABLE_GPU=1 waydroid session start

# Workaround 2: Switch to integrated GPU (dual-GPU laptops)
# Use prime-select or DRI_PRIME=1

# Workaround 3: NVIDIA open kernel module 575.51.02+
# Recent reports (mid-2025) show Waydroid "works" with open driver
# But GPU acceleration may still be partial
```

#### 8.3.7 Waydroid Known Issues

| Issue | Workaround |
|---|---|
| NVIDIA GPU: no/flickering rendering | `WAYDROID_DISABLE_GPU=1` or switch to iGPU |
| X11: no display | Run nested Wayland: `weston &` then `WAYLAND_DISPLAY=wayland-1 waydroid show-full-ui` |
| Camera not working | Very limited support (v4l2 only, no PipeWire) |
| Magisk flaky install | Check waydroid_script version; may need manual Magisk flash |
| Bluetooth/USB not working | Not natively supported |
| Dual GPU flickering | Force iGPU only or use software rendering |
| SELinux blocks Waydroid | Set permissive: `sudo setenforce 0` (temp) or configure policy |

---

---

## 9. Advanced Patching Techniques

→ **Full reference**: [references/advanced-patching.md](references/advanced-patching.md)

This section covers:
- Dynamic instrumentation with Frida (SSL pinning bypass, root detection bypass, signature bypass)
- Dealing with obfuscation (R8/ProGuard/DexGuard)
- Bypassing app integrity checks (file hash verification, tamper detection, DEX integrity, Play Integrity)
- Creating Magisk modules as an alternative to direct patching.

---

## 10. Adding Features to an APK

→ **Full reference**: [references/adding-features.md](references/adding-features.md)

This section covers:
- Creating new smali classes from scratch
- Adding a new Activity to the app
- Adding external libraries (.jar / .aar)
- Injecting code into the app lifecycle
- Handling multi-DEX when adding code
- Practical example: Adding a "Debug Panel" to any app.

---

## 11. Delivering the APK to an End User

→ **Full reference**: [references/delivery.md](references/delivery.md)

This section covers:
- Release signing (not debug!)
- What the end user must do before installing
- Distribution methods (direct APK, .apks bundle, .apkm, ADB install)
- Preventing Play Store overwrites
- Preparing a user-friendly delivery package.

---

## 12. End-to-End Workflow: Zero to Delivery

→ **Full reference**: [references/end-to-end-workflow.md](references/end-to-end-workflow.md)

A complete checklist-driven workflow from toolchain setup to final delivery:
- Phase 1: Setup (one-time)
- Phase 2: Analysis
- Phase 3: Decompile
- Phase 4: Modify
- Phase 5: Recompile & Fix
- Phase 6: Sign & Test (Local)
- Phase 7: Prepare for Delivery
- Phase 8: Deliver
- Phase 9: Maintenance.

---

## 13. Troubleshooting: Common Failures & Solutions

→ **Full reference**: [references/troubleshooting.md](references/troubleshooting.md)

Quick reference tables for:
- Decompilation failures
- Recompilation failures
- Installation failures
- Runtime failures (app crashes after install)
- Performance issues.

---

## 14. Quick Reference Cheat Sheet

→ **Full reference**: [references/quick-reference.md](references/quick-reference.md)

Includes:
- Command summary (decompile, recompile, align, sign, install)
- Smali quick reference
- Key file paths
- Common patterns cheat sheet.


## References

- Redroid documentation: https://github.com/remote-android/redroid-doc
- Redroid Docker Hub: https://hub.docker.com/r/redroid/redroid
- Waydroid website: https://waydro.id
- Waydroid documentation: https://docs.waydro.id
- Waydroid GitHub: https://github.com/waydroid/waydroid
- casualsnek/waydroid_script: https://github.com/casualsnek/waydroid_script
