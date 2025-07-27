# HyprScreenShot

A standalone, update-resilient screenshot utility based on HyDE's implementation with advanced maintainability features.

## Overview

HyprScreenShot provides a **portable, DE-agnostic screenshot system** that automatically adapts to tool updates and maintains compatibility across different versions of its dependencies.

### Key Features

- **Update-Resilient Architecture**: Automatically detects tool capabilities and adapts to version changes
- **Automatic Migration System**: Handles configuration updates when tools are upgraded
- **Comprehensive Testing**: Built-in compatibility testing after updates
- **Multiple Capture Modes**: Area, frozen, monitor, screen, and OCR text extraction
- **Modern Annotation**: Supports both Satty and Swappy annotation tools
- **Smart Clipboard Integration**: Seamless Wayland clipboard operations
- **Detailed Reporting**: Comprehensive compatibility and status reports
- **Configurable Notifications**: TOML-based configuration with user-friendly management
- **Subcommand Architecture**: Unified interface for screenshots, updates, and configuration

> **⚠️ Arch Linux Only**: HySS is designed exclusively for Arch Linux and Arch-based distributions. While the tool may work on other distributions, we only provide official support and installation guidance for Arch Linux systems with `pacman`, `yay`, and `paru` package managers.

## Quick Start for Arch Linux

**New to Linux?** This section will guide you through installing HyprScreenShot step-by-step. If you're experienced with Arch Linux, you can skip to the [Installation](#installation) section below.

### Prerequisites Check

Before installing HyprScreenShot, let's verify your system is ready:

1. **Open a terminal**: Press `Ctrl + Alt + T` or search for "Terminal" in your application menu

2. **Check if you're running Wayland** (required for HyprScreenShot):
   ```bash
   echo $XDG_SESSION_TYPE
   # Should output: wayland
   ```

3. **Verify Hyprland is installed** (if using Hyprland):
   ```bash
   hyprctl version
   # Should show Hyprland version info
   ```

If either check fails, HyprScreenShot may not work properly on your system.

### Step 1: Install Dependencies

HyprScreenShot needs several packages to work. Install them with pacman:

```bash
# Update your system first (important!)
sudo pacman -Syu

# Install core dependencies
sudo pacman -S grim slurp wl-clipboard imagemagick tesseract tesseract-data-eng jq libnotify

# Install annotation tool (choose one):
# Option 1: Satty (modern, recommended)
sudo pacman -S satty

# Option 2: Swappy (traditional alternative)
sudo pacman -S swappy
```

**What each package does:**
- `grim` - Takes screenshots on Wayland
- `slurp` - Lets you select screen areas
- `wl-clipboard` - Manages clipboard operations
- `imagemagick` - Processes images for OCR
- `tesseract` - Extracts text from images (OCR)
- `jq` - Processes configuration data
- `libnotify` - Shows desktop notifications
- `satty/swappy` - Tools for annotating screenshots

### Step 2: Download HyprScreenShot

Choose one of these methods:

**Method 1: Git Clone (recommended for development)**
```bash
# Navigate to your home directory
cd ~

# Clone the repository
git clone https://github.com/thesleepingsage/HySS.git

# Enter the directory
cd HySS
```

**Method 2: Download Release**
```bash
# Navigate to your Downloads folder
cd ~/Downloads

# Download latest release
wget https://github.com/thesleepingsage/HySS/archive/v1.0.0.tar.gz

# Extract the archive
tar -xzf v1.0.0.tar.gz

# Enter the extracted directory
cd HySS-1.0.0
```

### Step 3: Install HyprScreenShot

Now install HyprScreenShot on your system:

```bash
# Make the installation script executable
chmod +x install.sh

# Install system-wide (recommended)
sudo ./install.sh

# OR install for your user only
./install.sh --user
```

**What this does:**
- Copies `hyss` command to your system
- Sets up library files
- Creates necessary directories
- Makes HyprScreenShot available from anywhere

### Step 4: Verify Installation

Test that everything works:

```bash
# Check HyprScreenShot is installed
hyss version
# Should show: HyprScreenShot version 1.0.0

# Check system status
hyss update check
# Should show: ✓ System is up to date and compatible

# Test dependencies
hyss update status
# Should show all tools as available (true)
```

### Step 5: Take Your First Screenshot

Try these basic commands:

```bash
# Take a screenshot of selected area
hyss area

# Take a screenshot with frozen screen (easier targeting)
hyss freeze

# Take fullscreen screenshot
hyss screen

# Extract text from screen area (OCR)
hyss ocr
```

**Expected behavior:**
- A selection tool will appear
- Click and drag to select an area
- Screenshot will be saved and copied to clipboard
- You'll see a notification confirming success

