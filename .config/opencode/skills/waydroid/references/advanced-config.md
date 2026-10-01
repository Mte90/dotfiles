This file is loaded on demand from ../SKILL.md.

# Advanced Configuration

## Custom Images

Use custom LineageOS images:

```bash
sudo cp system.img vendor.img /var/lib/waydroid/images/
```

## HAL Configuration

Configure hardware abstraction layer:

```bash
waydroid prop set ro.hardware.vendor <vendor>
# Common values: qcom, intel, exynos, mediatek
```

## Boot Animation

```bash
sudo cp bootanimation.zip /var/lib/waydroid/system/media/
```

## Magisk (Root Access)

For root access in Waydroid:

```bash
waydroid shell su -c "magisk --setup-mount /sbin/magisk"
```
