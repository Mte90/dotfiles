---
name: waydroid
description: "Waydroid - Container-based Android on Linux with Wayland support, GPU acceleration, and native app integration"
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - waydroid
    - android
    - container
    - linux
    - wayland
    - android-emulation
    - gapps
    - lineagos
---

# Waydroid

Complete guide to running Android applications on Linux using Waydroid - a container-based solution with native Wayland integration.

## Overview

Waydroid is a container-based approach to boot a full Android system on a regular GNU/Linux system. It uses Linux namespaces (user, pid, uts, net, mount, ipc) to run a full Android system in a container and provides Android applications on any GNU/Linux-based platform with near-native performance.

Key features:
- **Wayland Integration**: Full support for Wayland compositors with smooth windowing
- **GPU Acceleration**: Hardware-accelerated graphics for games and GPU-intensive apps
- **Native Performance**: Near-native speed with reduced overhead compared to emulators
- **LineageOS-based**: Uses customized Android system images based on LineageOS
- **binderfs**: Uses Android binder IPC mechanism for communication between container and host

## Installation

### Ubuntu/Debian

```bash
# Install prerequisites
sudo apt install curl ca-certificates python3-gbinder python3-trio -y

# Add the official repository
curl https://repo.waydro.id | sudo bash

# Or specify distribution manually
curl -s https://repo.waydro.id | sudo bash -s focal  # for Ubuntu 20.04
curl -s https://repo.waydro.id | sudo bash -s jammy  # for Ubuntu 22.04
curl -s https://repo.waydro.id | sudo bash -s noble   # for Ubuntu 24.04

# Install Waydroid
sudo apt install waydroid -y
```

Supported Ubuntu versions: focal, jammy, kinetic, lunar, mantic, noble
Supported Debian versions: bullseye, bookworm, trixie, sid

### Fedora

```bash
# Enable Waydroid Copr repository
sudo dnf copr enable aleasto/waydroid

# Install Waydroid
sudo dnf install waydroid
```

For Fedora Silverblue/Kinoite:
```bash
rpm-ostree install waydroid
```

### Arch Linux

```bash
# Using yay (AUR helper)
yay -S waydroid

# Or using git
git clone https://aur.archlinux.org/waydroid.git
cd waydroid
makepkg -si
```

### openSUSE

```bash
sudo zypper addrepo https://download.opensuse.org/repositories/openSUSE:Tools/openSUSE_Tools.repo
sudo zypper install waydroid
```

### Void Linux

```bash
sudo xbps-install -S waydroid
```

## Initialization

### Basic Initialization

```bash
# Initialize Waydroid (downloads latest Android image)
sudo waydroid init
```

### With Google Apps (GApps)

```bash
# Initialize with GAPPS support
sudo waydroid init -s GAPPS
```

### Manual OTA URLs

If the automatic detection fails, you can specify OTA URLs manually:

```bash
sudo waydroid init \
  -s https://ota.waydro.id/system \
  -v https://ota.waydro.id/vendor
```

## Starting Waydroid

### Using systemd (recommended)

```bash
# Start the container service
sudo systemctl start waydroid-container.service

# Enable on boot
sudo systemctl enable waydroid-container.service

# Start a session
waydroid session start
```

### Manual start (without systemd)

```bash
# Start container (requires sudo)
sudo waydroid container start

# Start session (in new terminal, no sudo)
waydroid session start
```

## CLI Commands

### App Management

```bash
# Install an APK
waydroid app install /path/to/app.apk

# List installed apps
waydroid app list

# Launch an app (use package name from list)
waydroid app launch com.package.name

# Uninstall an app
waydroid app uninstall com.package.name
```

### Shell Access

```bash
# Enter Android shell
waydroid shell

# Execute a single command
waydroid shell pm list packages
waydroid shell getprop ro.product.model
waydroid shell su -c "ls -la /sdcard/"
```

### UI Control

