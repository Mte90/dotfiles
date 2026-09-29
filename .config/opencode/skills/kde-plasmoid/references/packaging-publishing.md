<!-- This file is loaded on demand from ../SKILL.md -->

# Packaging & Publishing Reference

Complete reference for packaging Plasmoids with plasmapkg2 and publishing to KDE Store.

## Create Release Package

```bash
# Clean package
cd my-plasmoid
rm -f ../my-plasmoid.plasmoid
cd package && zip -r ../../my-plasmoid-1.0.0.plasmoid . && cd ..

# Verify package structure
unzip -l my-plasmoid-1.0.0.plasmoid
```

## Build .plasmoid with plasmapkg2

```bash
# Package creation
cd my-plasmoid/package
plasmapkg2 -c my-plasmoid.plasmoid

# List contents
plasmapkg2 -t Plasma/Applet --list

# Package with compression
plasmapkg2 -c -o my-plasmoid-compressed.plasmoid package/
```

## Install/Update/Remove

```bash
# Install from package
plasmapkg2 -i my-plasmoid.plasmoid

# Install from directory (auto-packages)
plasmapkg2 -i package/

# Upgrade existing
plasmapkg2 -u my-plasmoid.plasmoid

# Remove
plasmapkg2 -r com.example.my-plasmoid

# List all installed widgets
plasmapkg2 -t Plasma/Applet --list

# List with details
plasmapkg2 -t Plasma/Applet --list --verbose
```

## Local Deployment

```bash
# Install to user Plasma (persistent across sessions)
plasmapkg2 -i my-plasmoid-1.0.0.plasmoid

# Verify installation location
find ~/.local/share/plasma-appletsrc -name "*my-plasmoid*" 2>/dev/null || \
find ~/.local/share/plasma-appletsrc -name "*com.example.my-plasmoid*" 2>/dev/null

# List all installed applets
plasmapkg2 -t Plasma/Applet --list

# Check widget configuration file location
cat ~/.local/share/plasma-appletsrc/com.example.kde.desktop-appletsrc
```

## System-Wide Deployment (requires root)

```bash
# Copy to system location
sudo cp my-plasmoid-1.0.0.plasmoid /usr/share/plasma/plasmoids/com.example.my-plasmoid/

# Or copy folder structure
sudo mkdir -p /usr/share/plasma/plasmoids/com.example.my-plasmoid
sudo cp -r my-plasmoid/package/* /usr/share/plasma/plasmoids/com.example.my-plasmoid/

# Reload plasma shell to apply
kquitapp6 plasmashell && kstart6 plasmashell

# Verify installation
sudo plasmapkg2 -l com.example.my-plasmoid
```

## KDE Store Distribution

### Step 1: Prepare package

```bash
# Create release package
cd my-plasmoid
VERSION="1.0.0"
plasmapkg2 -c -o my-plasmoid-${VERSION}.plasmoid package/

# Verify package contents
unzip -l my-plasmoid-${VERSION}.plasmoid

# Check metadata
unzip -p my-plasmoid-${VERSION}.plasmoid metadata.json | jq .
```

### Step 2: Prepare screenshots

Screenshots should:
- Be high-resolution (1920x1080 minimum)
- Show widget in actual Plasma session
- Include at least 3 variations:
  1. Widget in desktop mode
  2. Widget in panel (if applicable)
  3. Configuration dialog

```bash
# Create screenshots directory
mkdir -p screenshots

# Capture widget screenshots
plasmoidtest com.example.my-plasmoid
# (Take screenshots manually or use automation)
```

### Step 3: Submit to KDE Store

1. **Account setup:**
   - Visit https://store.kde.org/
   - Register with KDE account (GitHub, KDE Accounts, or email)

2. **New submission:**
   - Click "Submit New Applet"
   - Fill metadata form:
     - Name, description, category
     - License (must match metadata.json)
     - Screenshots (upload PNG files)
     - GitHub repository URL (optional but recommended)

3. **Review process:**
   - KDE maintainers review (typically 1-2 weeks)
   - Common rejection reasons:
     - Missing required metadata fields
     - Non-compliant license
     - Promotional/proprietary content
     - Broken QML syntax
     - Missing plasma compatibility declaration

4. **Approved applet:**
   - Appears in Plasma Add-Widgets panel
   - Visible to all KDE users
   - Automated updates available

### KDE Store Requirements

**Prepare files:**
- `my-plasmoid-1.0.0.plasmoid`
- Screenshots (PNG, 1920x1080 recommended)
- README.md with description
- LICENSE file (compatible with specified license)

**KDE Store requirements:**
- Minimum plasma version compatibility declared
- Complete metadata in metadata.json
- Valid SPDX license identifier
- At least 3 screenshots showing widget in use

**KDE Store policy compliance:**
- No promotional content
- No aggressive marketing in description
- Open-source license only (no proprietary components)
- Privacy policy for widgets accessing user data

### GitHub Release

```bash
# Create release archive
tar -czf my-plasmoid-1.0.0.tar.gz my-plasmoid/

# Installation script
cat > install.sh << 'EOF'
#!/bin/bash
plasmapkg2 -i my-plasmoid-1.0.0.plasmoid
echo "Widget installed. Reload plasma shell: kquitapp6 plasmashell && kstart6 plasmashell"
EOF
chmod +x install.sh

# Verify installation
./install.sh
plasmapkg2 -t Plasma/Applet --list | grep my-plasmoid
```

## Publishing Timeline

| Stage | Duration | Notes |
|-------|----------|-------|
| Development | Variable | Depends on feature complexity |
| Testing | 1-2 days | Manual testing, regression checks |
| Package creation | 30 minutes | Build .plasmoid package |
| KDE Store review | 1-2 weeks | Varies by workload |
| User availability | Immediate | Once approved |