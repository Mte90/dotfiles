This file is loaded on demand from ../SKILL.md.

# GPU, Networking, and Window Modes

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
waydroid shell dumpsys SurfaceFlinger
```

### NVIDIA

Supports NVIDIA GPUs through native Wayland renderer. Ensure:
- NVIDIA driver installed
- Wayland compositor with NVIDIA support (e.g., GNOME on Wayland, Sway)

### AMD/Intel

Works out of the box with Mesa drivers. For best performance:
- Ensure mesa drivers are up to date
- Use a Wayland compositor

### Performance Tuning

```bash
waydroid prop set ro.hardware.gralloc gbm
waydroid prop set ro.hardware.egl emulated
```

## Networking

Waydroid creates a network bridge automatically (NAT'd behind host).

```bash
# Check network interfaces
ip addr show waydroid0

# Android sees eth0 with DHCP
```

### Sharing Host Network

Waydroid shares the host network by default. To isolate, modify container configuration.

### Internet Access

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
waydroid app launch com.package.name
waydroid window set windowed
```

### Multi-Window (Tablet Mode)

```bash
waydroid window set tablet
```
