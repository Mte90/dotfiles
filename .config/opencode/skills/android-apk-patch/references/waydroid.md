# Waydroid: Android Container with Desktop UI for Local APK Testing

## 8.3 Waydroid: Android Container with Desktop UI

### 8.3.1 What Is Waydroid?

**Waydroid** runs Android as an LXC container with native desktop window integration. Unlike redroid, it displays Android apps as regular windows on your Linux desktop. It requires a Wayland compositor (GNOME Wayland, KDE Plasma Wayland, Sway, Hyprland, etc.).

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

### 8.3.2 Installation

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

### 8.3.3 GApps, Magisk & ARM Translation via waydroid_script

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
waydroid session start
waydroid show-full-ui
```

**ARM translation critical requirement**: Your CPU must support **SSE 4.2** instruction set:

```bash
# Check
cat /proc/cpuinfo | grep sse4_2
# If empty: your CPU doesn't support it — ARM translation won't work
```

### 8.3.4 ADB Connection & APK Installation

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

### 8.3.5 Complete Waydroid APK Testing Workflow

```bash
# === One-time setup ===
curl https://repo.waydro.id | sudo bash
sudo apt install waydroid
sudo waydroid init   # or: sudo waydroid init -s GAPS
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

### 8.3.6 NVIDIA GPU: Known Pain Point

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

### 8.3.7 Waydroid Known Issues

| Issue | Workaround |
|---|---|
| NVIDIA GPU: no/flickering rendering | `WAYDROID_DISABLE_GPU=1` or switch to iGPU |
| X11: no display | Run nested Wayland: `weston &` then `WAYLAND_DISPLAY=wayland-1 waydroid show-full-ui` |
| Camera not working | Very limited support (v4l2 only, no PipeWire) |
| Magisk flaky install | Check waydroid_script version; may need manual Magisk flash |
| Bluetooth/USB not working | Not natively supported |
| Dual GPU flickering | Force iGPU only or use software rendering |
| SELinux blocks Waydroid | Set permissive: `sudo setenforce 0` (temp) or configure policy |
