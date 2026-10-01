This file is loaded on demand from ../SKILL.md.

# Desktop Environment Integration and Troubleshooting

## Desktop Environment Integration

### GNOME

Waydroid integrates well with GNOME on Wayland. Apps appear in the application overview. Use GNOME Extensions like:
- **Glass Mint**: Transparent top bar
- **Waydroid**: Native integration (check extensions.gnome.org)

### Sway/i3

For tiling window managers:

```bash
waydroid app launch com.package.name
# Waydroid windows can be managed like regular XDG windows
```

### App Launchers

Create desktop entries for Android apps:

```bash
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
lsmod | grep binder
ls -la /dev/binder*
sudo systemctl restart waydroid-container.service
waydroid session start
waydroid log
```

**No internet in Android**

```bash
ip addr show waydroid0
sudo waydroid container restart
```

**Apps not launching**

```bash
waydroid status
waydroid session stop
waydroid session start
```

**GPU issues / Poor performance**

```bash
waydroid shell dumpsys SurfaceFlinger
sudo dnf update  # Fedora
sudo apt upgrade  # Ubuntu
# For NVIDIA, ensure proprietary driver is installed
```

**Audio not working**

```bash
waydroid shell media list-sinks
waydroid prop set audio.oss 1
```

### Reset Waydroid

```bash
waydroid session stop
sudo waydroid container stop
sudo rm -rf /var/lib/waydroid/
sudo waydroid init
sudo systemctl start waydroid-container.service
waydroid session start
```

### Complete Uninstall

```bash
waydroid session stop
sudo waydroid container stop
sudo systemctl disable waydroid-container.service

sudo apt remove waydroid        # Ubuntu/Debian
sudo dnf remove waydroid        # Fedora
yay -R waydroid                 # Arch

sudo rm -rf /var/lib/waydroid ~/.local/share/waydroid
```
