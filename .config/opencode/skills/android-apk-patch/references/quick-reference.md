# Quick Reference Cheat Sheet

## Command Summary

| Task | Command |
|---|---|
| **Decompile** | `apktool d app.apk -o out/ -f --api 35` |
| **Recompile** | `apktool b out/ -o rebuilt.apk` |
| **Align** | `zipalign -v -p 4 rebuilt.apk aligned.apk` |
| **Sign (testing)** | `apksigner sign --ks debug.keystore --ks-pass pass:android aligned.apk` |
| **Sign (release)** | `apksigner sign --ks release.keystore --ks-key-alias myapp --v1-signing-enabled true --v2-signing-enabled true aligned.apk` |
| **Verify** | `apksigner verify --verbose --print-certs aligned.apk` |
| **Install** | `adb install -r aligned.apk` |
| **Install splits** | `adb install-multiple base.apk split_config.arm64_v8a.apk` |
| **Connect ADB** | `adb connect localhost:5555` (for emulator) |
| **List packages** | `adb shell pm list packages` |
| **Uninstall** | `adb uninstall com.example.app` |
| **Frida bypass SSL** | `frida -U -n app -l bypass_ssl_pinning.js` |
| **Generate QR code** | `python3 -m qrcode "http://your.link/app.apk" > qr.png` |

## Smali Quick Reference

| Pattern | Meaning |
|---|---|
| `.class public Lcom/example/MyClass;` | Class declaration |
| `.method public method()V` | Void method, public |
| `.registers 2` | Total registers (this + 1 local) |
| `invoke-super {p0, p1}, SomeClass->method(LType;)V` | Call superclass method |
| `const-string v0, "text"` | String constant |
| `iput-object v0, p0, LMyClass;->field:Ljava/lang/Object;` | Set field |
| `return-object v0` | Return object |
| `return-void` | Return void |
| `if-eqz v0, :label` | If v0 == 0, goto label |
| `goto :label` | Unconditional jump |

## Key File Paths

| Purpose | Location |
|---|---|
| Main decompilation | `decompiled/smali/` (code), `decompiled/res/` (resources) |
| Custom smali classes | `decompiled/smali/com/example/patch/` |
| New activities/layouts | `decompiled/smali/com/example/patch/`, `decompiled/res/layout/` |
| External libraries | `decompiled/smali/com/example/patch/libs/` |
| Application class hook | Modify existing `MyApp.smali` or create `PatchedApplication.smali` |