```bash
# Show full Android UI (fullscreen)
waydroid show-full-ui

# Take screenshot
waydroid screenshot

# Set window mode
waydroid window set <fullscreen|windowed|tablet> [position]
```

### Status and Info

```bash
# Check Waydroid status
waydroid status

# View logs
waydroid log
waydroid log -cat main  # Filter by logcat
waydroid log -cat all   # All logs

# Get device properties
waydroid prop get
waydroid prop get ro.product.model
```

### Container Control

```bash
# Stop session
waydroid session stop

# Stop container
sudo waydroid container stop

# Restart
sudo waydroid container restart
```

### Configuration

```bash
# Edit Waydroid configuration
waydroid config set <property> <value>

# Example: set portrait orientation
waydroid config set ro.orientation.portrait 1
```

## Architecture

### Container Technology

Waydroid uses Linux namespaces to isolate the Android container:
- **user namespace**: User ID mapping
- **pid namespace**: Process isolation
- **uts namespace**: Hostname
- **net namespace**: Network stack
- **mount namespace**: Filesystem
- **ipc namespace**: Inter-process communication

### binderfs

Waydroid requires the binder kernel module for Android IPC. Modern kernels use binderfs:

```bash
# Check if binderfs is available
ls -la /dev/binder*

# Load binder module (if needed)
sudo modprobe binder_linux
```

For Arch Linux with custom kernels, install binder_linux-dkms from AUR.

### Images

Waydroid uses LineageOS-based images:
- **System image**: Contains Android framework and system apps
- **Vendor image**: Contains hardware-specific blobs
- **Images location**: `/var/lib/waydroid/`

## GPU Support

### Verification

```bash
# Check GPU rendering
waydroid shell dumpsys SurfaceFlinger
```

### NVIDIA

Waydroid supports NVIDIA GPUs through the native Wayland renderer. Ensure you have:
- NVIDIA driver installed
- Wayland compositor with NVIDIA support (e.g., GNOME on Wayland, Sway)

### AMD/Intel

Works out of the box with Mesa drivers. For best performance:
- Ensure mesa drivers are up to date
- Use a Wayland compositor

### Performance Tuning

```bash
# Enable hardware GPU rendering (usually enabled by default)
waydroid prop set ro.hardware.gralloc gbm
waydroid prop set ro.hardware.egl emulated
```

## Networking

Waydroid creates a network bridge automatically. To verify:

```bash
# Check network interfaces
ip addr show waydroid0

# Network is usually NAT'd behind host
# Android sees eth0 with DHCP
```

### Sharing Host Network

```bash
# Waydroid shares the host network by default
# To isolate, you would need to modify the container configuration
```

### Internet Access

Waydroid container should have internet access automatically. If not:

```bash
# Check DNS
waydroid shell getprop net.dns1

# Test connectivity
waydroid shell ping -c 3 google.com
```

## Window Modes

### Fullscreen Mode

```bash
waydroid show-full-ui
```

### Windowed Mode

```bash
# Launch in window
waydroid app launch com.package.name

# Or set windowed mode explicitly
waydroid window set windowed
```

### Multi-Window (Tablet Mode)

```bash
# Enable tablet/multi-window mode
waydroid window set tablet
```

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
# Check certification status
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
# Default ADB connects to localhost
adb connect 192.168.250.1:5555

# Or use waydroid's adb over network
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
# List devices
adb devices

# Install APK
adb install app.apk

# Uninstall
adb uninstall com.package.name

# Push file
adb push local.txt /sdcard/

# Pull file
adb pull /sdcard/screenshot.png

# Shell access
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
# Create directory on host
mkdir -p ~/waydroid/shared

# Bind mount (add to /etc/fstab or systemd mount)
sudo mount --bind ~/waydroid/shared /var/lib/waydroid/data/media/0/Download/shared
```

### Using ADB for Files

```bash
# Push files to Android
adb push /path/on/host /sdcard/Download/

