# Advanced Patching Techniques

## 9.1 Dynamic Instrumentation with Frida

Frida lets you hook Java and native functions at runtime without modifying the APK. This is invaluable for:

- Understanding app behavior before patching
- Bypassing checks at runtime to test if your static patch would work
- Analyzing encrypted/obfuscated code

### Bypass SSL Pinning

```javascript
// bypass_ssl_pinning.js
Java.perform(function() {
    // OkHttp CertificatePinner bypass
    var CertificatePinner = Java.use('okhttp3.CertificatePinner');
    CertificatePinner.check.overload('java.lang.String', 'java.util.List').implementation = function(hostname, peerCertificates) {
        console.log('[+] SSL Pinning bypassed for: ' + hostname);
    };

    // TrustManager bypass
    var X509TrustManager = Java.use('javax.net.ssl.X509TrustManager');
    var SSLContext = Java.use('javax.net.ssl.SSLContext');

    var TrustManager = Java.registerClass({
        name: 'com.bypass.TrustManager',
        implements: [X509TrustManager],
        methods: {
            checkClientTrusted: function(chain, authType) {},
            checkServerTrusted: function(chain, authType) {},
            getAcceptedIssuers: function() { return []; }
        }
    });

    var trustManagers = [TrustManager.$new()];
    var sslContext = SSLContext.getInstance('TLS');
    sslContext.init(null, trustManagers, null);
    var factory = sslContext.getSocketFactory();

    // Hook HttpsURLConnection to use our factory
    var HttpsURLConnection = Java.use('javax.net.ssl.HttpsURLConnection');
    HttpsURLConnection.setDefaultSSLSocketFactory(factory);
    HttpsURLConnection.setDefaultHostnameVerifier(Java.use('javax.net.ssl.HostnameVerifier').$new({
        verify: function(hostname, session) { return true; }
    }));
    console.log('[+] SSL Pinning fully bypassed');
});
```

### Bypass Root Detection

```javascript
// bypass_root.js
Java.perform(function() {
    // Common root detection methods to bypass

    // 1. File existence checks
    var File = Java.use('java.io.File');
    File.exists.implementation = function() {
        var path = this.getAbsolutePath();
        var rootPaths = ['/system/app/Superuser.apk', '/sbin/su', '/system/bin/su',
                        '/system/xbin/su', '/data/local/xbin/su', '/data/local/bin/su',
                        '/system/sd/xbin/su', '/system/bin/failsafe/su', '/su/bin/su'];
        if (rootPaths.indexOf(path) !== -1) {
            console.log('[*] Root detection bypassed: ' + path);
            return false;
        }
        return this.exists.call(this);
    };

    // 2. PackageManager checks for root apps
    var PackageManager = Java.use('android.app.ApplicationPackageManager');
    PackageManager.getPackageInfo.overload('java.lang.String', 'int').implementation = function(pkg, flags) {
        var rootPkgs = ['com.topjohnwu.magisk', 'eu.chainfire.supersu', 'com.koushikdutta.superuser',
                        'com.noshufou.android.su', 'com.thirdparty.superuser'];
        if (rootPkgs.indexOf(pkg) !== -1) {
            console.log('[*] Root app detection bypassed: ' + pkg);
            throw Java.use('android.content.pm.PackageManager$NameNotFoundException').$new(pkg);
        }
        return this.getPackageInfo(pkg, flags);
    };
});
```

### Bypass Runtime Signature Check

