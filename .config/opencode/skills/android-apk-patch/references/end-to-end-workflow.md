# End-to-End Workflow: Zero to Delivery

## Phase 1: Setup (One-Time)

- [ ] **Install toolchain** (Section 1.3): Java 17, Apktool 2.11.0, jadx 1.5.1, APKEditor, Android SDK Build Tools (apksigner + zipalign), ADB, Frida
- [ ] **Create release keystore** (Section 11.1): `keytool -genkey` → save `~/release.keystore` somewhere safe
- [ ] **Set up testing environment** (Section 7 or 8):
  - Option A: Android Studio AVD + rootAVD
  - Option B: Redroid Docker container
  - Option C: Waydroid
- [ ] **Verify clean pipeline**: Decompile a test APK → recompile without changes → sign → install on test env → app works = tools are working

## Phase 2: Analysis

- [ ] **Analyze the target APK with jadx** (Section 2.1): `jadx-gui target.apk` — understand the architecture, find the code you need to modify
- [ ] **Note the package name** from `AndroidManifest.xml` — you'll need it for uninstall/install
- [ ] **Check if it's a split APK** (Section 3.1): Is it `.apks`, `.apkm`, `.xapk`, or a single `.apk`?
- [ ] **Identify dependencies**: Does the app use GApps? (Section 6) OEM frameworks? (Section 5.2) AndroidX libraries?
- [ ] **Plan your modifications**: Write down exactly what you'll change (smali files, resources, manifest entries, new classes)

## Phase 3: Decompile

- [ ] **For single APK**: `apktool d target.apk -o dec/ -f` (Section 2.1)
- [ ] **For split APK**: Extract → merge with APKEditor → `apktool d merged.apk -o dec/ -f` (Section 3.2)
- [ ] **If resource errors**: Try `--api 35` or `--ignore-missing-resources` flags (Section 2.2)
- [ ] **If OEM framework errors**: Install required frameworks with `apktool if` (Section 5.2)
- [ ] **Verify**: The decompiled directory should have `smali/`, `res/`, `AndroidManifest.xml`, and no error messages

## Phase 4: Modify

- [ ] **Back up the clean decompiled directory**: `cp -r dec/ dec_clean_backup/`
- [ ] **For existing code patches**: Edit smali files in `dec/smali*/` (Section 2.4)
- [ ] **For adding new features**: Create new smali classes, add resources, update manifest (Section 10)
- [ ] **For new libraries**: Convert .jar/.aar to smali and merge (Section 10.3)
- [ ] **For lifecycle hooks**: Modify Application class or add your own (Section 10.4)
- [ ] **Add logging**: `Log.d("PatchTag", "feature X active")` everywhere for debugging
- [ ] **Save incremental backups**: `cp -r dec/ dec_v1_feature_x/` after each major change

## Phase 5: Recompile & Fix

- [ ] **Recompile**: `apktool b dec/ -o rebuilt.apk` (Section 2.1)
- [ ] **If recompile fails**: Check Section 10.5 (AAPT2 Error Catalog) and Section 5.4
- [ ] **If method limit exceeded**: Handle multi-dex (Section 10.5)
- [ ] **If you hit the same issue repeatedly**: Try a clean decompile (no changes) → recompile → if it fails, it's a tool/version issue not your modification

## Phase 6: Sign & Test (Local)

- [ ] **Align**: `zipalign -v -p 4 rebuilt.apk rebuilt_aligned.apk` (Section 8.1.3)
- [ ] **Sign with testing key**: `apksigner sign --ks ~/release.keystore ... rebuilt_aligned.apk` (Section 11.1)
- [ ] **Verify**: `apksigner verify --verbose rebuilt_aligned.apk`
- [ ] **Uninstall previous version on test env**: `adb uninstall com.example.app`
- [ ] **Install**: `adb install rebuilt_aligned.apk` (or `adb install-multiple` for splits)
- [ ] **Launch**: `adb shell am start -n com.example.app/.MainActivity`
- [ ] **Check logs**: `adb logcat -s "PatchTag:*" "AndroidRuntime:E"` (Section 7.6)
- [ ] **Test all modified features**: Does the new functionality work? Does existing functionality still work?
- [ ] **If app crashes**: Use Section 13.4 (Runtime Failures) diagnostic flow
- [ ] **If signature check detected**: Use Section 9.3 (Frida signature bypass) to identify the check, then patch smali
- [ ] **Iterate**: Fix issues → recompile → sign → install → test until stable

## Phase 7: Prepare for Delivery

- [ ] **Sign with release keystore** (if you used debug key during testing): Same `zipalign` + `apksigner` with `~/release.keystore`
- [ ] **Verify final signature**: `apksigner verify --verbose --print-certs final.apk`
- [ ] **For single APK**: The `.apk` file is ready to send
- [ ] **For split APKs**: Sign all splits with the same key, create `.apks` bundle (Section 11.3 Method B)
- [ ] **Test installation from the user's perspective**: On a physical device (if available), uninstall original → install your patched version
- [ ] **Write user instructions**: Use the template in Section 11.5

## Phase 8: Deliver

- [ ] **Send the APK to the user**: Via file transfer, cloud link, or QR code (Section 11.3)
- [ ] **If split APK**: Also send SAI installer + instructions
- [ ] **Communicate clearly**: User must uninstall original first, must disable auto-updates
- [ ] **Support**: Be ready to debug issues the user encounters (most common: didn't uninstall original, Play Store overwrote patch, wrong architecture splits)

## Phase 9: Maintenance

- [ ] **When the original app updates**: Download new version, decompile, re-apply modifications, test, re-deliver (Section 11.6)
- [ ] **Keep your keystore safe**: Lost keystore = users must reinstall from scratch
- [ ] **Document your changes**: Keep a changelog of what you modified and where in the smali code — makes re-applying patches on new versions much faster