### Quick Setup Complete! 🎉

HyprScreenShot is now ready to use. For advanced configuration and Hyprland integration, continue reading the sections below.

---

## Installation

> **👆 New to Linux?** Check out the [Quick Start for Arch Linux](#quick-start-for-arch-linux) section above for step-by-step guidance!

### Dependencies (Arch Linux)

Install these packages before installing HyprScreenShot:

```bash
# Update your system first
sudo pacman -Syu

# Install core dependencies
sudo pacman -S grim slurp wl-clipboard imagemagick tesseract tesseract-data-eng jq libnotify

# Install annotation tool (choose one)
sudo pacman -S satty      # Modern tool (recommended)
# OR
sudo pacman -S swappy     # Traditional alternative
```

**Alternative: AUR Installation**
```bash
# Using yay (AUR helper)
yay -S hyprscreenshot-git

# Using paru (AUR helper)
paru -S hyprscreenshot-git

# Manual AUR installation
git clone https://aur.archlinux.org/hyprscreenshot.git
cd hyprscreenshot
makepkg -si
```

### Manual Installation

For development or customization, install manually:

#### Step 1: Download Source Code

**Option A: Git Clone (for development)**
```bash
# Clone the repository
git clone https://github.com/thesleepingsage/HySS.git
cd HySS
```

**Option B: Download Release**
```bash
# Download latest release
wget https://github.com/thesleepingsage/HySS/releases/download/v1.0.0/HySS-v1.0.0.tar.gz

# Extract and enter directory
tar -xzf HySS-v1.0.0.tar.gz
cd HySS-v1.0.0
```

#### Step 2: Run Installation Script

**System-wide installation (recommended):**
```bash
# Make script executable and install
chmod +x install.sh
sudo ./install.sh
```
*Installs to `/usr/local/bin/hyss` - available system-wide*

**User-local installation:**
```bash
# Install for current user only
chmod +x install.sh
./install.sh --user
```
*Installs to `~/.local/bin/hyss` - may need to add to PATH*

#### Installation Options

```bash
# Show installation help
./install.sh --help

# Force overwrite existing installation
./install.sh --force

# User installation with force overwrite
./install.sh --user --force
```

#### Post-Installation Verification

After installation, verify everything works:

```bash
# Check that hyss is available
hyss version

# Verify system dependencies
hyss update check

# Run compatibility tests
hyss update test
```

#### Directory Structure

**System-wide installation:**
- Executable: `/usr/local/bin/hyss`
- Libraries: `/usr/local/share/hyss/lib/`

**User installation:**
- Executable: `~/.local/bin/hyss`
- Libraries: `~/.local/share/hyss/lib/`

## Usage

### Basic Screenshot Operations

```bash
# Interactive area/window selection
hyss area

# Frozen screen selection (easier targeting)
hyss freeze

# Current monitor
hyss monitor

# All monitors
hyss screen

# OCR text extraction to clipboard
hyss ocr
```

### Desktop Environment Integration

Add keybindings to your DE configuration:

```bash
# Example keybindings (adapt to your DE)
Super+P              exec /path/to/hyss area
Super+Ctrl+P         exec /path/to/hyss freeze
Super+Alt+P          exec /path/to/hyss monitor
Print                exec /path/to/hyss screen
Super+Shift+S        exec /path/to/hyss ocr
```

### Hyprland Integration

HySS provides clean, simple commands that replace complex manual screenshot tool chains commonly found in Hyprland configurations.

#### Command Simplification

**Before (Complex manual chains):**
```bash
# 78 characters of complexity with multiple tools and parameters
bindd = Super+Shift, S, Screen snip, exec, hyprshot --freeze --clipboard-only --mode region --silent

# 89 characters with temporary files and cleanup
bindd = Super+Shift, T, Character recognition, exec, grim -g "$(slurp $SLURP_ARGS)" "tmp.png" && tesseract "tmp.png" - | wl-copy && rm "tmp.png"

# Multiple tools for simple fullscreen screenshot
bindld = ,Print, Screenshot >> clipboard, exec, grim - | wl-copy
```

**After (Clean HySS commands):**
```bash
# Simple, memorable commands - just 13-18 characters each
bindd = Super+Shift, S, Screen snip, exec, hyss freeze
bindd = Super+Shift, T, Character recognition, exec, hyss ocr
bindld = ,Print, Screenshot >> clipboard, exec, hyss screen
```

#### Ready-to-Use Hyprland Keybinds

Drop these into your `hyprland.conf` or keybinds configuration:

```bash
# Screenshot operations
bindd = Super+Shift, S, Screen snip, exec, hyss freeze           # Frozen screen region selection
bindd = Super+Alt, S, Area selection, exec, hyss area            # Interactive area selection
bindld = ,Print, Screenshot >> clipboard, exec, hyss screen      # Fullscreen to clipboard
bindd = Super, Print, Monitor screenshot, exec, hyss monitor     # Current monitor only

# Advanced features
bindd = Super+Shift, T, Character recognition, exec, hyss ocr    # OCR text extraction
bindd = Super+Shift, C, Color picker, exec, hyprpicker -a        # Color picker (system tool)
```

#### Benefits for Dotfile Sharing

- **Cleaner configs**: Easy to read and understand at a glance
- **Reduced complexity**: No need to memorize tool-specific parameters
- **Better maintenance**: HySS automatically handles tool updates and compatibility
- **Consistent behavior**: Same commands work regardless of underlying tool versions
- **Simplified sharing**: Others can easily understand and modify your keybinds

#### Migration from Manual Commands

Replace your existing complex screenshot commands with HySS equivalents:

| Manual Command Chain | HySS Replacement | Function |
|---------------------|------------------|----------|
| `hyprshot --freeze --clipboard-only --mode region --silent` | `hyss freeze` | Frozen screen selection |
| `grim -g "$(slurp)" \| wl-copy` | `hyss area` | Interactive region selection |
| `grim - \| wl-copy` | `hyss screen` | Fullscreen to clipboard |
| `grim $(xdg-user-dir PICTURES)/Screenshots/...` | `hyss screen` | Fullscreen with auto-save |
| `grim -g "$(slurp)" "tmp.png" && tesseract...` | `hyss ocr` | OCR text extraction |

### Environment Variables

```bash
# Force specific annotation tool
export HYSS_ANNOTATION_TOOL=satty

# Skip annotation step
export HYSS_NO_ANNOTATION=1

# Copy to clipboard only (don't save file)
export HYSS_COPY_ONLY=1

# Custom save directory
hyss area ~/Desktop/screenshots
```

### Configuration Management

HyprScreenShot uses a TOML configuration file for user-friendly settings:

```bash
# Show current configuration
hyss config show

# Edit configuration file
hyss config edit

# Get specific setting
hyss config get notifications enabled

# Set specific setting
hyss config set notifications enabled false

# Create default configuration
hyss config init

# Validate configuration
hyss config validate
```

The configuration file is located at `~/.config/hyss/config.toml` and supports:
- Notification settings (enabled, app name, urgency, timeout)
- Default directories and filename formats
- Annotation tool preferences
- Clipboard behavior settings

## Update Management

### Automatic Update Handling

The tool automatically:
- Detects when dependencies are updated
- Migrates configurations to new formats
- Tests compatibility after changes
- Provides detailed reports on issues

### Manual Update Operations

```bash
# Check system status and detect updates
hyss update check

# Run comprehensive compatibility tests
hyss update test

# Generate detailed status report
hyss update report

# Force regenerate all configurations
hyss update force-regen

# Show migration and test history
hyss update history

# Clean old data and backups
hyss update clean
```

### Interactive Update Manager

```bash
# Launch interactive update manager
hyss update interactive
```

## Architecture

### Modular Design

The tool uses a **plugin-style architecture** with abstraction layers:

- **Tool Detection** (`lib/tool-detection.sh`): Version detection and capability mapping
- **Capture Abstraction** (`lib/capture-abstraction.sh`): Screenshot capture methods
- **Annotation Abstraction** (`lib/annotation-abstraction.sh`): Annotation tool integration
- **Clipboard Abstraction** (`lib/clipboard-abstraction.sh`): Clipboard operations
- **Migration System** (`lib/migration-system.sh`): Configuration migrations
- **Compatibility Testing** (`lib/compatibility-testing.sh`): Automated testing

### Update Resilience

The system maintains compatibility through:

1. **Dynamic Capability Detection**: Tests tool features at runtime
2. **Version-Aware Configuration**: Generates configs based on detected versions
3. **Graceful Degradation**: Core functionality works even if advanced features fail
4. **Automatic Fallbacks**: Switches to alternative methods when tools change
5. **Migration Framework**: Handles configuration updates automatically

### Data Storage

```
~/.config/hyss/                    # Configuration files
├── config.toml                    # Main configuration file
├── satty/config.toml              # Satty annotation config
└── swappy/config                  # Swappy annotation config

~/.local/share/hyss/               # Data and cache
├── tool-capabilities.json         # Cached tool capabilities
├── migration-metadata.json        # Migration tracking
└── compatibility-test-results.json # Test results

~/Pictures/Screenshots/            # Default screenshot location
```

## Troubleshooting

### Common Issues

**1. "Missing required dependencies"**
```bash
# Check which tools are missing
hyss update status

# Install missing tools (example for Arch Linux)
sudo pacman -S grim slurp wl-clipboard satty imagemagick tesseract tesseract-data-eng jq libnotify
```

**2. "Annotation tool failed"**
```bash
# Check annotation tool status
hyss update test

# Try alternative annotation tool
export HYSS_ANNOTATION_TOOL=swappy
hyss area
```

**3. "Clipboard integration not working"**
```bash
# Verify Wayland clipboard tools
which wl-copy wl-paste

# Test clipboard directly
echo "test" | wl-copy
wl-paste
```

**4. "Configuration errors after tool updates"**
```bash
# Force regenerate configurations
hyss update force-regen

# Check migration history
hyss update history
```

**5. "Command not found: hyss"**
```bash
# Check if hyss is in your PATH
which hyss

# If user installation, add to PATH
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc
source ~/.bashrc

# Or for zsh users
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc
source ~/.zshrc
```

**6. "Permission denied" errors**
```bash
# Fix executable permissions
chmod +x ~/.local/bin/hyss

# Or for system installation
sudo chmod +x /usr/local/bin/hyss
```

### Arch Linux Specific Issues

**AUR Package Build Failures**
```bash
# Update package database first
sudo pacman -Sy

# For yay users:
yay -Sc
yay -S hyprscreenshot-git --rebuild

# For paru users:
paru -Sc
paru -S hyprscreenshot-git --rebuild

# Manual AUR troubleshooting (yay)
cd ~/.cache/yay/hyprscreenshot-git
rm -rf src/ pkg/
yay -S hyprscreenshot-git

# Manual AUR troubleshooting (paru)
cd ~/.cache/paru/clone/hyprscreenshot-git
rm -rf src/ pkg/
paru -S hyprscreenshot-git
```

**Missing base-devel Group**
```bash
# Install essential build tools
sudo pacman -S base-devel

# Verify git is installed
sudo pacman -S git
```

**Wayland Session Issues**
```bash
# Check current session type
echo $XDG_SESSION_TYPE

# If showing 'x11', you need to:
# 1. Log out of your session
# 2. Select Wayland session at login screen
# 3. Or install/configure Wayland compositor

# For Hyprland specifically
sudo pacman -S hyprland
# Then log out and select Hyprland session
```

**Package Conflicts**
```bash
# Check for conflicting packages
pacman -Qo /usr/bin/grim

# Remove conflicting AUR packages
yay -R conflicting-package

# Reinstall from official repos
sudo pacman -S grim slurp
```

**Environment Variables Not Working**
```bash
# Check current environment
env | grep XDG

# Restart your session if variables are missing
# Or source your shell config
source ~/.bashrc  # or ~/.zshrc
```

### Debug Mode

Enable verbose output for troubleshooting:
```bash
hyss update check --verbose
```

### Compatibility Reports

Generate detailed compatibility reports:
```bash
# Generate report file
hyss update report > hyss-report.txt

# View current status
hyss update status
```

## Advanced Features

### OCR Text Extraction

The tool includes sophisticated OCR capabilities:
- Interactive area selection for text regions
- Automatic image enhancement for better recognition
- Direct clipboard integration
- Notification with extracted text preview

### Workflow Integration

Examples of advanced usage:

```bash
# Screenshot with custom processing
hyss area && convert ~/Pictures/Screenshots/latest.png -resize 50% ~/Pictures/Screenshots/thumbnail.png

# OCR with custom language
TESSERACT_OPTS="-l fra" hyss ocr

# Automated screenshot series
for i in {1..5}; do
    hyss screen ~/Desktop/series_$i.png
    sleep 2
done
```

### Custom Configurations

Create custom annotation configurations:

```bash
# Custom Satty config
mkdir -p ~/.config/hyss/satty
cat > ~/.config/hyss/satty/config.toml << 'EOF'
[general]
initial-tool = "rectangle"
corner-roundness = 0
early-exit = true

[color-palette]
palette = ["#ff0000", "#00ff00", "#0000ff"]
EOF
```

## Development

### Extending the Tool

The modular architecture makes it easy to:
- Add support for new screenshot tools
- Implement additional annotation tools
- Create custom capture modes
- Add new export formats

### Testing Changes

```bash
# Run full test suite
hyss update test

# Test specific functionality
hyss update test --verbose
```

### Contributing

When adding new features:
1. Update capability detection in `lib/tool-detection.sh`
2. Add abstraction layer support if needed
3. Include migration logic for configuration changes
4. Add compatibility tests
5. Update documentation

## License

This tool is based on HyDE's screenshot implementation and maintains compatibility with its design principles while adding update resilience and portability features.

---

**Note**: This tool is designed to be a drop-in replacement for HyDE's screenshot system while providing enhanced maintainability and cross-DE compatibility.