```javascript
// bypass_signature.js
Java.perform(function() {
    var targetPkg = 'com.example.app';
    var fakeSignature = '308202e3308201eba0030201020...'; // Google's cert or desired signature hex

    var PackageManager = Java.use('android.app.ApplicationPackageManager');
    PackageManager.getPackageInfo.overload('java.lang.String', 'int').implementation = function(pkg, flags) {
        var result = this.getPackageInfo(pkg, flags);

        if (pkg === targetPkg && (flags & 0x40) !== 0) {
            console.log('[*] Intercepted signature query for: ' + pkg);

            // Create fake Signature object
            var Signature = Java.use('android.content.pm.Signature');
            var hexBytes = Java.use('android.util.HexDump');
            var fakeSig = Signature.$new(
                Java.array('byte', hexBytes.hexStringToByteArray(fakeSignature))
            );
            result.signatures.value = Java.array('android.content.pm.Signature', [fakeSig]);
        }
        return result;
    };

    // Also hook GET_SIGNING_CERTIFICATES (API 28+)
    var PackageInfo = Java.use('android.content.pm.PackageInfo');
    if (PackageInfo.signatures) {
        PackageManager.getPackageInfo.overload('java.lang.String', 'android.os.PackageManager$PackageInfoFlags').implementation = function(pkg, flags) {
            var result = this.getPackageInfo(pkg, flags);
            console.log('[*] Intercepted signingInfo query for: ' + pkg);
            return result;
        };
    }
});
```

## 9.2 Dealing with Obfuscation (R8/ProGuard/DexGuard)

**R8** (default since Android Gradle Plugin 7.0) does:
- **Shrinking**: Removes unused code/resources
- **Optimization**: Optimizes bytecode
- **Obfuscation**: Renames classes/methods/fields to short names (a, b, c, etc.)
- **Desugaring**: Converts Java 8+ features to older bytecode

**Analysis strategies for obfuscated code**:

```bash
# 1. Use jadx for decompilation — handles most R8 output
jadx -d decompiled/ target.apk

# 2. Search for string constants (not obfuscated)
# URLs, API keys, package names, error messages

# 3. Use jadx's built-in deobfuscation
jadx --deobf target.apk

# 4. Use Frida to trace method calls at runtime
# Even obfuscated, the API signatures are preserved
frida -U -f com.example.app -l trace_calls.js
```

**trace_calls.js** — Trace all methods in a class:

```javascript
Java.perform(function() {
    Java.enumerateLoadedClasses({
        onMatch: function(className) {
            if (className.includes('example')) {
                console.log('[*] Found class: ' + className);
                Java.use(className).$methods.forEach(function(method) {
                    console.log('  - ' + method);
                });
            }
        },
        onComplete: function() {}
    });
});
```

## 9.3 Bypassing App Integrity Checks

Apps implement various anti-tamper mechanisms. Here's how to deal with each:

**Check 1: File hash verification**

```smali
# App computes SHA-256 of its own APK file and compares to known value
# Patch: Find the MessageDigest usage and NOP the comparison

# In smali, look for:
invoke-static {v0}, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;
# Change to: nop (won't compute hash)
```

**Check 2: Tamper detection via `PackageManager`**

```smali
# App checks if its APK path has been modified
# Look for: getSourceDir(), getApplicationInfo()
# Patch: Redirect to a cached response
```

**Check 3: DEX integrity check**

```smali
# App reads its own DEX files and verifies checksums
# Look for: openDexFile, DexFile, "/data/app/..."
# Patch: NOP the verification or return the expected hash
```

**Check 4: Google Play Integrity**

```bash
# Cannot be fully bypassed on emulator
# On physical device with root:
# Install TrickyStore + PIF NEXT + ZygiskNext
# See: 6.4 Play Integrity Bypass
```

## 9.4 Creating Magisk Modules as an Alternative

For modifications that would otherwise require system-level changes (framework patches, system app modifications, signature spoofing):

```properties
# module.prop
id=my_apk_patch
name=My APK Patch Module
version=v1.0
versionCode=1
author=YourName
description=Patches for target app
```

**RRO (Runtime Resource Overlay) for resource-only modifications**:

```xml
<!-- overlay/SystemUIOverlay/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.systemui.overlay">

    <application android:label="SystemUI Overlay">
        <overlay
            android:targetPackage="com.android.systemui"
            android:targetName="SystemUI"
            android:isStatic="true"
            android:priority="100" />
    </application>
</manifest>
```

**Replacing a system APK entirely**:

```
my_module/
├── module.prop
└── system/
    └── app/
        └── Settings/
            └── Settings.apk    # Your patched Settings APK
```

**Advantages over direct patching**:
- Systemless — doesn't modify `/system` partition
- Reversible — disable/uninstall the module
- OTA-safe — system updates don't conflict
- Works with Magisk, KernelSU, and APatch
