This file is loaded on demand from ../SKILL.md.

# GApps, ADB, and File Sharing

## GAPPS Support

### Installation

Initialize with GAPPS support:

```bash
sudo waydroid init -s GAPPS
```

This installs:
- Google Play Services
- Google Play Store
- Core Google apps

### Google Play Certification

To use Google Play Store fully:

1. Open Play Store on Waydroid
2. Sign in with Google account
3. The device should auto-register

For certification issues:
```bash
waydroid shell settings get secure android_id
```

### Manual GApps Installation

If you initialized without GAPPS, you can add it later:

```bash
# Download GApps from OpenGApps
# Extract to /var/lib/waydroid/
# Restart waydroid
```

## ADB Integration

### Connect to Waydroid via ADB

```bash
adb connect 192.168.250.1:5555
waydroid shell getprop ro.debuggable  # Check if ADB is enabled
```

### Enable ADB Network Debugging

```bash
# In Waydroid shell
waydroid shell setprop persist.adb.enable 1
waydroid shell setprop service.adb.tcp.port 5555

# Then connect
adb connect 192.168.250.1:5555
```

### Common ADB Commands

```bash
adb devices
adb install app.apk
adb uninstall com.package.name
adb push local.txt /sdcard/
adb pull /sdcard/screenshot.png
adb shell
```

## File Sharing

### Internal Storage

The Android container sees `/sdcard/` as internal storage:

```bash
# Access from host (read-only)
ls /var/lib/waydroid/data/media/0/

# Or use waydroid shell
waydroid shell ls /sdcard/
```

### Shared Folders

Create a shared folder between host and Android:

```bash
mkdir -p ~/waydroid/shared
sudo mount --bind ~/waydroid/shared /var/lib/waydroid/data/media/0/Download/shared
```

### Using ADB for Files

```bash
adb push /path/on/host /sdcard/Download/
adb pull /sdcard/screenshots/ /path/on/host/
```
