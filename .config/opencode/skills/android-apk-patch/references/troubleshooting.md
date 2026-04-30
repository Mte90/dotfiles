# Troubleshooting: Common Failures & Solutions

## 13.1 Decompilation Failures

| Symptom | Cause | Fix |
|---|---|---|
| `AAPT2` crashes with "invalid file path" | Windows path length limit or special characters | Move project to short path (e.g., `C:\proj\` or `/home/user/p/`), rename files to remove spaces/special chars |
| `resources.arsc` decompilation produces `null` | Corrupted resource table in original APK | Try `apktool d -r` (skip resources) or `apktool d --ignore-missing-resources` |
| `Smali: offset X already in use` | Multiple smali sources conflict during merge | Re-decompile the original APK cleanly, don't mix sources |
| `java.nio.BufferOverflowException` | Very large resource table (>2GB) | Use 64-bit Java: `JAVA_OPTS="-Xmx4g" apktool b ...` |

## 13.2 Recompilation Failures

| Symptom | Cause | Fix |
|---|---|---|
| `error: resource has already been defined` | Duplicate resources across merged splits | Remove duplicate from the split that's not needed; merge only base + required splits |
| `style attribute not found` | AndroidX resource mismatch | Install OEM framework with `apktool if`; ensure Apktool 2.11.0+ |
| `too many method references` | Method count exceeds 65,536 limit | Enable multi-dex (Section 10.5); use ProGuard/R8 to remove unused code before adding features |
| `unsupported DEX format` | Smali version too old | Update smali/baksmali to v3.0.9 (bundled with Apktool 2.11.0) |

## 13.3 Installation Failures

| Symptom | Cause | Fix |
|---|---|---|
| `INSTALL_PARSE_FAILED_NO_CERTIFICATES` | APK not signed | Sign with `apksigner`, not `jarsigner` |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Different signing key | Uninstall original app first |
| `INSTALL_FAILED_SESSION_INVALID` | Split APKs signed with different keys | Sign ALL splits with the SAME keystore |
| `INSTALL_PARSE_FAILED_UNEXPECTED_EXCEPTION` | Not aligned | Run `zipalign -v -p 4` BEFORE signing |
| `INSTALL_FAILED_VERIFICATION_FAILURE` | Device requires verified installs (MIUI, Samsung Knox) | Disable MIUI optimization, or use `adb install --bypass-low-target-sdk-block` |

## 13.4 Runtime Failures (App Crashes After Install)

| Symptom | Likely Cause | Diagnostic |
|---|---|---|
| `ClassNotFoundException` | Missing class in modified DEX | Check smali was compiled into correct DEX; verify package name |
| `NoSuchMethodError` | Method signature changed in new app version | Compare method signatures between original and new version |
| `VerifyError` | Invalid smali instruction or register count mismatch | Check `.registers` declaration matches usage; compare with original method |
| `Signature verification error` | App has runtime signature self-check | Use Frida to bypass (Section 9.3) or patch the check in smali |
| `Resources$NotFoundException` | Resource ID changed after recompilation | Check `R.java` equivalent; update resource references in smali |

## 13.5 Performance Issues

| Symptom | Cause | Fix |
|---|---|---|
| App runs very slowly in emulator | x86 emulator with ARM translation | Use ARM64 system image or real device |
| UI janky / dropped frames | Heavy modifications on UI thread | Move work to background threads; use `Handler`/`AsyncTask` |
| APK takes too long to install | Multi-dex with many classes | Enable instant run in Android Studio; test on API 21+ device |