# Pull files from Android
adb pull /sdcard/screenshots/ /path/on/host/
```

## Desktop Environment Integration

### GNOME

Waydroid integrates well with GNOME on Wayland. Apps appear in the application overview. Use GNOME Extensions like:
- **Glass Mint**: Transparent top bar
- **Waydroid**: Native integration (check extensions.gnome.org)

### Sway/i3

For tiling window managers:

```bash
# Launch in windowed mode
waydroid app launch com.package.name

# Waydroid windows can be managed like regular XDG windows
```

### App Launchers

Create desktop entries for Android apps:

```bash
# Generate desktop entry
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/waydroid-app.desktop << EOF
[Desktop Entry]
Name=App Name
Exec=waydroid app launch com.package.name
Icon=android-icon
Type=Application
Categories=Android;
EOF
```

## Troubleshooting

### Common Issues

**Waydroid won't start**

```bash
# Check kernel module
lsmod | grep binder

# Check binderfs
ls -la /dev/binder*

# Restart services
sudo systemctl restart waydroid-container.service
waydroid session start

# Check logs
waydroid log
```

**No internet in Android**

```bash
# Check network interface
ip addr show waydroid0

# Restart network
sudo waydroid container restart
```

**Apps not launching**

```bash
# Check if session is running
waydroid status

# Restart session
waydroid session stop
waydroid session start
```

**GPU issues / Poor performance**

```bash
# Check GPU info
waydroid shell dumpsys SurfaceFlinger

# Update mesa drivers (AMD/Intel)
sudo dnf update  # Fedora
sudo apt upgrade  # Ubuntu

# For NVIDIA, ensure proprietary driver is installed
```

**Audio not working**

```bash
# Check audio sink
waydroid shell media list-sinks

# Set audio to ALSA/PulseAudio
waydroid prop set audio.oss 1
```

### Reset Waydroid

```bash
# Stop everything
waydroid session stop
sudo waydroid container stop

# Remove data (creates fresh install)
sudo rm -rf /var/lib/waydroid/

# Reinitialize
sudo waydroid init

# Restart services
sudo systemctl start waydroid-container.service
waydroid session start
```

### Complete Uninstall

```bash
# Stop services
waydroid session stop
sudo waydroid container stop
sudo systemctl disable waydroid-container.service

# Remove packages
sudo apt remove waydroid        # Ubuntu/Debian
sudo dnf remove waydroid        # Fedora
yay -R waydroid                 # Arch

# Remove data
sudo rm -rf /var/lib/waydroid ~/.local/share/waydroid
```

## Advanced Configuration

### Custom Images

Use custom LineageOS images:

```bash
# Download custom system and vendor images
sudo cp system.img vendor.img /var/lib/waydroid/images/
```

### HAL Configuration

Configure hardware abstraction layer:

```bash
# Set vendor HAL
waydroid prop set ro.hardware.vendor <vendor>

# Common values: qcom, intel, exynos, mediatek
```

### Boot Animation

```bash
# Custom boot animation
sudo cp bootanimation.zip /var/lib/waydroid/system/media/
```

### Magisk (Root Access)

For root access in Waydroid:

```bash
# Install Magisk on Waydroid
waydroid shell su -c "magisk --setup-mount /sbin/magisk"
```

## Best Practices

1. **Use Wayland session**: Waydroid only works with Wayland compositors
2. **Keep system updated**: Regular updates ensure compatibility
3. **Use GAPPS if needed**: Google Play Services required for many apps
4. **Check logs first**: Always check `waydroid log` when troubleshooting
5. **Use proper GPU drivers**: Install appropriate drivers for your hardware
6. **Enable ADB for complex tasks**: ADB provides more control
7. **Back up important data**: Waydroid data is in `/var/lib/waydroid/`

## References

- **Official Documentation**: https://docs.waydro.id/
- **Waydroid GitHub**: https://github.com/waydroid/waydroid
- **Arch Wiki**: https://wiki.archlinux.org/title/Waydroid
- **OTA Images**: https://ota.waydro.id/
- **LineageOS**: https://lineageos.org/