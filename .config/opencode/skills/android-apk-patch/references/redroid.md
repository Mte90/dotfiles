# Redroid: Android in Docker for Local APK Testing

## 8.2 Redroid: Android in Docker for Headless APK Testing

### 8.2.1 What Is Redroid?

**Redroid (Remote-Android)** runs a full Android system inside a Docker container. It does NOT use QEMU or virtualization — it runs Android userspace **natively** on the host Linux kernel using LXC primitives. The host kernel must have binder/ashmem modules (or binderfs), but no VM is involved.

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

### 8.2.2 Prerequisites & Kernel Setup

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

### 8.2.3 Basic Docker Setup

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

### 8.2.4 Available Docker Image Tags

| Tag | Android | Notes |
|---|---|---|
| `redroid/redroid:11.0.0-latest` | 11 | Stable, legacy |
| `redroid/redroid:12.0.0-latest` | 12 | Stable |
| `redroid/redroid:13.0.0-latest` | 13 | Stable |
| `redroid/redroid:14.0.0-latest` | 14 | **Recommended** — most stable |
| `redroid/redroid:15.0.0-latest` | 15 | Newer, check stability |
| `redroid/redroid:14.0.0_64only-latest` | 14 | 64-bit only (smaller, fewer compat issues) |
| `erstt/redroid` | Various | Pre-built with ARM translation |

### 8.2.5 ADB Connection & APK Installation

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

### 8.2.6 GApps, Magisk & ARM Translation on Redroid

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

### 8.2.7 Complete Redroid APK Testing Workflow

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

### 8.2.8 Redroid Known Issues

| Issue | Workaround |
|---|---|
| Container won't start (binder missing) | `sudo modprobe binder_linux` + `linux-modules-extra-$(uname -r)` |
| Apps can't access internet | Use `--net=host` in docker run |
| Long first boot on WSL2 | Store data as Docker volume (not bind mount) |
| ARM app crashes on x86 host | Install ARM translation: `redroid-script.py <id> --libndk` |
| No audio output | Expected in headless mode; use scrcpy for visual only |
| Magisk instability after install | Restart container 2-3 times |
| GPU artifacts on NVIDIA | Use software rendering (remove `-v /dev/dri:/dev/dri`) |
